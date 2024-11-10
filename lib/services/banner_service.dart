import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class BannerService {
  final DocumentReference _bannerDoc = FirebaseFirestore.instance.collection('Game').doc('Banner');
  static const String BANNERS_CACHE_KEY = 'banners_cache';
  static const String BANNER_REVISION_KEY = 'banner_revision';
  static const int MAX_STORED_VERSIONS = 5;
  static const int MAX_CACHE_SIZE = 100;

  // Memory cache
  final Map<int, Map<String, dynamic>> _bannerCache = {};

  // Stream controller for real-time updates
  final _bannerUpdateController = StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get bannerUpdates => _bannerUpdateController.stream;

  // Sync-related constants and controllers
  static const Duration SYNC_DEBOUNCE = Duration(milliseconds: 500);
  static const Duration SYNC_TIMEOUT = Duration(seconds: 5);
  Timer? _syncDebounceTimer;
  bool _isSyncing = false;
  final StreamController<bool> _syncStatusController = StreamController<bool>.broadcast();
  Stream<bool> get syncStatus => _syncStatusController.stream;

  Future<List<Map<String, dynamic>>> fetchBanners() async {
    try {
      // Try local storage first
      List<Map<String, dynamic>> localBanners = await _getBannersFromLocal();
      
      // If local storage is empty, try fetching from server
      if (localBanners.isEmpty) {
        var connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          DocumentSnapshot snapshot = await _bannerDoc.get();
          if (snapshot.exists) {
            Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
            localBanners = data['banners'] != null ? List<Map<String, dynamic>>.from(data['banners']) : [];
            // Store in local
            await _storeBannersLocally(localBanners);
          }
        }
      }
      
      // Update memory cache
      for (var banner in localBanners) {
        _bannerCache[banner['id']] = banner;
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

  Future<Map<String, dynamic>?> getBannerDetails(int id) async {
    try {
      if (_bannerCache.containsKey(id)) {
        return _bannerCache[id];
      }
      
      List<Map<String, dynamic>> banners = await _getBannersFromLocal();
      var banner = banners.firstWhere((b) => b['id'] == id, orElse: () => {});
      
      if (banner.isNotEmpty) {
        _bannerCache[id] = banner;
        return banner;
      }

      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot snapshot = await _bannerDoc.get();
        if (snapshot.exists) {
          List<Map<String, dynamic>> serverBanners = List<Map<String, dynamic>>.from(
              (snapshot.data() as Map<String, dynamic>)['banners'] ?? []);
          var serverBanner = serverBanners.firstWhere((b) => b['id'] == id, orElse: () => {});
          if (serverBanner.isNotEmpty) {
            _bannerCache[id] = serverBanner;
            return serverBanner;
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error in getBannerById: $e');
      return null;
    }
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

  Future<void> _logBannerOperation(String operation, int bannerId, String details) async {
    try {
      await FirebaseFirestore.instance.collection('Logs').add({
        'type': 'banner_operation',
        'operation': operation,
        'bannerId': bannerId,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
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
    _syncStatusController.close();
  }

  Future<void> _verifyDataIntegrity() async {
    try {
      List<Map<String, dynamic>> serverBanners = [];
      List<Map<String, dynamic>> localBanners = await _getBannersFromLocal();
      
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot snapshot = await _bannerDoc.get();
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          serverBanners = List<Map<String, dynamic>>.from(data['banners'] ?? []);
        }
      }

      bool needsRepair = false;
      
      // Check for duplicate IDs
      Set<int> seenIds = {};
      for (var banner in localBanners) {
        int id = banner['id'];
        if (seenIds.contains(id)) {
          needsRepair = true;
          break;
        }
        seenIds.add(id);
      }

      // Check for required fields
      for (var banner in localBanners) {
        if (!banner.containsKey('id') || 
            !banner.containsKey('img') || 
            !banner.containsKey('title')) {
          needsRepair = true;
          break;
        }
      }

      // Compare with server data if available
      if (serverBanners.isNotEmpty && serverBanners.length != localBanners.length) {
        needsRepair = true;
      }

      if (needsRepair) {
        await resolveConflicts(serverBanners, localBanners);
        await _logBannerOperation('integrity_repair', -1, 'Data repaired');
      }

      // Clear memory cache if repair was needed
      if (needsRepair) {
        _bannerCache.clear();
      }
    } catch (e) {
      print('Error verifying data integrity: $e');
      await _logBannerOperation('integrity_check_error', -1, e.toString());
    }
  }

  Future<void> resolveConflicts(List<Map<String, dynamic>> serverBanners, List<Map<String, dynamic>> localBanners) async {
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
        _bannerCache[banner['id']] = banner;
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
        banners[index] = updatedBanner;
        await _storeBannersLocally(banners);
        await _updateServerBanners(banners);
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
      banners.removeWhere((b) => b['id'] == id);
      await _storeBannersLocally(banners);
      await _updateServerBanners(banners);
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

  void _setSyncStatus(bool syncing) {
    if (_isSyncing != syncing) {
      _isSyncing = syncing;
      _syncStatusController.add(_isSyncing);
    }
  }

  // Add new debounced sync method
  void _debouncedSync() {
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(SYNC_DEBOUNCE, () {
      _syncWithServer();
    });
  }

  // Add new sync method
  Future<void> _syncWithServer() async {
    if (_isSyncing) {
      print('🔄 Banner sync already in progress, skipping...');
      return;
    }

    try {
      print('🔄 Starting banner sync process');
      _setSyncStatus(true);

      // First verify data integrity
      print('🔍 Verifying banner data integrity');
      await _verifyDataIntegrity();

      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print('📡 No internet connection, aborting banner sync');
        return;
      }

      print('📥 Fetching banner data from server');
      // Add timeout to prevent hanging
      DocumentSnapshot snapshot = await _bannerDoc.get()
          .timeout(SYNC_TIMEOUT);

      if (!snapshot.exists) {
        print('❌ Banner document not found on server');
        return;
      }

      int serverRevision = snapshot.get('revision') ?? 0;
      int? localRevision = await _getLocalRevision();

      print('📊 Server revision: $serverRevision, Local revision: $localRevision');

      // Only sync if server has newer data
      if (localRevision == null || serverRevision > localRevision) {
        print('🔄 Server has newer data, updating local cache');
        List<Map<String, dynamic>> serverBanners = 
            await _fetchAndUpdateLocal(snapshot);
        
        // Update memory cache
        print('💾 Updating memory cache with ${serverBanners.length} banners');
        for (var banner in serverBanners) {
          _bannerCache[banner['id']] = banner;
        }

        // Notify listeners
        print('📢 Notifying listeners of banner updates');
        _bannerUpdateController.add(serverBanners);
      } else {
        print('✅ Local banner data is up to date');
      }

    } catch (e) {
      print('❌ Error in banner sync: $e');
      await _logBannerOperation('sync_error', -1, e.toString());
    } finally {
      print('🏁 Banner sync process completed');
      _setSyncStatus(false);
    }
  }

  void _manageCacheSize() {
    if (_bannerCache.length > MAX_CACHE_SIZE) {
      // Remove oldest entries if cache gets too large
      final entriesToRemove = _bannerCache.length - MAX_CACHE_SIZE;
      final sortedKeys = _bannerCache.keys.toList()..sort();
      for (var i = 0; i < entriesToRemove; i++) {
        _bannerCache.remove(sortedKeys[i]);
      }
    }
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
}