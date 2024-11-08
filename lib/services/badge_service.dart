import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class BadgeService {
  final DocumentReference _badgeDoc = FirebaseFirestore.instance.collection('Game').doc('Badge');
  static const String BADGES_CACHE_KEY = 'badges_cache';

  Future<List<Map<String, dynamic>>> fetchBadges() async {
    try {
      // Try to get from Firebase first
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot snapshot = await _badgeDoc.get();
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          List<Map<String, dynamic>> badges = 
              data['badges'] != null ? List<Map<String, dynamic>>.from(data['badges']) : [];
          
          // Cache the fetched data
          await _storeBadgesLocally(badges);
          return badges;
        }
      }
      
      // If offline or Firebase fetch failed, get from local storage
      return await _getBadgesFromLocal();
    } catch (e) {
      // On error, try to get from local storage
      return await _getBadgesFromLocal();
    }
  }

  Future<void> _storeBadgesLocally(List<Map<String, dynamic>> badges) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String badgesJson = jsonEncode(badges);
      await prefs.setString(BADGES_CACHE_KEY, badgesJson);
    } catch (e) {
      // Handle error silently - local storage is a fallback
    }
  }

  Future<List<Map<String, dynamic>>> _getBadgesFromLocal() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? badgesJson = prefs.getString(BADGES_CACHE_KEY);
      if (badgesJson != null) {
        List<dynamic> badgesList = jsonDecode(badgesJson);
        return badgesList.map((badge) => badge as Map<String, dynamic>).toList();
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
        DocumentSnapshot snapshot = await _badgeDoc.get();
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          List<Map<String, dynamic>> badges = 
              data['badges'] != null ? List<Map<String, dynamic>>.from(data['badges']) : [];
          if (badges.isNotEmpty) {
            return badges.map((badge) => badge['id'] as int).reduce((a, b) => a > b ? a : b) + 1;
          }
        }
        return 0;
      }

      // If offline, calculate from local storage
      List<Map<String, dynamic>> localBadges = await _getBadgesFromLocal();
      if (localBadges.isNotEmpty) {
        return localBadges.map((badge) => badge['id'] as int).reduce((a, b) => a > b ? a : b) + 1;
      }
      return 0;
    } catch (e) {
      return 0; // Start with 0 in case of error
    }
  }

  Future<void> addBadge(Map<String, dynamic> badge) async {
    try {
      int nextId = await getNextId();
      badge['id'] = nextId;
      
      // Get current badges list
      List<Map<String, dynamic>> badges = await fetchBadges();
      badges.add(badge);
      
      // Save locally first
      await _storeBadgesLocally(badges);
      
      // Then update Firebase if online
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _badgeDoc.update({'badges': badges});
      }
    } catch (e) {
      // If Firebase update fails, at least we have local storage
    }
  }

  Future<void> updateBadge(int id, Map<String, dynamic> updatedBadge) async {
    try {
      // Update locally first
      List<Map<String, dynamic>> badges = await _getBadgesFromLocal();
      int index = badges.indexWhere((badge) => badge['id'] == id);
      if (index != -1) {
        badges[index] = updatedBadge;
        await _storeBadgesLocally(badges);
      }
      
      // Then update Firebase if online
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _badgeDoc.update({'badges': badges});
      }
    } catch (e) {
      // If Firebase update fails, at least we have local storage
    }
  }

  Future<void> deleteBadge(int id) async {
    try {
      // Delete locally first
      List<Map<String, dynamic>> badges = await _getBadgesFromLocal();
      badges.removeWhere((badge) => badge['id'] == id);
      await _storeBadgesLocally(badges);
      
      // Then update Firebase if online
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _badgeDoc.update({'badges': badges});
      }
    } catch (e) {
      // If Firebase update fails, at least we have local storage
    }
  }
}