import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class BannerService {
  final DocumentReference _bannerDoc = FirebaseFirestore.instance.collection('Game').doc('Banner');
  static const String BANNERS_CACHE_KEY = 'banners_cache';

  Future<List<Map<String, dynamic>>> fetchBanners() async {
    try {
      // Try to get from Firebase first
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot snapshot = await _bannerDoc.get();
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          List<Map<String, dynamic>> banners = 
              data['banners'] != null ? List<Map<String, dynamic>>.from(data['banners']) : [];
          
          // Cache the fetched data
          await _storeBannersLocally(banners);
          return banners;
        }
      }
      
      // If offline or Firebase fetch failed, get from local storage
      return await _getBannersFromLocal();
    } catch (e) {
      // On error, try to get from local storage
      return await _getBannersFromLocal();
    }
  }

  Future<void> _storeBannersLocally(List<Map<String, dynamic>> banners) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String bannersJson = jsonEncode(banners);
      await prefs.setString(BANNERS_CACHE_KEY, bannersJson);
    } catch (e) {
      // Handle error silently - local storage is a fallback
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
      // Handle error silently
    }
    return []; // Return empty list if local storage fails or is empty
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
      return 0; // Start with 0 in case of error
    }
  }

  Future<void> addBanner(Map<String, dynamic> banner) async {
    try {
      int nextId = await getNextId();
      banner['id'] = nextId;
      
      // Get current banners list
      List<Map<String, dynamic>> banners = await fetchBanners();
      banners.add(banner);
      
      // Save locally first
      await _storeBannersLocally(banners);
      
      // Then update Firebase if online
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _bannerDoc.update({'banners': banners});
      }
    } catch (e) {
      // If Firebase update fails, at least we have local storage
    }
  }

  Future<void> updateBanner(int id, Map<String, dynamic> updatedBanner) async {
    try {
      // Update locally first
      List<Map<String, dynamic>> banners = await _getBannersFromLocal();
      int index = banners.indexWhere((banner) => banner['id'] == id);
      if (index != -1) {
        banners[index] = updatedBanner;
        await _storeBannersLocally(banners);
      }
      
      // Then update Firebase if online
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _bannerDoc.update({'banners': banners});
      }
    } catch (e) {
      // If Firebase update fails, at least we have local storage
    }
  }

  Future<void> deleteBanner(int id) async {
    try {
      // Delete locally first
      List<Map<String, dynamic>> banners = await _getBannersFromLocal();
      banners.removeWhere((banner) => banner['id'] == id);
      await _storeBannersLocally(banners);
      
      // Then update Firebase if online
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _bannerDoc.update({'banners': banners});
      }
    } catch (e) {
      // If Firebase update fails, at least we have local storage
    }
  }
}