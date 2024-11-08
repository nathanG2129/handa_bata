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

  // Memory cache
  final Map<int, Map<String, dynamic>> _bannerCache = {};

  // Stream controller for real-time updates
  final _bannerUpdateController = StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get bannerUpdates => _bannerUpdateController.stream;

  Future<List<Map<String, dynamic>>> fetchBanners() async {
    try {
      List<Map<String, dynamic>> localBanners = await _getBannersFromLocal();
      var connectivityResult = await (Connectivity().checkConnectivity());
      
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot snapshot = await _bannerDoc.get();
        if (snapshot.exists) {
          // Check if revision field exists first
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          int serverRevision = data.containsKey('revision') ? data['revision'] : 0;
          
          if (!data.containsKey('revision')) {
            await _bannerDoc.update({
              'revision': 0,
              'lastModified': FieldValue.serverTimestamp(),
            });
          }
          
          int localRevision = await _getLocalRevision() ?? -1;
          
          if (serverRevision > localRevision || localBanners.isEmpty) {
            final banners = await _fetchAndUpdateLocal(snapshot);
            _bannerUpdateController.add(banners);
            return banners;
          }
        } else {
          await _bannerDoc.set({
            'banners': [],
            'revision': 0,
            'lastModified': FieldValue.serverTimestamp(),
          });
        }
      }
      return localBanners;
    } catch (e) {
      print('Error in fetchBanners: $e');
      await _logBannerOperation('fetch_error', -1, e.toString());
      return await _getBannersFromLocal();
    }
  }

  Future<Map<String, dynamic>?> getBannerById(int id) async {
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

      // Compare with server data if available
      if (serverBanners.isNotEmpty && serverBanners.length != localBanners.length) {
        needsRepair = true;
      }

      if (needsRepair) {
        await resolveConflicts(serverBanners, localBanners);
        await _logBannerOperation('integrity_repair', -1, 'Data repaired');
      }

      _bannerCache.clear();
    } catch (e) {
      print('Error verifying data integrity: $e');
      await _logBannerOperation('integrity_check_error', -1, e.toString());
    }
  }

  Future<void> resolveConflicts(List<Map<String, dynamic>> serverBanners, List<Map<String, dynamic>> localBanners) async {
    try {
      Map<int, Map<String, dynamic>> mergedBanners = {};
      
      for (var banner in serverBanners) {
        mergedBanners[banner['id']] = banner;
      }
      
      for (var localBanner in localBanners) {
        int id = localBanner['id'];
        if (!mergedBanners.containsKey(id) || 
            (localBanner['lastModified'] ?? 0) > (mergedBanners[id]!['lastModified'] ?? 0)) {
          mergedBanners[id] = localBanner;
        }
      }
      
      List<Map<String, dynamic>> resolvedBanners = mergedBanners.values.toList();
      await _storeBannersLocally(resolvedBanners);
      await _updateServerBanners(resolvedBanners);
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
}