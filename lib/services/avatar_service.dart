import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AvatarService {
  final DocumentReference _avatarDoc = FirebaseFirestore.instance.collection('Game').doc('Avatar');
  static const String AVATARS_CACHE_KEY = 'avatars_cache';

  Future<List<Map<String, dynamic>>> fetchAvatars() async {
    try {
      // Always check local cache first
      List<Map<String, dynamic>> localAvatars = await _getAvatarsFromLocal();
      if (localAvatars.isNotEmpty) {
        // If we have cached data, use it immediately
        
        // Try to update cache in background if online
        _updateCacheIfOnline();
        
        return localAvatars;
      }
      
      // If no local cache, then try Firebase
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot snapshot = await _avatarDoc.get();
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          List<Map<String, dynamic>> avatars = 
              data['avatars'] != null ? List<Map<String, dynamic>>.from(data['avatars']) : [];
          
          // Cache the fetched data
          await _storeAvatarsLocally(avatars);
          return avatars;
        }
      }
      
      return []; // Return empty list if both cache and Firebase fail
    } catch (e) {
      return await _getAvatarsFromLocal(); // Final fallback to cache
    }
  }

  Future<void> _storeAvatarsLocally(List<Map<String, dynamic>> avatars) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String avatarsJson = jsonEncode(avatars);
      await prefs.setString(AVATARS_CACHE_KEY, avatarsJson);
    } catch (e) {
      // Handle error silently - local storage is a fallback
    }
  }

  Future<List<Map<String, dynamic>>> _getAvatarsFromLocal() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? avatarsJson = prefs.getString(AVATARS_CACHE_KEY);
      if (avatarsJson != null) {
        List<dynamic> avatarsList = jsonDecode(avatarsJson);
        return avatarsList.map((avatar) => avatar as Map<String, dynamic>).toList();
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
        DocumentSnapshot snapshot = await _avatarDoc.get();
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          List<Map<String, dynamic>> avatars = 
              data['avatars'] != null ? List<Map<String, dynamic>>.from(data['avatars']) : [];
          if (avatars.isNotEmpty) {
            return avatars.map((avatar) => avatar['id'] as int).reduce((a, b) => a > b ? a : b) + 1;
          }
        }
        return 0;
      }

      // If offline, calculate from local storage
      List<Map<String, dynamic>> localAvatars = await _getAvatarsFromLocal();
      if (localAvatars.isNotEmpty) {
        return localAvatars.map((avatar) => avatar['id'] as int).reduce((a, b) => a > b ? a : b) + 1;
      }
      return 0;
    } catch (e) {
      return 0; // Start with 0 in case of error
    }
  }

  Future<void> addAvatar(Map<String, dynamic> avatar) async {
    try {
      int nextId = await getNextId();
      avatar['id'] = nextId;
      
      // Get current avatars list
      List<Map<String, dynamic>> avatars = await fetchAvatars();
      avatars.add(avatar);
      
      // Save locally first
      await _storeAvatarsLocally(avatars);
      
      // Then update Firebase if online
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _avatarDoc.update({'avatars': avatars});
      }
    } catch (e) {
      // If Firebase update fails, at least we have local storage
    }
  }

  Future<void> updateAvatar(int id, Map<String, dynamic> updatedAvatar) async {
    try {
      // Update locally first
      List<Map<String, dynamic>> avatars = await _getAvatarsFromLocal();
      int index = avatars.indexWhere((avatar) => avatar['id'] == id);
      if (index != -1) {
        avatars[index] = updatedAvatar;
        await _storeAvatarsLocally(avatars);
      }
      
      // Then update Firebase if online
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _avatarDoc.update({'avatars': avatars});
      }
    } catch (e) {
      // If Firebase update fails, at least we have local storage
    }
  }

  Future<void> deleteAvatar(int id) async {
    try {
      // Delete locally first
      List<Map<String, dynamic>> avatars = await _getAvatarsFromLocal();
      avatars.removeWhere((avatar) => avatar['id'] == id);
      await _storeAvatarsLocally(avatars);
      
      // Then update Firebase if online
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _avatarDoc.update({'avatars': avatars});
      }
    } catch (e) {
      // If Firebase update fails, at least we have local storage
    }
  }

  // Add this method to update cache in background
  Future<void> _updateCacheIfOnline() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot snapshot = await _avatarDoc.get();
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          List<Map<String, dynamic>> avatars = 
              data['avatars'] != null ? List<Map<String, dynamic>>.from(data['avatars']) : [];
          await _storeAvatarsLocally(avatars);
        }
      }
    } catch (e) {
      // Silently handle error since this is a background update
    }
  }
}