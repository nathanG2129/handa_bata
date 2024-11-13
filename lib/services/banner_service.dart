import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:handabatamae/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:handabatamae/shared/connection_quality.dart';
import 'package:handabatamae/models/pending_banner_unlock.dart';
import 'package:handabatamae/services/user_profile_service.dart';

// Add new cache model
class CachedBanner {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final BannerPriority priority;
  
  CachedBanner(this.data, this.timestamp, {
    this.priority = BannerPriority.HIGH
  });
  
  bool get isValid => 
    DateTime.now().difference(timestamp) < const Duration(hours: 1);
}

// Move enum to top level
enum BannerPriority {
  CRITICAL,  // Current user's banner
  HIGH,      // Visible banners
  MEDIUM,    // Next level banners
  LOW        // Background loading
}

class BannerService {
  final DocumentReference _bannerDoc = FirebaseFirestore.instance.collection('Game').doc('Banner');
  
  // Update cache constants
  static const String BANNERS_CACHE_KEY = 'banners_cache';
  static const String BANNER_VERSION_KEY = 'banner_version';
  static const String BANNER_REVISION_KEY = 'banner_revision';
  static const int MAX_STORED_VERSIONS = 5;
  static const int MAX_CACHE_SIZE = 100;
  static const Duration CACHE_DURATION = Duration(hours: 1);

  // Update cache structure
  static final Map<int, CachedBanner> _bannerCache = {};
  static final Map<String, CachedBanner> _batchCache = {};

  // Keep existing controllers
  final _bannerUpdateController = StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get bannerUpdates => _bannerUpdateController.stream;

  static const Duration SYNC_DEBOUNCE = Duration(milliseconds: 500);
  static const Duration SYNC_TIMEOUT = Duration(seconds: 5);
  Timer? _syncDebounceTimer;
  bool _isSyncing = false;
  final StreamController<bool> _syncStatusController = StreamController<bool>.broadcast();
  Stream<bool> get syncStatus => _syncStatusController.stream;

  // Add connection manager
  final ConnectionManager _connectionManager = ConnectionManager();

  // Add priority queues
  final Map<BannerPriority, Queue<int>> _loadQueues = {
    BannerPriority.CRITICAL: Queue<int>(),
    BannerPriority.HIGH: Queue<int>(),
    BannerPriority.MEDIUM: Queue<int>(),
    BannerPriority.LOW: Queue<int>(),
  };

  // Add UserProfileService instance
  final UserProfileService _userProfileService = UserProfileService();

  // Update getBannerDetails with priority-aware loading
  Future<Map<String, dynamic>?> getBannerDetails(
    int id, {
    BannerPriority priority = BannerPriority.HIGH,
    int? userLevel,
    bool forceRefresh = false
  }) async {
    // Adjust priority based on level if provided
    if (userLevel != null) {
      final bannerLevel = getBannerIdForLevel(id);
      priority = _getPriorityForLevel(bannerLevel, userLevel);
    }

    try {
      // Check cache first (unless forced refresh)
      if (!forceRefresh && _bannerCache.containsKey(id) && _bannerCache[id]!.isValid) {
        final cached = _bannerCache[id]!;
        
        // If cached priority is lower than requested, queue refresh
        if (_getPriorityLevel(cached.priority) < _getPriorityLevel(priority)) {
          _queueBackgroundUpdate(id, priority);
        }
        
        return cached.data;
      }

      final quality = await _connectionManager.checkConnectionQuality();
      
      switch (quality) {
        case ConnectionQuality.OFFLINE:
          return await _getFromLocalStorageWithPriority(id, priority);
          
        case ConnectionQuality.POOR:
          // Use local storage but queue background update for high priority
          var localBanner = await _getFromLocalStorageWithPriority(id, priority);
          if (localBanner != null) {
            if (_getPriorityLevel(priority) >= _getPriorityLevel(BannerPriority.HIGH)) {
              _queueBackgroundUpdate(id, priority);
            }
            return localBanner;
          }
          // Fall through to server fetch if no local data
          break;
          
        case ConnectionQuality.GOOD:
        case ConnectionQuality.EXCELLENT:
          return await _fetchFromServerWithPriority(id, priority);
      }
      
      return null;
    } catch (e) {
      print('Error in getBannerDetails: $e');
      return _bannerCache[id]?.data;  // Return cached data on error
    }
  }

  // Helper for priority comparison
  int _getPriorityLevel(BannerPriority priority) {
    return BannerPriority.values.indexOf(priority);
  }

  // Renamed to avoid conflicts
  Future<Map<String, dynamic>?> _getFromLocalStorageWithPriority(
    int id,
    BannerPriority priority
  ) async {
    final localBanners = await _getBannersFromLocal();
    final banner = localBanners.firstWhere(
      (b) => b['id'] == id,
      orElse: () => {},
    );
    
    if (banner.isNotEmpty) {
      _addToCache(id, banner, priority: priority);
      return banner;
    }
    return null;
  }

  // Renamed to avoid conflicts
  Future<Map<String, dynamic>?> _fetchFromServerWithPriority(
    int id,
    BannerPriority priority
  ) async {
    try {
      final timeout = _getTimeoutForPriority(priority);
      DocumentSnapshot doc = await _bannerDoc.get().timeout(timeout);
            
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> banners = 
            List<Map<String, dynamic>>.from(data['banners'] ?? []);
              
        var serverBanner = banners.firstWhere(
          (b) => b['id'] == id,
          orElse: () => {},
        );
          
        if (serverBanner.isNotEmpty) {
          _addToCache(id, serverBanner, priority: priority);
          return serverBanner;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching from server: $e');
      return null;
    }
  }

  // Add background update queueing
  void _queueBackgroundUpdate(int id, BannerPriority priority) {
    queueBannerLoad(id, priority);
    _debouncedSync();
  }

  // Add priority-based fetch method
  Future<Map<String, dynamic>?> _fetchBannerWithPriority(
    int id,
    BannerPriority priority
  ) async {
    try {
      final quality = await _connectionManager.checkConnectionQuality();

      switch (quality) {
        case ConnectionQuality.OFFLINE:
          return await _getFromLocalStorage(id);
          
        case ConnectionQuality.POOR:
          // Use local storage but queue background update
          var localBanner = await _getFromLocalStorage(id);
          if (localBanner != null) {
            _queueBackgroundUpdate(id, priority);
            return localBanner;
          }
          break;
          
        case ConnectionQuality.GOOD:
        case ConnectionQuality.EXCELLENT:
          return await _fetchFromServer(id, priority);
      }
      
      return null;
    } catch (e) {
      print('Error in _fetchBannerWithPriority: $e');
      return null;
    }
  }

  // Add queue processing method
  Future<void> _processQueue(BannerPriority priority) async {
    final queue = _loadQueues[priority]!;
    while (queue.isNotEmpty) {
      final bannerId = queue.removeFirst();
      try {
        final banner = await _fetchBannerWithPriority(bannerId, priority);
        if (banner != null) {
          _addToCache(bannerId, banner);
        }
      } catch (e) {
        print('Error processing banner $bannerId: $e');
      }
    }
  }

  // Add helper methods
  Duration _getTimeoutForPriority(BannerPriority priority) {
    switch (priority) {
      case BannerPriority.CRITICAL:
        return const Duration(seconds: 10);
      case BannerPriority.HIGH:
        return const Duration(seconds: 5);
      case BannerPriority.MEDIUM:
        return const Duration(seconds: 3);
      case BannerPriority.LOW:
        return const Duration(seconds: 2);
    }
  }

  void queueBannerLoad(int bannerId, BannerPriority priority) {
    if (!_loadQueues[priority]!.contains(bannerId)) {
      _loadQueues[priority]!.add(bannerId);
      _debouncedSync();
    }
  }

  // Helper methods for different storage types
  Future<Map<String, dynamic>?> _getFromLocalStorage(int id) async {
    List<Map<String, dynamic>> localBanners = await _getBannersFromLocal();
    var banner = localBanners.firstWhere(
      (b) => b['id'] == id,
      orElse: () => {},
    );
    
    if (banner.isNotEmpty) {
      _addToCache(id, banner);
      return banner;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchFromServer(
    int id, 
    BannerPriority priority
  ) async {
    try {
      final timeout = _getTimeoutForPriority(priority);
      DocumentSnapshot doc = await _bannerDoc.get().timeout(timeout);
            
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> banners = 
            List<Map<String, dynamic>>.from(data['banners'] ?? []);
              
        var serverBanner = banners.firstWhere(
          (b) => b['id'] == id,
          orElse: () => {},
        );
          
        if (serverBanner.isNotEmpty) {
          _addToCache(id, serverBanner);
          return serverBanner;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching from server: $e');
      return null;
    }
  }

  // Unified sync system
  Future<void> _syncWithServer() async {
    if (_isSyncing) {
      print('🔄 Banner sync already in progress, skipping...');
      return;
    }

    try {
      print('🔄 Starting banner sync process');
      _setSyncStatus(true);

      // Add integrity check before proceeding
      await _verifyDataIntegrity();

      final quality = await _connectionManager.checkConnectionQuality();
      
      switch (quality) {
        case ConnectionQuality.OFFLINE:
          print('📱 Offline mode: Skipping sync');
          return;
          
        case ConnectionQuality.POOR:
          print('📡 Poor connection: Processing critical updates only');
          await _processQueue(BannerPriority.CRITICAL);
          break;
          
        case ConnectionQuality.GOOD:
          print('🌐 Good connection: Processing high priority updates');
          await _processQueue(BannerPriority.CRITICAL);
          await _processQueue(BannerPriority.HIGH);
          await _processQueue(BannerPriority.MEDIUM);
          break;
          
        case ConnectionQuality.EXCELLENT:
          print('🚀 Excellent connection: Processing all updates');
          for (var priority in BannerPriority.values) {
            await _processQueue(priority);
          }
          
          // Only do full sync on excellent connection
          await _performFullSync();
          break;
      }

    } catch (e) {
      print('❌ Error in sync: $e');
      await _logBannerOperation('sync_error', -1, e.toString());
    } finally {
      print('🏁 Banner sync process completed');
      _setSyncStatus(false);
    }
  }

  Future<void> _processAllQueues() async {
    for (var priority in BannerPriority.values) {
      await _processQueue(priority);
    }
  }

  Future<void> _performFullSync() async {
    try {
      DocumentSnapshot snapshot = await _bannerDoc.get()
          .timeout(const Duration(seconds: 5));

      if (!snapshot.exists) {
        print('❌ Banner document not found on server');
        return;
      }

      int serverRevision = snapshot.get('revision') ?? 0;
      int? localRevision = await _getLocalRevision();

      print('📊 Server revision: $serverRevision, Local revision: $localRevision');

      if (localRevision == null || serverRevision > localRevision) {
        print('🔄 Server has newer data, updating local cache');
        List<Map<String, dynamic>> serverBanners = 
            await _fetchAndUpdateLocal(snapshot);
        
        print('💾 Updating memory cache');
        for (var banner in serverBanners) {
          _addToCache(banner['id'], banner);
        }

        print('📢 Notifying listeners of updates');
        _bannerUpdateController.add(serverBanners);
      } else {
        print('✅ Local data is up to date');
      }
    } catch (e) {
      print('❌ Error in full sync: $e');
      throw e;
    }
  }

  void _setSyncStatus(bool syncing) {
    _isSyncing = syncing;
    _syncStatusController.add(_isSyncing);
  }

  void triggerBackgroundSync() {
    _debouncedSync();
  }

  void _debouncedSync() {
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _syncWithServer();
    });
  }

  // Add method to queue banner loading
  void _addToCache(
    int id, 
    Map<String, dynamic> data, {
    BannerPriority priority = BannerPriority.HIGH
  }) {
    _bannerCache[id] = CachedBanner(
      data, 
      DateTime.now(),
      priority: priority
    );
    
    if (priority == BannerPriority.CRITICAL) {
      _prewarmedBanners.add(id);
    }
    
    _manageCacheSize();
  }

  void _addToBatchCache(
    String key, 
    List<Map<String, dynamic>> data, {
    BannerPriority priority = BannerPriority.HIGH
  }) {
    _batchCache[key] = CachedBanner(
      {'banners': data}, 
      DateTime.now(),
      priority: priority
    );
  }

  // Keep other existing methods unchanged for now
  Future<List<Map<String, dynamic>>> fetchBanners({
    BannerPriority priority = BannerPriority.HIGH
  }) async {
    try {
      final cacheKey = 'all_banners';
      
      // Check batch cache first
      if (_batchCache.containsKey(cacheKey) && _batchCache[cacheKey]!.isValid) {
        return List<Map<String, dynamic>>.from(_batchCache[cacheKey]!.data['banners']);
      }

      // Try local storage first
      List<Map<String, dynamic>> localBanners = await _getBannersFromLocal();
      
      if (localBanners.isEmpty) {
        final quality = await _connectionManager.checkConnectionQuality();
        
        switch (quality) {
          case ConnectionQuality.OFFLINE:
            return [];
            
          case ConnectionQuality.POOR:
            // Queue background update if priority is high enough
            if (priority == BannerPriority.CRITICAL || priority == BannerPriority.HIGH) {
              _debouncedSync();
            }
            return [];
            
          default:
            // Fetch from server with timeout based on priority
            final timeout = _getTimeoutForPriority(priority);
            DocumentSnapshot snapshot = await _bannerDoc.get().timeout(timeout);
            
            if (snapshot.exists) {
              Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
              localBanners = data['banners'] != null ? 
                  List<Map<String, dynamic>>.from(data['banners']) : [];
              
              // Update caches and local storage
              _addToBatchCache(cacheKey, localBanners);
              for (var banner in localBanners) {
                _addToCache(banner['id'], banner);
              }
              await _storeBannersLocally(localBanners);
            }
        }
      }
      
      // Queue banners based on priority
      for (var banner in localBanners) {
        queueBannerLoad(banner['id'], priority);
      }
      
      return localBanners;
    } catch (e) {
      print('Error in fetchBanners: $e');
      await _logBannerOperation('fetch_error', -1, e.toString());
      return [];
    }
  }

  Future<bool> getBannerById(int id) async {
    final banner = await getBannerDetails(id);
    return banner != null;
  }

  Future<List<Map<String, dynamic>>> _fetchAndUpdateLocal(DocumentSnapshot snapshot) async {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    List<Map<String, dynamic>> banners = 
        data['banners'] != null ? List<Map<String, dynamic>>.from(data['banners']) : [];
    
    await _storeBannersLocally(banners);
    await _storeLocalRevision(snapshot.get('revision') ?? 0);
    await cleanupOldVersions();
    
    return banners;
  }

  Future<void> _storeBannersLocally(List<Map<String, dynamic>> banners) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // Store backup before updating
      String? existingData = prefs.getString(BANNERS_CACHE_KEY);
      if (existingData != null) {
        await prefs.setString('${BANNERS_CACHE_KEY}_backup', existingData);
      }
      
      String bannersJson = jsonEncode(banners);
      await prefs.setString(BANNERS_CACHE_KEY, bannersJson);
      
      // Clear backup after successful update
      await prefs.remove('${BANNERS_CACHE_KEY}_backup');
    } catch (e) {
      await _restoreFromBackup();
      print('Error storing banners locally: $e');
    }
  }

  Future<void> _restoreFromBackup() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? backup = prefs.getString('${BANNERS_CACHE_KEY}_backup');
      if (backup != null) {
        await prefs.setString(BANNERS_CACHE_KEY, backup);
      }
    } catch (e) {
      print('Error restoring from backup: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getBannersFromLocal() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? bannersJson = prefs.getString(BANNERS_CACHE_KEY);
      if (bannersJson != null) {
        List<dynamic> bannersList = jsonDecode(bannersJson);
        return bannersList.map((banner) => banner as Map<String, dynamic>).toList();
      }
    } catch (e) {
      print('Error getting banners from local: $e');
    }
    return [];
  }

  Future<void> cleanupOldVersions() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final oldKeys = prefs.getKeys()
          .where((key) => key.startsWith('banner_version_'))
          .toList();
      
      if (oldKeys.length > MAX_STORED_VERSIONS) {
        oldKeys.sort();
        for (var key in oldKeys.take(oldKeys.length - MAX_STORED_VERSIONS)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Error cleaning up versions: $e');
    }
  }

  Future<void> _logBannerOperation(
    String operation,
    int bannerId,
    String details, {
    Map<String, dynamic>? metadata  // Add metadata for admin operations
  }) async {
    try {
      await FirebaseFirestore.instance.collection('Logs').add({
        'type': 'banner_operation',
        'operation': operation,
        'bannerId': bannerId,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        if (metadata != null) 'metadata': metadata,  // Include admin metadata if present
      });
    } catch (e) {
      print('Error logging operation: $e');
    }
  }

  Future<int?> _getLocalRevision() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(BANNER_REVISION_KEY);
  }

  Future<void> _storeLocalRevision(int revision) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(BANNER_REVISION_KEY, revision);
  }

  void clearBannerCache(int id) {
    _bannerCache.remove(id);
  }

  void dispose() {
    _bannerUpdateController.close();
    _profileSubscription.cancel();
    _syncStatusController.close();
    clearPrewarmTracking();
  }

  // Add data validation method
  bool _validateBannerData(Map<String, dynamic> banner) {
    return banner.containsKey('id') &&
           banner.containsKey('img') &&
           banner.containsKey('title') &&
           banner['img'].toString().isNotEmpty &&
           banner['title'].toString().isNotEmpty;
  }

  // Add data integrity verification
  Future<void> _verifyDataIntegrity() async {
    try {
      print('🔍 Verifying banner data integrity');
      
      // Get both server and local data
      List<Map<String, dynamic>> serverBanners = [];
      List<Map<String, dynamic>> localBanners = await _getBannersFromLocal();
      
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot snapshot = await _bannerDoc.get();
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          serverBanners = List<Map<String, dynamic>>.from(data['banners'] ?? []);
        }
      }

      bool needsRepair = false;
      
      // 1. Check for duplicate IDs
      Set<int> seenIds = {};
      for (var banner in localBanners) {
        int id = banner['id'];
        if (seenIds.contains(id)) {
          print('⚠️ Found duplicate banner ID: $id');
          needsRepair = true;
          break;
        }
        seenIds.add(id);
      }

      // 2. Validate required fields
      for (var banner in localBanners) {
        if (!_validateBannerData(banner)) {
          print('⚠️ Invalid banner data found: ${banner['id']}');
          needsRepair = true;
          break;
        }
      }

      // 3. Compare with server data if available
      if (serverBanners.isNotEmpty && serverBanners.length != localBanners.length) {
        print('⚠️ Data mismatch: Server has ${serverBanners.length} banners, local has ${localBanners.length}');
        needsRepair = true;
      }

      // Repair if needed
      if (needsRepair) {
        print('🔧 Repairing banner data');
        await resolveConflicts(serverBanners, localBanners);
        await _logBannerOperation('integrity_repair', -1, 'Data repaired');
      }

      // Verify unlock state
      await _verifyUnlockState();

    } catch (e) {
      print('❌ Error verifying data integrity: $e');
      await _logBannerOperation('integrity_check_error', -1, e.toString());
    }
  }

  // Add unlock state verification
  Future<void> _verifyUnlockState() async {
    try {
      print('🔍 Verifying banner unlock state');
      
      final userProfile = await _userProfileService.fetchUserProfile();
      if (userProfile == null) return;

      // 1. Verify unlock array size matches banner count
      List<Map<String, dynamic>> banners = await fetchBanners();
      if (userProfile.unlockedBanner.length != banners.length) {
        print('⚠️ Unlock array size mismatch. Resizing...');
        List<int> newUnlockedBanner = List<int>.filled(banners.length, 0);
        for (int i = 0; i < userProfile.unlockedBanner.length && i < banners.length; i++) {
          newUnlockedBanner[i] = userProfile.unlockedBanner[i];
        }
        await _userProfileService.updateProfileWithIntegration(
          'unlockedBanner',
          newUnlockedBanner
        );
      }

      // 2. Verify current banner exists and is unlocked
      if (userProfile.bannerId > 0) {
        final bannerExists = await getBannerDetails(userProfile.bannerId) != null;
        final bannerLevel = getBannerIdForLevel(userProfile.bannerId);
        final isUnlocked = userProfile.level >= bannerLevel;

        if (!bannerExists || !isUnlocked) {
          print('⚠️ Current banner invalid or locked. Resetting to default...');
          await _userProfileService.updateProfileWithIntegration('bannerId', 0);
        }
      }

      print('✅ Banner unlock state verified');

    } catch (e) {
      print('❌ Error verifying unlock state: $e');
      await _logBannerOperation('unlock_verify_error', -1, e.toString());
    }
  }

  Future<void> resolveConflicts(
    List<Map<String, dynamic>> serverBanners, 
    List<Map<String, dynamic>> localBanners
  ) async {
    try {
      Map<int, Map<String, dynamic>> mergedBanners = {};
      
      // First add all server banners
      for (var banner in serverBanners) {
        if (banner.containsKey('id')) {
          mergedBanners[banner['id']] = banner;
        }
      }
      
      // Then merge local banners, keeping newer versions
      for (var localBanner in localBanners) {
        if (!localBanner.containsKey('id')) continue;
        
        int id = localBanner['id'];
        if (!mergedBanners.containsKey(id) || 
            (localBanner['lastModified'] ?? 0) > (mergedBanners[id]!['lastModified'] ?? 0)) {
          mergedBanners[id] = localBanner;
        }
      }
      
      // Convert back to list and ensure all required fields exist
      List<Map<String, dynamic>> resolvedBanners = mergedBanners.values
          .where((banner) => 
              banner.containsKey('id') && 
              banner.containsKey('img') && 
              banner.containsKey('title'))
          .toList();
      
      // Sort by ID to maintain consistent order
      resolvedBanners.sort((a, b) => a['id'].compareTo(b['id']));
      
      // Update both local and server
      await _storeBannersLocally(resolvedBanners);
      await _updateServerBanners(resolvedBanners);
      
      // Update memory cache
      _bannerCache.clear();
      for (var banner in resolvedBanners) {
        _addToCache(banner['id'], banner);
      }
      
      // Notify listeners of the changes
      _bannerUpdateController.add(resolvedBanners);
    } catch (e) {
      print('Error resolving conflicts: $e');
      await _logBannerOperation('conflict_resolution_error', -1, e.toString());
    }
  }

  Future<void> _updateServerBanners(List<Map<String, dynamic>> banners) async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _bannerDoc.update({
          'banners': banners,
          'revision': FieldValue.increment(1),
          'lastModified': FieldValue.serverTimestamp(),
        });
        await _logBannerOperation('server_update', -1, 'Updated ${banners.length} banners');
      }
    } catch (e) {
      print('Error updating server banners: $e');
      await _logBannerOperation('server_update_error', -1, e.toString());
      rethrow;
    }
  }

  Future<void> addBanner(Map<String, dynamic> banner) async {
    try {
      int nextId = await getNextId();
      banner['id'] = nextId;
      
      List<Map<String, dynamic>> banners = await fetchBanners();
      banners.add(banner);
      
      await _storeBannersLocally(banners);
      await _updateServerBanners(banners);

      // Log admin creation
      await _logBannerOperation(
        'admin_create',
        nextId,
        'Banner created',
        metadata: {
          'title': banner['title'],
          'img': banner['img'],
        }
      );
    } catch (e) {
      print('Error adding banner: $e');
      await _logBannerOperation('add_error', -1, e.toString());
      rethrow;
    }
  }

  Future<void> updateBanner(int id, Map<String, dynamic> updatedBanner) async {
    try {
      List<Map<String, dynamic>> banners = await fetchBanners();
      int index = banners.indexWhere((b) => b['id'] == id);
      if (index != -1) {
        // Store old data for logging
        final oldBanner = banners[index];
        banners[index] = updatedBanner;
        
        await _storeBannersLocally(banners);
        await _updateServerBanners(banners);

        // Log admin update with changes
        await _logBannerOperation(
          'admin_update',
          id,
          'Banner updated',
          metadata: {
            'old': oldBanner,
            'new': updatedBanner,
            'changedFields': _getChangedFields(oldBanner, updatedBanner),
          }
        );
      }
    } catch (e) {
      print('Error updating banner: $e');
      await _logBannerOperation('update_error', id, e.toString());
      rethrow;
    }
  }

  Future<void> deleteBanner(int id) async {
    try {
      List<Map<String, dynamic>> banners = await fetchBanners();
      final deletedBanner = banners.firstWhere((b) => b['id'] == id);
      banners.removeWhere((b) => b['id'] == id);
      
      await _storeBannersLocally(banners);
      await _updateServerBanners(banners);

      // Log admin deletion
      await _logBannerOperation(
        'admin_delete',
        id,
        'Banner deleted',
        metadata: {
          'deletedBanner': deletedBanner,
        }
      );
    } catch (e) {
      print('Error deleting banner: $e');
      await _logBannerOperation('delete_error', id, e.toString());
      rethrow;
    }
  }

  Future<int> getNextId() async {
    try {
      // Try to get from Firebase first
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot snapshot = await _bannerDoc.get();
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          List<Map<String, dynamic>> banners = 
              data['banners'] != null ? List<Map<String, dynamic>>.from(data['banners']) : [];
          if (banners.isNotEmpty) {
            return banners.map((banner) => banner['id'] as int).reduce((a, b) => a > b ? a : b) + 1;
          }
        }
        return 0;
      }

      // If offline, calculate from local storage
      List<Map<String, dynamic>> localBanners = await _getBannersFromLocal();
      if (localBanners.isNotEmpty) {
        return localBanners.map((banner) => banner['id'] as int).reduce((a, b) => a > b ? a : b) + 1;
      }
      return 0;
    } catch (e) {
      print('Error getting next banner ID: $e');
      return 0; // Start with 0 in case of error
    }
  }

  Future<List<Map<String, dynamic>>> getLocalBanners() async {
    return _getBannersFromLocal();
  }

  void _manageCacheSize() {
    if (_bannerCache.length > MAX_CACHE_SIZE) {
      var entries = _bannerCache.entries.toList()
        ..sort((a, b) {
          // First: Compare priorities
          final priorityCompare = b.value.priority.index.compareTo(
            a.value.priority.index
          );
          if (priorityCompare != 0) return priorityCompare;

          // Second: Keep prewarmed banners
          final isPrewarmedA = _prewarmedBanners.contains(a.key);
          final isPrewarmedB = _prewarmedBanners.contains(b.key);
          if (isPrewarmedA != isPrewarmedB) {
            return isPrewarmedB ? 1 : -1;
          }

          // Last: Compare timestamps
          return a.value.timestamp.compareTo(b.value.timestamp);
        });

      // Remove entries until we're under limit
      while (_bannerCache.length > MAX_CACHE_SIZE) {
        var entry = entries.removeLast();
        _bannerCache.remove(entry.key);
        _prewarmedBanners.remove(entry.key);
      }
    }
  }

  // Add helper method for cache priority
  BannerPriority _getCachePriorityForBanner(int bannerId) {
    // Get current user level (from latest banner fetch)
    final currentLevel = getBannerIdForLevel(bannerId);
    
    // Current level banner
    if (bannerId == currentLevel) {
      return BannerPriority.CRITICAL;
    }
    
    // Next level banner
    if (bannerId == currentLevel + 1) {
      return BannerPriority.HIGH;
    }
    
    // Soon-to-unlock banners
    if (bannerId <= currentLevel + PRELOAD_AHEAD) {
      return BannerPriority.MEDIUM;
    }
    
    // Far-future banners
    return BannerPriority.LOW;
  }

  Future<List<Map<String, dynamic>>> _recoverFromError() async {
    try {
      // Try to restore from backup first
      await _restoreFromBackup();
      
      // Clear corrupted cache
      _bannerCache.clear();
      
      // Try to get from local storage
      List<Map<String, dynamic>> localBanners = await _getBannersFromLocal();
      if (localBanners.isNotEmpty) {
        return localBanners;
      }
      
      // If all else fails, try server
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot snapshot = await _bannerDoc.get();
        if (snapshot.exists) {
          return await _fetchAndUpdateLocal(snapshot);
        }
      }
      
      return [];
    } catch (e) {
      print('Error in recovery attempt: $e');
      return [];
    }
  }


  // Add after existing properties
  static const int MAX_BANNER_LEVEL = 9;
  static const int PRELOAD_AHEAD = 2;

  // Add level-based loading methods
  Future<void> loadBannersForLevel(int userLevel) async {
    try {
      print('🎯 Loading banners for user level $userLevel');
      
      // Current level banner (CRITICAL)
      await getBannerDetails(
        getBannerIdForLevel(userLevel), 
        priority: BannerPriority.CRITICAL
      );
      
      // Next level banner (HIGH)
      if (userLevel < MAX_BANNER_LEVEL) {
        print('🔄 Preloading next level banner');
        queueBannerLoad(
          getBannerIdForLevel(userLevel + 1), 
          BannerPriority.HIGH
        );
      }
      
      // Soon-to-unlock banners (MEDIUM)
      final maxPreload = userLevel + PRELOAD_AHEAD;
      for (var level = userLevel + 2; 
           level <= min(maxPreload, MAX_BANNER_LEVEL); 
           level++) {
        print('📥 Queueing banner for level $level');
        queueBannerLoad(
          getBannerIdForLevel(level), 
          BannerPriority.MEDIUM
        );
      }
      
      // Remaining banners (LOW)
      for (var level = maxPreload + 1; 
           level <= MAX_BANNER_LEVEL; 
           level++) {
        queueBannerLoad(
          getBannerIdForLevel(level), 
          BannerPriority.LOW
        );
      }
    } catch (e) {
      print('❌ Error in loadBannersForLevel: $e');
      await _logBannerOperation('level_load_error', userLevel, e.toString());
    }
  }

  // Helper method for level-based banner ID
  int getBannerIdForLevel(int level) {
    return level.clamp(1, MAX_BANNER_LEVEL);
  }

  // Update existing fetchBanners to accept userLevel
  Future<List<Map<String, dynamic>>> fetchBannersWithLevel({
    BannerPriority priority = BannerPriority.HIGH,
    int? userLevel
  }) async {
    final banners = await fetchBanners();
    
    if (userLevel != null) {
      await loadBannersForLevel(userLevel);
    }
    
    return banners;
  }

  // Add priority adjustment helper
  BannerPriority _adjustPriorityForLevel(
    int bannerId, 
    int currentLevel, 
    BannerPriority basePriority
  ) {
    if (bannerId == currentLevel) {
      return BannerPriority.CRITICAL;
    }
    
    if (bannerId == currentLevel + 1) {
      return basePriority == BannerPriority.CRITICAL 
          ? BannerPriority.CRITICAL 
          : BannerPriority.HIGH;
    }
    
    if (bannerId <= currentLevel + PRELOAD_AHEAD) {
      return _getPriorityLevel(basePriority) <= _getPriorityLevel(BannerPriority.MEDIUM)
          ? basePriority 
          : BannerPriority.MEDIUM;
    }
    
    return basePriority;
  }


  // Add prewarming constants and properties
  static const int PREWARM_BATCH_SIZE = 2;
  static const Duration PREWARM_DELAY = Duration(milliseconds: 100);
  bool _isPrewarming = false;
  final Set<int> _prewarmedBanners = {};

  // Add prewarm methods
  Future<void> prewarmBannerCache(int userLevel) async {
    if (_isPrewarming) {
      print('🔄 Cache prewarming already in progress');
      return;
    }

    try {
      print('🔥 Starting banner cache prewarm for level $userLevel');
      _isPrewarming = true;

      final quality = await _connectionManager.checkConnectionQuality();
      
      switch (quality) {
        case ConnectionQuality.OFFLINE:
          print('📱 Offline mode: Prewarming from local storage');
          await _prewarmFromLocal(userLevel);
          break;

        case ConnectionQuality.POOR:
          print('📡 Poor connection: Prewarming critical banners only');
          await _prewarmCriticalBanners(userLevel);
          break;

        case ConnectionQuality.GOOD:
        case ConnectionQuality.EXCELLENT:
          print('🚀 Good connection: Full prewarm');
          await _prewarmAllBanners(userLevel);
          break;
      }

    } catch (e) {
      print('❌ Error prewarming cache: $e');
      await _logBannerOperation('prewarm_error', userLevel, e.toString());
    } finally {
      _isPrewarming = false;
    }
  }

  Future<void> _prewarmCriticalBanners(int userLevel) async {
    // Current level banner (CRITICAL)
    if (!_prewarmedBanners.contains(userLevel)) {
      await getBannerDetails(
        getBannerIdForLevel(userLevel),
        priority: BannerPriority.CRITICAL
      );
      _prewarmedBanners.add(userLevel);
    }

    // Next level banner (HIGH)
    if (userLevel < MAX_BANNER_LEVEL && !_prewarmedBanners.contains(userLevel + 1)) {
      await getBannerDetails(
        getBannerIdForLevel(userLevel + 1),
        priority: BannerPriority.HIGH
      );
      _prewarmedBanners.add(userLevel + 1);
    }
  }

  Future<void> _prewarmFromLocal(int userLevel) async {
    final localBanners = await _getBannersFromLocal();
    
    // Prioritize current and next level
    for (var banner in localBanners) {
      final bannerId = banner['id'];
      if (bannerId == userLevel || bannerId == userLevel + 1) {
        _addToCache(bannerId, banner);
        _prewarmedBanners.add(bannerId);
      }
    }
  }

  Future<void> _prewarmAllBanners(int userLevel) async {
    // First load critical banners
    await _prewarmCriticalBanners(userLevel);

    // Then load soon-to-unlock banners in batches
    final maxPreload = min(userLevel + PRELOAD_AHEAD, MAX_BANNER_LEVEL);
    for (var level = userLevel + 2; level <= maxPreload; level += PREWARM_BATCH_SIZE) {
      final batch = List.generate(
        PREWARM_BATCH_SIZE,
        (index) => level + index,
      ).where((l) => l <= maxPreload);

      await Future.wait(
        batch.map((level) async {
          if (!_prewarmedBanners.contains(level)) {
            await getBannerDetails(
              getBannerIdForLevel(level),
              priority: BannerPriority.MEDIUM
            );
            _prewarmedBanners.add(level);
          }
        })
      );

      // Add delay between batches
      await Future.delayed(PREWARM_DELAY);
    }

    // Queue remaining banners for background loading
    for (var level = maxPreload + 1; level <= MAX_BANNER_LEVEL; level++) {
      if (!_prewarmedBanners.contains(level)) {
        queueBannerLoad(
          getBannerIdForLevel(level),
          BannerPriority.LOW
        );
      }
    }
  }

  // Add cleanup method
  void clearPrewarmTracking() {
    _prewarmedBanners.clear();
  }

  // Add level-based loading methods
  Future<List<Map<String, dynamic>>> fetchBannersForLevel({
    required int userLevel,
    BannerPriority priority = BannerPriority.HIGH
  }) async {
    try {
      print('🎯 Loading banners for user level $userLevel');
      final banners = await fetchBanners();
      
      // Process banners based on level
      for (var banner in banners) {
        final bannerId = banner['id'];
        final bannerLevel = getBannerIdForLevel(bannerId);
        
        if (bannerLevel == userLevel) {
          // Current level banner - CRITICAL
          await getBannerDetails(
            bannerId,
            priority: BannerPriority.CRITICAL
          );
        } else if (bannerLevel == userLevel + 1) {
          // Next level banner - HIGH
          queueBannerLoad(bannerId, BannerPriority.HIGH);
        } else if (bannerLevel <= userLevel + PRELOAD_AHEAD) {
          // Soon-to-unlock banners - MEDIUM
          queueBannerLoad(bannerId, BannerPriority.MEDIUM);
        } else {
          // Far-future banners - LOW
          queueBannerLoad(bannerId, BannerPriority.LOW);
        }
      }
      
      return banners;
    } catch (e) {
      print('❌ Error loading banners for level: $e');
      await _logBannerOperation('level_load_error', userLevel, e.toString());
      return [];
    }
  }

  // Helper method for level-based priority
  BannerPriority _getPriorityForLevel(int bannerLevel, int userLevel) {
    if (bannerLevel == userLevel) {
      return BannerPriority.CRITICAL;
    } else if (bannerLevel == userLevel + 1) {
      return BannerPriority.HIGH;
    } else if (bannerLevel <= userLevel + PRELOAD_AHEAD) {
      return BannerPriority.MEDIUM;
    }
    return BannerPriority.LOW;
  }

  // Add progressive loading constants
  static const int VIEWPORT_BUFFER = 2;  // Number of items to buffer
  static const int BATCH_SIZE = 5;       // Items per batch
  static const Duration BATCH_DELAY = Duration(milliseconds: 100);

  // Add viewport tracking
  final Map<String, Set<int>> _loadedBatches = {};

  // Add progressive loading methods
  Future<void> handleViewportChange({
    required int startIndex,
    required int endIndex,
    required String cacheKey,
    int? userLevel,
  }) async {
    try {
      print('👁️ Viewport changed: $startIndex to $endIndex');
      
      // Initialize batch tracking for this cache key
      _loadedBatches[cacheKey] ??= {};

      // Calculate visible range with buffer
      final bufferedStart = max(0, startIndex - VIEWPORT_BUFFER);
      final bufferedEnd = min(MAX_BANNER_LEVEL, endIndex + VIEWPORT_BUFFER);

      // Load visible banners first
      await _loadVisibleBanners(
        bufferedStart, 
        bufferedEnd, 
        cacheKey,
        userLevel
      );

      // Queue adjacent banners
      _queueAdjacentBanners(
        bufferedStart, 
        bufferedEnd, 
        cacheKey,
        userLevel
      );

    } catch (e) {
      print('❌ Error handling viewport change: $e');
    }
  }

  Future<void> _loadVisibleBanners(
    int start,
    int end,
    String cacheKey,
    int? userLevel,
  ) async {
    final visibleBatch = List.generate(
      end - start + 1,
      (index) => start + index,
    );

    // Load in batches
    for (var i = 0; i < visibleBatch.length; i += BATCH_SIZE) {
      final batchEnd = min(i + BATCH_SIZE, visibleBatch.length);
      final batch = visibleBatch.sublist(i, batchEnd);
      
      if (!_isBatchLoaded(batch, cacheKey)) {
        await Future.wait(
          batch.map((id) => getBannerDetails(
            id,
            priority: _getPriorityForBatch(id, userLevel),
          ))
        );
        
        _markBatchLoaded(batch, cacheKey);
        await Future.delayed(BATCH_DELAY);
      }
    }
  }

  void _queueAdjacentBanners(
    int start,
    int end,
    String cacheKey,
    int? userLevel,
  ) {
    // Queue banners just outside viewport
    final preloadStart = max(0, start - BATCH_SIZE);
    final preloadEnd = min(MAX_BANNER_LEVEL, end + BATCH_SIZE);
    
    for (var id = preloadStart; id <= preloadEnd; id++) {
      if (id < start || id > end) {  // Outside current viewport
        queueBannerLoad(
          id,
          _getPriorityForBatch(id, userLevel) // Use level-based priority if available
        );
      }
    }
  }

  // Helper methods
  bool _isBatchLoaded(List<int> batch, String cacheKey) {
    return batch.every((id) => _loadedBatches[cacheKey]?.contains(id) ?? false);
  }

  void _markBatchLoaded(List<int> batch, String cacheKey) {
    _loadedBatches[cacheKey]?.addAll(batch);
  }

  BannerPriority _getPriorityForBatch(int bannerId, int? userLevel) {
    if (userLevel != null) {
      return _getPriorityForLevel(bannerId, userLevel);
    }
    return BannerPriority.MEDIUM;
  }

  // Add cleanup method
  void clearProgressiveLoadingState(String cacheKey) {
    _loadedBatches.remove(cacheKey);
  }

  static const String PENDING_UNLOCKS_KEY = 'pending_banner_unlocks';

  Future<void> checkLevelUnlock(int newLevel) async {
    try {
      print('🎯 Checking banner unlocks for level $newLevel');
      final quality = await _connectionManager.checkConnectionQuality();
      
      // Get current unlocked banners from profile
      final userProfile = await _userProfileService.fetchUserProfile();
      if (userProfile == null) return;

      List<int> updatedUnlockedBanners = List<int>.from(userProfile.unlockedBanner);
      
      // Check for new unlocks
      if (newLevel <= MAX_BANNER_LEVEL) {
        updatedUnlockedBanners[newLevel] = 1;
        
        if (quality == ConnectionQuality.OFFLINE) {
          // Queue unlock for later
          await _queueUnlock(PendingBannerUnlock(
            bannerId: newLevel,
            unlockedAtLevel: newLevel,
            timestamp: DateTime.now(),
          ));
        } else {
          // Update profile immediately
          await _userProfileService.updateProfileWithIntegration(
            'unlockedBanner',
            updatedUnlockedBanners
          );

          // Start preloading new banner
          await getBannerDetails(
            getBannerIdForLevel(newLevel),
            priority: BannerPriority.CRITICAL
          );
        }
      }
    } catch (e) {
      print('❌ Error checking banner unlocks: $e');
      await _logBannerOperation('unlock_error', newLevel, e.toString());
    }
  }

  Future<void> _queueUnlock(PendingBannerUnlock unlock) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> pendingUnlocks = prefs.getStringList(PENDING_UNLOCKS_KEY) ?? [];
      pendingUnlocks.add(jsonEncode(unlock.toJson()));
      await prefs.setStringList(PENDING_UNLOCKS_KEY, pendingUnlocks);
      print('💾 Banner unlock queued for later sync');
    } catch (e) {
      print('❌ Error queueing unlock: $e');
    }
  }

  Future<void> _processPendingUnlocks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> pendingUnlocks = prefs.getStringList(PENDING_UNLOCKS_KEY) ?? [];
      
      if (pendingUnlocks.isEmpty) return;

      print('🔄 Processing ${pendingUnlocks.length} pending unlocks');
      
      for (String unlockJson in pendingUnlocks) {
        final unlock = PendingBannerUnlock.fromJson(jsonDecode(unlockJson));
        await checkLevelUnlock(unlock.unlockedAtLevel);
      }

      await prefs.setStringList(PENDING_UNLOCKS_KEY, []);
      print('✅ All pending unlocks processed');

    } catch (e) {
      print('❌ Error processing pending unlocks: $e');
    }
  }

  late StreamSubscription<UserProfile> _profileSubscription;

  void _setupProfileListener() {
    _profileSubscription = _userProfileService.profileUpdates
      .listen((profile) async {
        // Check for level-based unlocks
        await checkLevelUnlock(profile.level);
      });
  }

  // Helper for tracking changed fields
  String _getChangedFields(
    Map<String, dynamic> oldBanner,
    Map<String, dynamic> newBanner
  ) {
    List<String> changes = [];
    newBanner.forEach((key, value) {
      if (oldBanner[key] != value) {
        changes.add('$key: ${oldBanner[key]} → $value');
      }
    });
    return changes.join(', ');
  }
}