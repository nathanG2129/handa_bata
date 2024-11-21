import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:handabatamae/services/avatar_service.dart';
import 'package:handabatamae/services/user_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/game_save_data.dart'; // Add this import
import '../services/stage_service.dart'; // Add this import
import '../services/banner_service.dart'; // Add this import
import '../services/badge_service.dart'; // Add this import
// For BuildContext and VoidCallback

/// Represents a single entry in the offline changes queue
class QueueEntry {
  final String categoryId;
  final Map<String, dynamic> gameData;
  final DateTime timestamp;
  
  const QueueEntry({
    required this.categoryId,
    required this.gameData,
    required this.timestamp,
  });
  
  Map<String, dynamic> toMap() => {
    'categoryId': categoryId,
    'gameData': gameData,
    'timestamp': timestamp.toIso8601String(),
  };
  
  factory QueueEntry.fromMap(Map<String, dynamic> map) => QueueEntry(
    categoryId: map['categoryId'],
    gameData: Map<String, dynamic>.from(map['gameData']),
    timestamp: DateTime.parse(map['timestamp']),
  );

  @override
  String toString() => 'QueueEntry(categoryId: $categoryId, timestamp: $timestamp)';
}

/// Constants for game save error messages
class GameSaveError {
  static const String SAVE_FAILED = 'Failed to save game data';
  static const String LOAD_FAILED = 'Failed to load game data';
  static const String CREATE_FAILED = 'Failed to create initial game data';
  static const String BACKUP_FAILED = 'Failed to backup game data';
  static const String RESTORE_FAILED = 'Failed to restore game data';
}

/// Constants for game state keys
class GameStateKeys {
  static const String SAVE_PREFIX = 'game_progress_';
  static const String BACKUP_PREFIX = 'game_progress_backup_';
}

/// Constants for offline queue management
class OfflineQueueKeys {
  static const String QUEUE_KEY = 'offline_game_save_queue';
  static const String LAST_SYNC_KEY = 'last_sync_timestamp';
  static const String QUEUE_BACKUP_KEY = 'offline_queue_backup';
}

/// Constants for sync status
class SyncStatus {
  static const String PENDING = 'pending';
  static const String SUCCESS = 'success';
  static const String FAILED = 'failed';
}

/// Constants for sync retry settings
class SyncRetryConfig {
  static const int MAX_RETRIES = 3;
  static const int BASE_DELAY_SECONDS = 2;
  static const int MAX_QUEUE_SIZE = 100;
}

/// Service for handling authentication and user profile management.
/// Supports both regular users and guest accounts with offline capabilities.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StageService _stageService = StageService(); // Initialize StageService
  final BannerService _bannerService = BannerService(); // Initialize BannerService
  final BadgeService _badgeService = BadgeService(); // Add this line
  final String defaultLanguage;

  static const String USER_PROFILE_KEY = 'user_profile';
  static const String GUEST_PROFILE_KEY = 'guest_profile';
  static const String GUEST_UID_KEY = 'guest_uid';

  static const int MAX_CACHE_SIZE = 100;
  static const String USER_CACHE_VERSION_KEY = 'user_cache_version';

  final List<StreamSubscription> _subscriptions = [];

  final Map<String, UserProfile> _userCache = {};
  int _currentCacheVersion = 0;

  // Add this variable at class level to store current password temporarily
  String? _currentPassword;

  AuthService._internal({this.defaultLanguage = 'en'}) {
    // Set persistence to LOCAL to maintain auth state
    _auth.setPersistence(Persistence.LOCAL);
    
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      print('🔐 Auth state changed: ${user?.uid ?? 'No user'}');
    });
    
    Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);
  }

  void startListening() {
    _listenToFirestoreChanges();
  }

  Future<User?> registerWithEmailAndPassword(String email, String password, String username, String nickname, String birthday, {String role = 'user'}) async {
    try {
      // Check username availability first
      bool isTaken = await isUsernameTaken(username);
      if (isTaken) {
        throw Exception('Username is already taken');
      }

      // Create the user in Firebase Auth first
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      User? user = result.user;

      if (user != null) {
        String finalNickname = nickname.isEmpty ? _generateRandomNickname() : nickname;
        
        // Get the number of banners and badges
        List<Map<String, dynamic>> banners = await _bannerService.fetchBanners();
        List<Map<String, dynamic>> badges = await _badgeService.fetchBadges();
        int bannerCount = banners.length;
        int badgeCount = badges.length;
        
        // Create user profile
        UserProfile userProfile = UserProfile(
          profileId: user.uid,
          username: username,
          nickname: finalNickname,
          avatarId: 0,
          badgeShowcase: [-1, -1, -1],
          bannerId: 0,
          exp: 0,
          expCap: 100,
          hasShownCongrats: false,
          level: 1,
          totalBadgeUnlocked: 0,
          totalStageCleared: 0,
          unlockedBadge: List<int>.filled(badgeCount, 0),
          unlockedBanner: List<int>.filled(bannerCount, 0),
          email: email,
          birthday: birthday,
        );

        // Create user document in Firestore
        await _firestore.collection('User').doc(user.uid).set({
          'email': email,
          'role': role,
        });

        // Create profile data
        await _firestore
            .collection('User')
            .doc(user.uid)
            .collection('ProfileData')
            .doc(user.uid)
            .set(userProfile.toMap());

        // Save profile locally
        await saveUserProfileLocally(userProfile);

        // Initialize game save data for each category
        List<Map<String, dynamic>> categories = await _stageService.fetchCategories(defaultLanguage);
        for (var category in categories) {
          List<Map<String, dynamic>> stages = await _stageService.fetchStages(defaultLanguage, category['id']);
          GameSaveData gameSaveData = await createInitialGameSaveData(stages);
          
          // Save to Firestore
          await _firestore
              .collection('User')
              .doc(user.uid)
              .collection('GameSaveData')
              .doc(category['id'])
              .set(gameSaveData.toMap());
            
          // Save locally
          await saveGameSaveDataLocally(category['id'], gameSaveData);
        }

        return user;
      }
      return null;
    } catch (e) {
      print('Error in registerWithEmailAndPassword: $e');
      rethrow;
    }
  }

  Future<void> createGuestProfile(User user) async {
    // Get the number of banners and badges
    List<Map<String, dynamic>> banners = await _bannerService.fetchBanners();
    List<Map<String, dynamic>> badges = await _badgeService.fetchBadges();
    int bannerCount = banners.length;
    int badgeCount = badges.length;
    
    UserProfile guestProfile = UserProfile(
      profileId: user.uid,
      username: 'Guest',
      nickname: _generateRandomNickname(),
      avatarId: 0,
      badgeShowcase: [-1, -1, -1],
      bannerId: 0,
      exp: 0,
      expCap: 100,
      hasShownCongrats: false,
      level: 1,
      totalBadgeUnlocked: 0,
      totalStageCleared: 0,
      unlockedBadge: List<int>.filled(badgeCount, 0), // Dynamic size based on badge count
      unlockedBanner: List<int>.filled(bannerCount, 0),
      email: '',
      birthday: '',
    );

    // Save profile to Firestore
    await _firestore
        .collection('User')
        .doc(user.uid)
        .collection('ProfileData')
        .doc(user.uid)
        .set(guestProfile.toMap());

    // Add this: Save user document with email and role
    await _firestore.collection('User').doc(user.uid).set({
      'email': 'guest@example.com',
      'role': 'guest',
    });

    // Save profile locally
    await saveUserProfileLocally(guestProfile);

    // Create GameSaveData for guest
    List<Map<String, dynamic>> categories = await _stageService.fetchCategories(defaultLanguage);
    for (Map<String, dynamic> category in categories) {
      List<Map<String, dynamic>> stages = await _stageService.fetchStages(defaultLanguage, category['id']);
      GameSaveData gameSaveData = await createInitialGameSaveData(stages);
      
      // Save locally first
      await saveGameSaveDataLocally(category['id'], gameSaveData);
      
      // Then save to Firebase if online
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _firestore
            .collection('User')
            .doc(user.uid)
            .collection('GameSaveData')
            .doc(category['id'])
            .set(gameSaveData.toMap());
      }
    }
  }

    Future<void> syncProfile(String role) async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        UserProfile? localProfile = role == 'guest' 
            ? await getLocalGuestProfile()
            : await getLocalUserProfile();
        
        if (localProfile != null) {
          await _firestore
              .collection('User')
              .doc(localProfile.profileId)
              .collection('ProfileData')
              .doc(localProfile.profileId)
              .set(localProfile.toMap());
          
          if (role == 'guest') {
            await clearLocalGuestProfile();
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveGuestProfileLocally(UserProfile profile) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String profileJson = jsonEncode(profile.toMap());
    await prefs.setString(GUEST_PROFILE_KEY, profileJson);
  }

  Future<UserProfile?> getLocalGuestProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? profileJson = prefs.getString(GUEST_PROFILE_KEY);
    if (profileJson != null) {
      Map<String, dynamic> profileMap = jsonDecode(profileJson);
      return UserProfile.fromMap(profileMap);
    }
    return null;
  }

  Future<void> clearLocalGuestProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(GUEST_PROFILE_KEY);
  }

  Future<bool> isSignedIn() async {
    User? user = _auth.currentUser;
    return user != null;
  }

  Future<void> saveGuestAccountDetails(String uid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(GUEST_UID_KEY, uid);
  }

  Future<String?> getGuestAccountDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(GUEST_UID_KEY);
  }

  Future<void> clearGuestAccountDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(GUEST_UID_KEY);
  }

  Future<void> updateUserProfile(String field, dynamic value) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        print('🔄 Updating user profile - Field: $field');
        print('📊 Previous value in cache: ${_userCache[user.uid]?.toMap()[field]}');

        // Get current profile first
        UserProfile? currentProfile = await getUserProfile();
        if (currentProfile != null) {
          // Create updated profile preserving all existing values
          Map<String, dynamic> updatedData = currentProfile.toMap();
          updatedData[field] = value;
          
          // For unlocked badges, preserve existing unlocks
          if (field == 'unlockedBadge') {
            List<int> currentUnlocks = currentProfile.unlockedBadge;
            List<int> newUnlocks = value as List<int>;
            
            // Ensure we don't lose unlocks
            for (int i = 0; i < currentUnlocks.length && i < newUnlocks.length; i++) {
              if (currentUnlocks[i] == 1) {
                newUnlocks[i] = 1;
              }
            }
            updatedData[field] = newUnlocks;
          }

          // Create new profile with updated data
          UserProfile updatedProfile = UserProfile.fromMap(updatedData);

          // Update Firestore
          await _firestore
              .collection('User')
              .doc(user.uid)
              .collection('ProfileData')
              .doc(user.uid)
              .update({field: updatedData[field]});

          // Update local storage and cache
          await saveUserProfileLocally(updatedProfile);
          _addToCache(user.uid, updatedProfile);

          print('📊 Updated value in cache: ${_userCache[user.uid]?.toMap()[field]}');
        }
      }
    } catch (e) {
      print('❌ Error updating user profile: $e');
      rethrow;
    }
  }

  Future<User?> signInWithUsernameAndPassword(String username, String password) async {
    try {
      String? email = await getEmailByUsername(username);
      if (email == null) {
        return null;
      }

      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      
      if (user != null) {
        print('🔄 Fetching game save data after login');
        
        // Get categories and fetch game save data for each
        List<Map<String, dynamic>> categories = await _stageService.fetchCategories(defaultLanguage);
        
        for (var category in categories) {
          String categoryId = category['id'];
          print('📥 Fetching game save data for category: $categoryId');
          
          try {
            // Get game save data from Firestore
            DocumentSnapshot saveDoc = await _firestore
                .collection('User')
                .doc(user.uid)
                .collection('GameSaveData')
                .doc(categoryId)
                .get();

            if (saveDoc.exists) {
              // Convert and save locally
              GameSaveData gameSaveData = GameSaveData.fromMap(
                saveDoc.data() as Map<String, dynamic>
              );
              await saveGameSaveDataLocally(categoryId, gameSaveData);
              print('✅ Saved game data for category: $categoryId');
            } else {
              print('⚠️ No existing game data for category: $categoryId');
              // Create initial game save data
              List<Map<String, dynamic>> stages = 
                  await _stageService.fetchStages(defaultLanguage, categoryId);
              GameSaveData initialData = await createInitialGameSaveData(stages);
              await saveGameSaveDataLocally(categoryId, initialData);
              print('✅ Created initial game data for category: $categoryId');
            }
          } catch (e) {
            print('❌ Error fetching game data for $categoryId: $e');
          }
        }
      }

      return user;
    } catch (e) {
      print('❌ Error during sign in: $e');
      return null;
    }
  }

  Future<String?> getEmailByUsername(String username) async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collectionGroup('ProfileData').where('username', isEqualTo: username).get();
      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return querySnapshot.docs.first.get('email');
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      print('\n🚪 SIGNING OUT');
      
      // 1. Clear all local data first
      print('🧹 Clearing local data...');
      await clearAllLocalData();
      
      // 2. Sign out from Firebase Auth
      print('🔑 Signing out from Firebase Auth...');
      await _auth.signOut();
      
      print('✅ Sign out completed successfully\n');
    } catch (e) {
      print('❌ Error during sign out: $e');
      rethrow;
    }
  }

  Future<UserProfile?> getUserProfile() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return UserProfile.guestProfile;

      // Check memory cache first
      if (_userCache.containsKey(user.uid)) {
        return _userCache[user.uid];
      }

      // Then check local storage
      UserProfile? localProfile = await getLocalUserProfile();
      if (localProfile != null) {
        _addToCache(user.uid, localProfile);
        return localProfile;
      }

      // Finally check Firestore if online
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot profileDoc = await _firestore
            .collection('User')
            .doc(user.uid)
            .collection('ProfileData')
            .doc(user.uid)
            .get();
        
        if (profileDoc.exists) {
          UserProfile profile = UserProfile.fromMap(profileDoc.data() as Map<String, dynamic>);
          _addToCache(user.uid, profile);
          await saveUserProfileLocally(profile);
          return profile;
        }
      }
      
      return UserProfile.guestProfile;
    } catch (e) {
      print('Error getting user profile: $e');
      return UserProfile.guestProfile;
    }
  }

  Future<void> deleteUserAccount() async {
    try {
      print('\n🗑️ DELETING USER ACCOUNT');
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user found to delete');
      }

      String? role = await getUserRole(user.uid);
      print('👤 User role: $role');
      
      // For regular users, require reauthentication FIRST before any deletion
      if (role != 'guest') {
        try {
          // Just check if token is fresh
          await user.reload();
        } catch (e) {
          // Always require reauthentication for account deletion
          throw Exception('Please reauthenticate to delete your account');
        }
      }

      // Now proceed with deletion in correct order
      print('🗑️ Deleting Firestore data...');
      await _deleteFirestoreData(user.uid);
      print('✅ Firestore data deleted');

      print('🗑️ Clearing local data...');
      await clearAllLocalData();
      print('✅ Local data cleared');

      print('🗑️ Deleting Firebase Auth user...');
      await user.delete();
      print('✅ Firebase Auth user deleted');

      print('🚪 Signing out...');
      await signOut();
      print('✅ User signed out');

      print('✅ Account deletion completed successfully\n');
    } catch (e) {
      print('❌ Error deleting user account: $e');
      rethrow;
    }
  }

  // Helper method to handle Firestore deletion
  Future<void> _deleteFirestoreData(String uid) async {
    try {
      print('🗑️ Starting Firestore data deletion');
      
      // Define all subcollections to delete
      List<String> subcollections = [
        'ProfileData', 
        'GameSaveData',
        'GameProgress',
      ];
      
      WriteBatch batch = _firestore.batch();
      
      // Delete all documents in each subcollection
      for (String subcollection in subcollections) {
        print('🗑️ Deleting $subcollection collection');
        QuerySnapshot subcollectionDocs = 
          await _firestore.collection('User').doc(uid).collection(subcollection).get();
        
        for (var doc in subcollectionDocs.docs) {
          batch.delete(doc.reference);
        }
      }
      
      // Delete the main user document
      batch.delete(_firestore.collection('User').doc(uid));
      
      // Commit the batch
      await _executeBatchWithRetry(batch);
      
      print('✅ All Firestore data deleted successfully');
    } catch (e) {
      print('❌ Error deleting Firestore data: $e');
      rethrow;
    }
  }

  Future<String?> getUserRole(String uid) async {
    DocumentSnapshot userDoc = await _firestore.collection('User').doc(uid).get();
    if (userDoc.exists) {
      return userDoc.get('role');
    }
    return null;
  }

    void _listenToFirestoreChanges() {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      _subscriptions.add(
        _firestore
            .collection('User')
            .doc(currentUser.uid)
            .collection('ProfileData')
            .doc(currentUser.uid)
            .snapshots()
            .listen(
          (docSnapshot) async {
            if (!docSnapshot.exists) return;

            // Get local profile first
            UserProfile? localProfile = await getLocalUserProfile();
            if (localProfile == null) {
              UserProfile userProfile = UserProfile.fromMap(docSnapshot.data() as Map<String, dynamic>);
              await saveUserProfileLocally(userProfile);
              return;
            }

            // Calculate total XP for both profiles
            UserProfile serverProfile = UserProfile.fromMap(docSnapshot.data() as Map<String, dynamic>);
            int localTotalXP = ((localProfile.level - 1) * 100) + localProfile.exp;
            int serverTotalXP = ((serverProfile.level - 1) * 100) + serverProfile.exp;

            // Only update if server has higher XP
            if (serverTotalXP > localTotalXP) {
              await saveUserProfileLocally(serverProfile);
            }
          },
          onError: (e) => print('Error in profile listener: $e'),
        ),
      );

      // GameSaveData listener
      _subscriptions.add(
        _firestore
            .collection('User')
            .doc(currentUser.uid)
            .collection('GameSaveData')
            .snapshots()
            .listen(
          (QuerySnapshot snapshot) async {
            var connectivityResult = await Connectivity().checkConnectivity();
            if (connectivityResult != ConnectivityResult.none) {
              for (var change in snapshot.docChanges) {
                if (change.type == DocumentChangeType.modified) {
                  String categoryId = change.doc.id;
                  GameSaveData gameSaveData = GameSaveData.fromMap(
                    change.doc.data() as Map<String, dynamic>
                  );
                  await saveGameSaveDataLocally(categoryId, gameSaveData);
                }
              }
            }
          },
          onError: (error) {
          },
        ),
      );
    } catch (e) {
      print('Error in _listenToFirestoreChanges: $e');
    }
  }

    Future<void> saveUserProfileLocally(UserProfile profile) async {
    try {
      if (!_validateUserProfile(profile)) {
        throw Exception('Invalid user profile data');
      }
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String profileJson = jsonEncode(profile.toMap());
      await prefs.setString(USER_PROFILE_KEY, profileJson);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAvatarId(int avatarId) async {
    try {
      User? user = _auth.currentUser;
      
      if (user != null) {
        // Validate avatar exists
        final avatarService = AvatarService();
        List<Map<String, dynamic>> availableAvatars = 
            await avatarService.fetchAvatars();
        bool avatarExists = availableAvatars.any((a) => a['id'] == avatarId);
        
        if (!avatarExists) {
          throw Exception('Selected avatar no longer exists');
        }

        // Get current profile
        UserProfile? currentProfile = await getLocalUserProfile();
        currentProfile ??= await getUserProfile();
        
        if (currentProfile == null) {
          throw Exception('User profile not found');
        }

        // Clear old avatar from cache
        avatarService.clearAvatarCache(currentProfile.avatarId);
        
        // Update locally
        Map<String, dynamic> profileMap = currentProfile.toMap();
        profileMap['avatarId'] = avatarId;
        UserProfile updatedProfile = UserProfile.fromMap(profileMap);
        
        // Validate updated profile
        if (!_validateUserProfile(updatedProfile)) {
          throw Exception('Invalid profile data after avatar update');
        }

        await saveUserProfileLocally(updatedProfile);

        // Update Firebase if online
        var connectivityResult = await (Connectivity().checkConnectivity());
        if (connectivityResult != ConnectivityResult.none) {
          await _firestore
              .collection('User')
              .doc(user.uid)
              .collection('ProfileData')
              .doc(user.uid)
              .update({
                'avatarId': avatarId,
                'lastUpdated': FieldValue.serverTimestamp(),
              });
        }
      }
    } catch (e) {
      print('Error updating avatar ID: $e');
      rethrow;
    }
  }

  // Add method to handle avatar deletion fallback
  Future<void> handleDeletedAvatar(int oldAvatarId) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await updateAvatarId(0); // Reset to default avatar
        
        // Notify user if online
        var connectivityResult = await (Connectivity().checkConnectivity());
        if (connectivityResult != ConnectivityResult.none) {
          // Here you would implement your notification system
          print('Avatar $oldAvatarId was deleted by admin. Reset to default avatar.');
        }
      }
    } catch (e) {
      print('Error handling deleted avatar: $e');
    }
  }

  Future<void> clearLocalUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(USER_PROFILE_KEY);
  }

  Future<bool> hasLocalUserProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(USER_PROFILE_KEY);
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasLocalGuestProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(GUEST_PROFILE_KEY);
    } catch (e) {
      return false;
    }
  }

  Future<UserProfile?> getLocalUserProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? profileJson = prefs.getString(USER_PROFILE_KEY);
      if (profileJson != null) {
        Map<String, dynamic> profileMap = jsonDecode(profileJson);
        return UserProfile.fromMap(profileMap);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearAllLocalData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Get all keys from SharedPreferences
      Set<String> allKeys = prefs.getKeys();
      
      // Create a list of keys to remove
      List<String> keysToRemove = [
        USER_PROFILE_KEY,
        GUEST_PROFILE_KEY,
        GUEST_UID_KEY,
      ];

      // Add game progress keys
      keysToRemove.addAll(
        allKeys.where((key) => key.startsWith('game_progress_'))
      );

      // Add game save data keys
      keysToRemove.addAll(
        allKeys.where((key) => key.startsWith('game_save_data_'))
      );

      // Add pending sync keys
      keysToRemove.addAll(
        allKeys.where((key) => key.startsWith('pending_'))
      );

      // Remove all keys in parallel
      await Future.wait(
        keysToRemove.map((key) => prefs.remove(key))
      );

      print('🧹 Cleared all local data including game saves');
    } catch (e) {
      print('❌ Error clearing local data: $e');
      rethrow;
    }
  }

  bool _validateUserProfile(UserProfile profile) {
    return profile.profileId.isNotEmpty &&
        profile.username.isNotEmpty &&
        profile.nickname.isNotEmpty &&
        profile.level > 0 &&
        profile.expCap > 0;
  }

  /// Converts a guest account to a regular user account while preserving all data.
  /// Returns the updated User object or null if conversion fails.
  Future<User?> convertGuestToUser(String email, String password, String username, String nickname, String birthday) async {
    try {
      print('\n🔄 CONVERTING GUEST TO USER');
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      // Check username availability first
      bool isTaken = await isUsernameTaken(username);
      if (isTaken) {
        throw Exception('Username is already taken');
      }

      // Get current guest profile
      UserProfile? guestProfile = await getLocalUserProfile();
      if (guestProfile == null) {
        throw Exception('No guest profile found');
      }

      print('👤 Current profile:');
      print('Username: ${guestProfile.username}');
      print('Nickname: ${guestProfile.nickname}');

      // Create updated profile with new user data but keep existing nickname
      UserProfile updatedProfile = guestProfile.copyWith(
        username: username,  // Set new username
        email: email,       // Set email
        birthday: birthday, // Set birthday
        // Keep existing nickname instead of overwriting
        nickname: guestProfile.nickname // Keep the nickname user has set
      );

      print('👤 Updated profile:');
      print('Username: ${updatedProfile.username}');
      print('Nickname: ${updatedProfile.nickname}');

      // Store conversion data
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_conversion', jsonEncode({
        'email': email,
        'password': password,
        'username': username,
        'nickname': updatedProfile.nickname, // Store existing nickname
        'birthday': birthday,
        'guestProfile': updatedProfile.toMap(),
      }));

      print('✅ Guest conversion prepared\n');
      return currentUser;
    } catch (e) {
      print('❌ Error preparing guest conversion: $e');
      rethrow;
    }
  }

  // Add new method to complete the conversion after OTP verification
  Future<User?> completeGuestConversion() async {
    try {
      print('\n🔄 COMPLETING GUEST CONVERSION');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? pendingConversionData = prefs.getString('pending_conversion');
      if (pendingConversionData == null) {
        throw Exception('No pending conversion found');
      }

      Map<String, dynamic> conversionData = jsonDecode(pendingConversionData);
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No current user found');
      }

      print('👤 Converting guest to regular user...');
      
      // Link email/password to anonymous account
      AuthCredential credential = EmailAuthProvider.credential(
        email: conversionData['email'],
        password: conversionData['password'],
      );

      print('🔗 Linking email credential...');
      await currentUser.linkWithCredential(credential);
      
      // Get the updated profile data
      Map<String, dynamic> profileData = conversionData['guestProfile'];
      UserProfile updatedProfile = UserProfile.fromMap(profileData);

      print('💾 Updating Firestore documents...');
      
      // Update in a batch to ensure atomicity
      WriteBatch batch = _firestore.batch();
      
      // Update main user document
      DocumentReference userDoc = _firestore.collection('User').doc(currentUser.uid);
      batch.set(userDoc, {
        'email': conversionData['email'],
        'role': 'user',
      });

      // Update profile data
      DocumentReference profileDoc = userDoc
          .collection('ProfileData')
          .doc(currentUser.uid);
      batch.set(profileDoc, updatedProfile.toMap());

      // Commit the batch
      await batch.commit();

      // Update profile using UserProfileService
      final userProfileService = UserProfileService();
      await userProfileService.batchUpdateProfile({
        'username': conversionData['username'],
        'email': conversionData['email'],
        'birthday': conversionData['birthday'],
        // Keep existing nickname from the guest profile
        'nickname': conversionData['nickname'],
      });

      // Update local storage
      await saveUserProfileLocally(updatedProfile);
      _addToCache(currentUser.uid, updatedProfile);

      // Clear pending conversion data
      await prefs.remove('pending_conversion');

      print('✅ Guest conversion completed successfully\n');
      return currentUser;
    } catch (e) {
      print('❌ Error completing guest conversion: $e');
      rethrow;
    }
  }

  /// Tracks the sync status for each category
  Future<void> updateSyncStatus(String categoryId, String status) async {
    try {
      print('📝 Updating sync status for $categoryId: $status');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('sync_status_$categoryId', status);
      await prefs.setString(
        OfflineQueueKeys.LAST_SYNC_KEY, 
        DateTime.now().toIso8601String()
      );
      
      print('✅ Sync status updated successfully');
    } catch (e) {
      print('❌ Error updating sync status: $e');
    }
  }

  /// Modified save method with queue integration
  Future<void> saveGameSaveDataLocally(String categoryId, GameSaveData data) async {
    try {
      print('💾 Starting save process for category: $categoryId');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Create backup of current data
      print('📦 Creating backup...');
      String? existingData = prefs.getString('game_save_data_$categoryId');
      if (existingData != null) {
        await prefs.setString('game_save_data_backup_$categoryId', existingData);
        print('✅ Backup created successfully');
      }

      // Save new data locally
      print('💾 Saving new data...');
      String saveDataJson = jsonEncode(data.toMap());
      await prefs.setString('game_save_data_$categoryId', saveDataJson);
      
      // Queue for sync and update status
      print('🔄 Queueing for sync...');
      await queueOfflineChange(categoryId, data);
      await updateSyncStatus(categoryId, SyncStatus.PENDING);
      
      // Clear backup after successful save
      if (existingData != null) {
        await prefs.remove('game_save_data_backup_$categoryId');
        print('🧹 Backup cleared after successful save');
      }
      
      print('✅ Save process completed successfully');
      
      // Try to sync immediately if online
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        print('🌐 Online connection available, attempting immediate sync...');
        try {
          await syncCategoryData(categoryId);
          await updateSyncStatus(categoryId, SyncStatus.SUCCESS);
          await removeFromQueue(categoryId);
          print('✅ Immediate sync successful');
        } catch (syncError) {
          print('⚠️ Immediate sync failed, will retry later: $syncError');
          // Keep in queue for later sync
        }
      } else {
        print('📱 Offline - changes queued for later sync');
      }
      
    } catch (e) {
      print('❌ Error in save process: $e');
      print('Stack trace: ${StackTrace.current}');
      
      // Attempt to restore from backup
      await _restoreGameSaveBackup(categoryId);
      await updateSyncStatus(categoryId, SyncStatus.FAILED);
      
      throw GameSaveDataException('${GameSaveError.SAVE_FAILED}: $e');
    }
  }

  /// Get sync status for a category with detailed information
  Future<Map<String, dynamic>> getSyncStatus(String categoryId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String status = prefs.getString('sync_status_$categoryId') ?? SyncStatus.SUCCESS;
      
      // Get queue information
      List<QueueEntry> queue = await getOfflineQueue();
      DateTime? lastSync = await getLastSyncTime();
      
      // Get pending changes for this category
      int pendingChanges = queue.where((entry) => entry.categoryId == categoryId).length;
      
      return {
        'status': status,
        'pendingChanges': pendingChanges,
        'lastSyncTime': lastSync?.toIso8601String(),
        'hasFailedSync': status == SyncStatus.FAILED,
        'isInQueue': queue.any((entry) => entry.categoryId == categoryId),
      };
    } catch (e) {
      print('❌ Error getting sync status: $e');
      return {
        'status': SyncStatus.FAILED,
        'pendingChanges': 0,
        'lastSyncTime': null,
        'hasFailedSync': true,
        'isInQueue': false,
      };
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? timestamp = prefs.getString(OfflineQueueKeys.LAST_SYNC_KEY);
      return timestamp != null ? DateTime.parse(timestamp) : null;
    } catch (e) {
      print('❌ Error getting last sync time: $e');
      return null;
    }
  }

  Future<GameSaveData?> getLocalGameSaveData(String categoryId) async {
    try {
      print('🔍 Getting game data for category: $categoryId');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? saveDataJson = prefs.getString('game_save_data_$categoryId');
      
      if (saveDataJson != null) {
        Map<String, dynamic> saveDataMap = jsonDecode(saveDataJson);
        final data = GameSaveData.fromMap(saveDataMap);
        print('✅ Game data loaded successfully');
        return data;
      }
      print('ℹ️ No game data found for category: $categoryId');
      return null;
    } catch (e) {
      print('❌ Error loading game data: $e');
      final backup = await _restoreGameSaveBackup(categoryId);
      if (backup != null) {
        print('🔄 Restored from backup successfully');
        return backup;
      }
      throw GameSaveDataException('${GameSaveError.LOAD_FAILED}: $e');
    }
  }

  Future<void> _executeBatchWithRetry(WriteBatch batch, {int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        await batch.commit();
        return;
      } catch (e) {
        attempts++;
        if (attempts == maxRetries) rethrow;
        await Future.delayed(Duration(seconds: 1 * attempts));
      }
    }
  }

  Future<GameSaveData> createInitialGameSaveData(List<Map<String, dynamic>> stages) async {
    try {
      print('🎮 Creating initial game data');
      Map<String, StageDataEntry> stageData = {};

      // Group stages by category and type
      Map<String, List<Map<String, dynamic>>> adventureStages = {};
      Map<String, Map<String, dynamic>> arcadeStages = {};

      for (var stage in stages) {
        // Debug print the stage data
        print('📝 Processing stage data: ${stage.toString()}');

        String stageName = stage['stageName'] ?? '';
        if (stageName.isEmpty) {
          print('⚠️ Warning: Stage found with missing stageName');
          continue;
        }

        // Get category from the parent collection in StageService
        String categoryId = stage['id'] ?? stage['categoryId'] ?? _extractCategoryFromStageName(stageName);
        if (categoryId.isEmpty) {
          print('⚠️ Warning: Could not determine category for stage: $stageName');
          continue;
        }

        // Add category to stage data
        Map<String, dynamic> stageWithCategory = {
          ...stage,
          'categoryId': categoryId,
        };

        bool isArcade = stageName.toLowerCase().contains('arcade');
        print('🎯 Processing ${isArcade ? 'Arcade' : 'Adventure'} stage: $stageName for category: $categoryId');

        if (isArcade) {
          arcadeStages[categoryId] = stageWithCategory;
        } else {
          adventureStages.putIfAbsent(categoryId, () => []).add(stageWithCategory);
        }
      }

      // Print summary of collected stages
      adventureStages.forEach((category, stages) {
        print('📊 Category $category: ${stages.length} adventure stages');
      });
      arcadeStages.forEach((category, _) {
        print(' Category $category: 1 arcade stage');
      });

      // Process arcade stages
      for (var entry in arcadeStages.entries) {
        String categoryId = entry.key;
        var arcadeStage = entry.value;
        String arcadeKey = GameSaveData.getArcadeKey(categoryId);
        
        print('🎮 Creating arcade stage for $arcadeKey');
        stageData[arcadeKey] = ArcadeStageData(
          maxScore: _calculateMaxScore(arcadeStage),
        );
      }

      // Process adventure stages
      for (var entry in adventureStages.entries) {
        String categoryId = entry.key;
        var categoryStages = entry.value;

        // Sort stages by number
        categoryStages.sort((a, b) => _getStageNumber(a['stageName'])
            .compareTo(_getStageNumber(b['stageName'])));

        print('🎮 Creating ${categoryStages.length} adventure stages for $categoryId');
        
        for (var stage in categoryStages) {
          int stageNumber = _getStageNumber(stage['stageName']);
          String stageKey = GameSaveData.getStageKey(categoryId, stageNumber);
          
          print('📝 Creating stage data for $stageKey');
          stageData[stageKey] = AdventureStageData(
            maxScore: _calculateMaxScore(stage),
          );
        }
      }

      // Calculate total stages including arcade
      int totalStages = adventureStages.values
          .fold(0, (sum, stages) => sum + stages.length)
          + 1; 

      // Calculate total adventure stages (without arcade)
      int totalAdventureStages = adventureStages.values
          .fold(0, (sum, stages) => sum + stages.length);

      print('📊 Creating save data with $totalStages stages');
      
      return GameSaveData(
        stageData: stageData,
        normalStageStars: List<int>.filled(totalAdventureStages, 0),
        hardStageStars: List<int>.filled(totalAdventureStages, 0),
        unlockedNormalStages: List.generate(totalStages, (i) => i == 0),
        unlockedHardStages: List<bool>.filled(totalStages, false),
        hasSeenPrerequisite: List<bool>.filled(totalStages, false),
      );
    } catch (e) {
      print('❌ Error creating initial game data: $e');
      print('Stack trace: ${StackTrace.current}');
      throw GameSaveDataException('${GameSaveError.CREATE_FAILED}: $e');
    }
  }

  int _calculateMaxScore(Map<String, dynamic> stage) {
    if (stage['questions'] == null) return 0;
    
    return (stage['questions'] as List).fold(0, (sum, question) {
      switch (question['type']) {
        case 'Multiple Choice': return sum + 1;
        case 'Fill in the Blanks': return sum + (question['answer'] as List).length;
        case 'Identification': return sum + 1;
        case 'Matching Type': return sum + (question['answerPairs'] as List).length;
        default: return sum;
      }
    });
  }

  int _getStageNumber(String stageName) {
    final match = RegExp(r'\d+').firstMatch(stageName);
    return match != null ? int.parse(match.group(0)!) : 1;
  }

  Future<GameSaveData?> _restoreGameSaveBackup(String categoryId) async {
    try {
      print('🔄 Attempting to restore from backup for category: $categoryId');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? backupJson = prefs.getString('game_save_data_backup_$categoryId');
      if (backupJson != null) {
        return GameSaveData.fromMap(jsonDecode(backupJson));
      }
      return null;
    } catch (e) {
      print('❌ Error restoring from backup: $e');
      throw GameSaveDataException('${GameSaveError.RESTORE_FAILED}: $e');
    }
  }

  Future<void> dispose() async {
    for (var subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  /// Synchronizes local profile and game save data with Firestore when online.
  /// Handles both user and guest profiles.
  Future<void> syncProfiles() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) return;

    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      // Only sync profile data, not game saves
      UserProfile? localProfile = await getLocalUserProfile();
      if (localProfile != null) {
        await _firestore
            .collection('User')
            .doc(currentUser.uid)
            .collection('ProfileData')
            .doc(currentUser.uid)
            .set(localProfile.toMap());
      }
    }
  }

  /// Updates game progress including score, stars, and unlocks next stage if applicable
  Future<void> updateGameProgress({
    required String categoryId,
    required String stageName,
    required int score,
    required int stars,
    required String mode,
    int? record,
    required bool isArcade,
  }) async {
    try {
      print('🎮 Updating game progress for ${isArcade ? 'arcade' : 'adventure'} mode');
      
      // Get current game save data
      GameSaveData? localData = await getLocalGameSaveData(categoryId);
      if (localData == null) {
        print('📝 Creating new game save data');
        localData = GameSaveData.initial(7); // 7 stages per quest
      }

      // Get the appropriate stage key
      String stageKey = isArcade 
          ? GameSaveData.getArcadeKey(categoryId)
          : GameSaveData.getStageKey(categoryId, _getStageNumber(stageName));

      // Update based on game mode
      if (isArcade) {
        if (record == null) {
          throw GameSaveDataException('Record is required for arcade mode');
        }
        print('🎯 Updating arcade record: $record');
        localData.updateArcadeRecord(stageKey, record);
      } else {
        // Update adventure mode progress
        print('🎯 Updating adventure progress:');
        print('Score: $score, Stars: $stars, Mode: $mode');
        
        int stageIndex = _getStageNumber(stageName) - 1;
        localData.updateScore(stageKey, score, mode);
        localData.updateStars(stageIndex, stars, mode);
        
        // Unlock next stage if applicable
        if (stars > 0) {
          print('🔓 Unlocking next stage');
          localData.unlockStage(stageIndex + 1, mode);
        }
      }

      // Save updated data
      await saveGameSaveDataLocally(categoryId, localData);
      
      print('✅ Game progress updated successfully');
    } catch (e) {
      print('❌ Error updating game progress: $e');
      throw GameSaveDataException('Failed to update game progress: $e');
    }
  }

  String _generateRandomNickname() {
    final random = Random();
    final number = random.nextInt(90000) + 10000; // Generates number between 10000-99999
    return 'player$number';
  }

  /// Checks if a username is already taken
  Future<bool> isUsernameTaken(String username) async {
    try {
      print('🔍 Checking if username "$username" is taken');
      QuerySnapshot querySnapshot = await _firestore
          .collectionGroup('ProfileData')
          .where('username', isEqualTo: username)
          .get();
      
      bool isTaken = querySnapshot.docs.isNotEmpty;
      print(isTaken ? '❌ Username is taken' : '✅ Username is available');
      return isTaken;
    } catch (e) {
      print('❌ Error checking username availability: $e');
      rethrow;
    }
  }

  Future<void> updateBannerId(int bannerId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Update local profile first
      UserProfile? currentProfile = await getLocalUserProfile();
      currentProfile ??= await getUserProfile();
      
      // Update locally
      Map<String, dynamic> profileMap = currentProfile!.toMap();
      profileMap['bannerId'] = bannerId;
      UserProfile updatedProfile = UserProfile.fromMap(profileMap);
      await saveUserProfileLocally(updatedProfile);

      // Update Firebase if online
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _firestore
            .collection('User')
            .doc(currentUser.uid)
            .collection('ProfileData')
            .doc(currentUser.uid)
            .update({'bannerId': bannerId});
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _initializeCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentCacheVersion = prefs.getInt(USER_CACHE_VERSION_KEY) ?? 0;
  }

  void _addToCache(String userId, UserProfile profile) {
    // Remove oldest entries if cache is full
    if (_userCache.length >= MAX_CACHE_SIZE) {
      final keysToRemove = _userCache.keys.take(_userCache.length - MAX_CACHE_SIZE + 1);
      for (var key in keysToRemove) {
        _userCache.remove(key);
      }
    }
    _userCache[userId] = profile;
  }

  Future<void> clearCache() async {
    _userCache.clear();
    _currentCacheVersion++;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(USER_CACHE_VERSION_KEY, _currentCacheVersion);
  }

  Future<void> _verifyUserDataIntegrity() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) return;

      // Get local and server profiles
      UserProfile? localProfile = await getLocalUserProfile();
      DocumentSnapshot serverDoc = await _firestore
          .collection('User')
          .doc(currentUser.uid)
          .collection('ProfileData')
          .doc(currentUser.uid)
          .get();

      if (!serverDoc.exists || localProfile == null) return;

      Map<String, dynamic> serverData = serverDoc.data() as Map<String, dynamic>;
      UserProfile serverProfile = UserProfile.fromMap(serverData);

      // Check for data inconsistencies
      bool needsRepair = false;
      
      // Compare critical fields
      if (localProfile.level != serverProfile.level ||
          localProfile.exp != serverProfile.exp ||
          !listEquals(localProfile.unlockedBadge, serverProfile.unlockedBadge) ||
          !listEquals(localProfile.unlockedBanner, serverProfile.unlockedBanner)) {
        needsRepair = true;
      }

      if (needsRepair) {
        // Use server data as source of truth
        await saveUserProfileLocally(serverProfile);
        _addToCache(currentUser.uid, serverProfile);
      }
    } catch (e) {
      print('Error during data integrity check: $e');
    }
  }

  Future<void> batchUpdateUserProfiles(List<UserProfile> profiles) async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('No internet connection');
      }

      WriteBatch batch = _firestore.batch();
      
      for (var profile in profiles) {
        // Update Firestore
        DocumentReference docRef = _firestore
            .collection('User')
            .doc(profile.profileId)
            .collection('ProfileData')
            .doc(profile.profileId);
          
        batch.set(docRef, profile.toMap());
        
        // Update cache
        _addToCache(profile.profileId, profile);
        
        // Update local storage
        await saveUserProfileLocally(profile);
      }

      // Commit batch
      await _executeBatchWithRetry(batch);
    } catch (e) {
      print('Error in batch update: $e');
      rethrow;
    }
  }

  Future<UserProfile> createOfflineGuestProfile() async {
    // Generate temporary local ID
    final tempId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
    
    // Get the number of banners and badges from local cache
    final banners = await _bannerService.getLocalBanners();
    final badges = await _badgeService.getLocalBadges();
    
    // Create guest profile
    final guestProfile = UserProfile(
      profileId: tempId,
      username: 'Guest',
      nickname: _generateRandomNickname(),
      avatarId: 0,
      badgeShowcase: [-1, -1, -1],
      bannerId: 0,
      exp: 0,
      expCap: 100,
      hasShownCongrats: false,
      level: 1,
      totalBadgeUnlocked: 0,
      totalStageCleared: 0,
      unlockedBadge: List<int>.filled(badges.length, 0),
      unlockedBanner: List<int>.filled(banners.length, 0),
      email: '',
      birthday: '',
    );

    // Save locally
    await saveGuestProfileLocally(guestProfile);
    
    // Queue for sync when online
    await _queueForSync(tempId);
    
    return guestProfile;
  }

  Future<void> _queueForSync(String tempId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> pendingSync = prefs.getStringList('pending_guest_sync') ?? [];
    pendingSync.add(tempId);
    await prefs.setStringList('pending_guest_sync', pendingSync);
  }

  Future<void> syncOfflineGuests() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) return;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> pendingSync = prefs.getStringList('pending_guest_sync') ?? [];
      
      for (String tempId in pendingSync) {
        // Create Firebase anonymous auth
        UserCredential userCredential = await _auth.signInAnonymously();
        User? user = userCredential.user;
        
        if (user != null) {
          // Get the offline profile using the tempId
          UserProfile? offlineProfile = await _getProfileByTempId(tempId);
          if (offlineProfile != null) {
            // Create new profile with Firebase UID but keep all other data
            UserProfile newProfile = offlineProfile.copyWith(
              profileId: user.uid,
            );
            
            // Save to Firestore
            await _firestore
                .collection('User')
                .doc(user.uid)
                .collection('ProfileData')
                .doc(user.uid)
                .set(newProfile.toMap());
            
            // Save user document
            await _firestore.collection('User').doc(user.uid).set({
              'email': 'guest@example.com',
              'role': 'guest',
            });
            
            // Update local storage with new profile
            await saveGuestProfileLocally(newProfile);
          }
        }
      }
      
      // Clear pending sync
      await prefs.setStringList('pending_guest_sync', []);
    } catch (e) {
      print('Error syncing offline guests: $e');
    }
  }

  // Add helper method to get profile by tempId
  Future<UserProfile?> _getProfileByTempId(String tempId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? profileJson = prefs.getString('${GUEST_PROFILE_KEY}_$tempId');
      if (profileJson != null) {
        Map<String, dynamic> profileMap = jsonDecode(profileJson);
        return UserProfile.fromMap(profileMap);
      }
    } catch (e) {
      print('Error getting profile by tempId: $e');
    }
    return null;
  }

  Future<void> resolveProfileConflicts(String tempId, String firebaseUid) async {
    try {
      // Get both profiles
      UserProfile? offlineProfile = await _getProfileByTempId(tempId);
      DocumentSnapshot onlineDoc = await _firestore
          .collection('User')
          .doc(firebaseUid)
          .collection('ProfileData')
          .doc(firebaseUid)
          .get();

      if (offlineProfile == null) return;

      // Merge profiles, preferring higher values
      UserProfile mergedProfile = UserProfile(
        profileId: firebaseUid,
        username: offlineProfile.username,
        nickname: offlineProfile.nickname,
        avatarId: offlineProfile.avatarId,
        badgeShowcase: offlineProfile.badgeShowcase,
        bannerId: offlineProfile.bannerId,
        exp: onlineDoc.exists ? 
            max((onlineDoc.data() as Map<String, dynamic>)['exp'] ?? 0, offlineProfile.exp) : 
            offlineProfile.exp,
        expCap: offlineProfile.expCap,
        hasShownCongrats: offlineProfile.hasShownCongrats,
        level: onlineDoc.exists ? 
            max((onlineDoc.data() as Map<String, dynamic>)['level'] ?? 1, offlineProfile.level) : 
            offlineProfile.level,
        totalBadgeUnlocked: onlineDoc.exists ? 
            max((onlineDoc.data() as Map<String, dynamic>)['totalBadgeUnlocked'] ?? 0, offlineProfile.totalBadgeUnlocked) : 
            offlineProfile.totalBadgeUnlocked,
        totalStageCleared: onlineDoc.exists ? 
            max((onlineDoc.data() as Map<String, dynamic>)['totalStageCleared'] ?? 0, offlineProfile.totalStageCleared) : 
            offlineProfile.totalStageCleared,
        unlockedBadge: _mergeUnlockArrays(
          offlineProfile.unlockedBadge,
          onlineDoc.exists ? List<int>.from((onlineDoc.data() as Map<String, dynamic>)['unlockedBadge'] ?? []) : []
        ),
        unlockedBanner: _mergeUnlockArrays(
          offlineProfile.unlockedBanner,
          onlineDoc.exists ? List<int>.from((onlineDoc.data() as Map<String, dynamic>)['unlockedBanner'] ?? []) : []
        ),
        email: 'guest@example.com',
        birthday: offlineProfile.birthday,
      );

      // Save merged profile
      await _firestore
          .collection('User')
          .doc(firebaseUid)
          .collection('ProfileData')
          .doc(firebaseUid)
          .set(mergedProfile.toMap());

      await saveUserProfileLocally(mergedProfile);
    } catch (e) {
      print('Error resolving profile conflicts: $e');
      // Keep offline data as backup
      await _backupOfflineData(tempId);
    }
  }

  List<int> _mergeUnlockArrays(List<int> offline, List<int> online) {
    if (offline.isEmpty) return online;
    if (online.isEmpty) return offline;
    return List<int>.generate(
      max(offline.length, online.length),
      (i) => i < offline.length && i < online.length ? 
          (offline[i] | online[i]) : // Bitwise OR to keep unlocks from both
          (i < offline.length ? offline[i] : online[i])
    );
  }

  Future<void> _backupOfflineData(String tempId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String backupKey = 'backup_${tempId}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Backup profile
      String? profileJson = prefs.getString('${GUEST_PROFILE_KEY}_$tempId');
      if (profileJson != null) {
        await prefs.setString(backupKey, profileJson);
      }

      // Backup game progress
      Map<String, dynamic> gameProgress = await _getAllGameProgress(tempId);
      if (gameProgress.isNotEmpty) {
        await prefs.setString('${backupKey}_progress', jsonEncode(gameProgress));
      }

      print('Backup created with key: $backupKey');
    } catch (e) {
      print('Error creating backup: $e');
    }
  }

  Future<bool> _restoreProfileBackup(String backupKey) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? backup = prefs.getString(backupKey);
      if (backup != null) {
        await prefs.setString(USER_PROFILE_KEY, backup);
        return true;
      }
      return false;
    } catch (e) {
      print('Error restoring profile backup: $e');
      return false;
    }
  }

  Future<void> retryFailedSync(String tempId) async {
    int attempts = 0;
    const maxAttempts = 3;
    const baseDelay = Duration(seconds: 2);

    while (attempts < maxAttempts) {
      try {
        // Create backup before attempting sync
        await _backupOfflineData(tempId);
        
        // Attempt sync
        await syncOfflineGuests();
        return;
      } catch (e) {
        attempts++;
        print('Sync attempt $attempts failed: $e');
        
        if (attempts == maxAttempts) {
          // Final attempt failed, restore from backup
          final backupKey = 'backup_${tempId}_${DateTime.now().millisecondsSinceEpoch}';
          await _restoreProfileBackup(backupKey);
          rethrow;
        }
        
        // Exponential backoff
        await Future.delayed(baseDelay * pow(2, attempts));
      }
    }
  }

  Future<Map<String, dynamic>> _getAllGameProgress(String tempId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> allProgress = {};
      
      // Get all keys related to game progress
      final progressKeys = prefs.getKeys()
          .where((key) => key.startsWith('game_progress_'));
      
      for (String key in progressKeys) {
        String? progressJson = prefs.getString(key);
        if (progressJson != null) {
          allProgress[key] = jsonDecode(progressJson);
        }
      }
      
      return allProgress;
    } catch (e) {
      print('Error getting all game progress: $e');
      return {};
    }
  }

  Future<void> _restoreGameProgress(Map<String, dynamic> progress) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      for (var entry in progress.entries) {
        await prefs.setString(entry.key, jsonEncode(entry.value));
      }
    } catch (e) {
      print('Error restoring game progress: $e');
    }
  }

  // Add helper method to extract category from stage name
  String _extractCategoryFromStageName(String stageName) {
    // Map of special cases and their correct category IDs
    const Map<String, String> specialCases = {
      'Volcanic': 'Volcanic',
      // Add any other special cases here if needed
    };

    // Check special cases first
    for (var prefix in specialCases.keys) {
      if (stageName.startsWith(prefix)) {
        return specialCases[prefix]!;
      }
    }
    
    // For regular cases, extract everything before the first number or "Arcade"
    RegExp exp = RegExp(r'^([A-Za-z]+)(?:\d+|Arcade)');
    var match = exp.firstMatch(stageName);
    return match?.group(1) ?? '';
  }

  /// Syncs game save data for a specific category
  Future<void> syncCategoryData(String categoryId) async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) return;

      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get local data for this category
      GameSaveData? localData = await getLocalGameSaveData(categoryId);
      
      if (localData != null) {
        // Sync only this category's data to Firestore
        await _firestore
          .collection('User')
          .doc(currentUser.uid)
          .collection('GameSaveData')
          .doc(categoryId)
          .set(localData.toMap());
          
        print('✅ Synced game data for category: $categoryId');
      }
    } catch (e) {
      print('❌ Error syncing category data: $e');
      throw GameSaveDataException('Failed to sync category data: $e');
    }
  }

  // Method to add changes to queue
  Future<void> queueOfflineChange(String categoryId, GameSaveData data) async {
    try {
      print('🔄 Queueing offline change for category: $categoryId');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Get existing queue
      List<QueueEntry> queue = await getOfflineQueue();
      print('📊 Current queue size: ${queue.length}');
      
      // Create new entry
      QueueEntry newEntry = QueueEntry(
        categoryId: categoryId,
        gameData: data.toMap(),
        timestamp: DateTime.now(),
      );
      
      // Add to queue (replace if exists)
      queue.removeWhere((entry) => entry.categoryId == categoryId);
      queue.add(newEntry);
      print('➕ Added new entry for $categoryId at ${newEntry.timestamp}');
      
      // Save updated queue
      await prefs.setString(
        OfflineQueueKeys.QUEUE_KEY,
        jsonEncode(queue.map((e) => e.toMap()).toList())
      );
      print('💾 Queue saved successfully');
    } catch (e) {
      print('❌ Error queueing offline change: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Method to get queue entries
  Future<List<QueueEntry>> getOfflineQueue() async {
    try {
      print('🔍 Retrieving offline queue');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Get queue string
      String? queueJson = prefs.getString(OfflineQueueKeys.QUEUE_KEY);
      if (queueJson == null) {
        print('ℹ️ No queue found, returning empty list');
        return [];
      }
      
      // Parse queue
      List<dynamic> queueList = jsonDecode(queueJson);
      List<QueueEntry> queue = queueList
          .map((entry) => QueueEntry.fromMap(entry))
          .toList();
      
      print('📊 Retrieved queue with ${queue.length} entries');
      queue.forEach((entry) => 
          print('📝 Queue entry: ${entry.toString()}'));
      
      return queue;
    } catch (e) {
      print('❌ Error getting offline queue: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Method to remove entry from queue
  Future<void> removeFromQueue(String categoryId) async {
    try {
      print('🗑️ Removing category from queue: $categoryId');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Get and update queue
      List<QueueEntry> queue = await getOfflineQueue();
      int sizeBefore = queue.length;
      queue.removeWhere((entry) => entry.categoryId == categoryId);
      print('📊 Queue size changed from $sizeBefore to ${queue.length}');
      
      // Save updated queue
      await prefs.setString(
        OfflineQueueKeys.QUEUE_KEY,
        jsonEncode(queue.map((e) => e.toMap()).toList())
      );
      print('✅ Successfully removed $categoryId from queue');
    } catch (e) {
      print('❌ Error removing from queue: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Method to backup queue before processing
  Future<void> backupQueue() async {
    try {
      print('📦 Creating queue backup');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Get current queue
      String? currentQueue = prefs.getString(OfflineQueueKeys.QUEUE_KEY);
      if (currentQueue == null) {
        print('ℹ️ No queue to backup');
        return;
      }
      
      // Save backup
      await prefs.setString(OfflineQueueKeys.QUEUE_BACKUP_KEY, currentQueue);
      print('✅ Queue backup created successfully');
    } catch (e) {
      print('❌ Error backing up queue: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Method to restore queue from backup
  Future<bool> restoreQueueFromBackup() async {
    try {
      print('🔄 Attempting to restore queue from backup');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Get backup
      String? backupQueue = prefs.getString(OfflineQueueKeys.QUEUE_BACKUP_KEY);
      if (backupQueue == null) {
        print('⚠️ No backup found to restore');
        return false;
      }
      
      // Restore from backup
      await prefs.setString(OfflineQueueKeys.QUEUE_KEY, backupQueue);
      print('✅ Queue restored successfully from backup');
      return true;
    } catch (e) {
      print('❌ Error restoring queue: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Main method to process the offline sync queue
  Future<void> processOfflineQueue({bool forceSync = false}) async {
    try {
      print('🔄 Starting offline queue processing');
      
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        print('📡 No network connection available');
        return;
      }

      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('👤 No user logged in');
        return;
      }

      // Backup queue before processing
      await backupQueue();
      print('📦 Queue backup created');

      // Get and sort queue by timestamp
      List<QueueEntry> queue = await getOfflineQueue();
      queue.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      print('📊 Processing ${queue.length} queue entries');
      
      // Track sync progress
      int successCount = 0;
      int failureCount = 0;
      DateTime syncStartTime = DateTime.now();

      // Process each entry
      for (var entry in queue) {
        try {
          print('🔄 Processing entry for category: ${entry.categoryId}');
          
          // Attempt sync with retry
          bool syncSuccess = await _syncEntryWithRetry(
            currentUser.uid, 
            entry,
            maxRetries: SyncRetryConfig.MAX_RETRIES
          );

          if (syncSuccess) {
            successCount++;
            await removeFromQueue(entry.categoryId);
            await updateSyncStatus(entry.categoryId, SyncStatus.SUCCESS);
          } else {
            failureCount++;
            await updateSyncStatus(entry.categoryId, SyncStatus.FAILED);
          }
        } catch (e) {
          print('❌ Error processing entry: $e');
          failureCount++;
        }
      }

      // Log sync completion
      Duration syncDuration = DateTime.now().difference(syncStartTime);
      print('✅ Sync completed in ${syncDuration.inSeconds}s');
      print('📊 Success: $successCount, Failures: $failureCount');

    } catch (e) {
      print('❌ Error processing offline queue: $e');
      print('Stack trace: ${StackTrace.current}');
      await restoreQueueFromBackup();
      rethrow;
    }
  }

  /// Sync a single queue entry with retry logic
 Future<bool> _syncEntryWithRetry(
  String userId, 
  QueueEntry entry, 
  {int maxRetries = SyncRetryConfig.MAX_RETRIES}
) async {
  int attempts = 0;
  
  while (attempts < maxRetries) {
    try {
      print('🔄 Sync attempt ${attempts + 1} for ${entry.categoryId}');
      
      // This code will never be reached in this test
      await _firestore
          .collection('User')
          .doc(userId)
          .collection('GameSaveData')
          .doc(entry.categoryId)
          .set(entry.gameData);
      
      print('✅ Sync successful for ${entry.categoryId}');
      return true;
    } catch (e) {
      attempts++;
      print('❌ Sync attempt $attempts failed: $e');
      
      if (attempts == maxRetries) {
        print('⚠️ Max retry attempts reached for ${entry.categoryId}');
        return false;
      }
      
      int delaySeconds = SyncRetryConfig.BASE_DELAY_SECONDS * pow(2, attempts).toInt();
      print('⏳ Waiting ${delaySeconds}s before next attempt');
      await Future.delayed(Duration(seconds: delaySeconds));
    }
  }
  
  return false;
}

  /// Update NetworkStateHandler to use new sync process
  void _handleConnectivityChange(ConnectivityResult result) async {
    if (result != ConnectivityResult.none) {
      print('🌐 Network connection restored');
      await processOfflineQueue();
    }
  }

  /// Add method for manual sync trigger
  Future<void> triggerManualSync() async {
    print('🔄 Manual sync triggered');
    await processOfflineQueue(forceSync: true);
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      print('\n🔐 CHANGING PASSWORD');
      User? user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user found or user has no email');
      }

      // Create credentials with current password
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      // Reauthenticate
      print('🔄 Reauthenticating user');
      await user.reauthenticateWithCredential(credential);

      // Change password
      print('🔄 Updating password');
      await user.updatePassword(newPassword);
      
      print('✅ Password changed successfully\n');
    } catch (e) {
      print('❌ Error changing password: $e');
      rethrow;
    }
  }

  Future<void> changeEmail(String newEmail, String currentPassword) async {
    try {
      print('\n🔄 CHANGING EMAIL');
      User? user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user found or user has no email');
      }

      // Store the password for later use
      _currentPassword = currentPassword;

      // Create credentials with current password
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      // Reauthenticate
      print('🔄 Reauthenticating user');
      await user.reauthenticateWithCredential(credential);

      // Send OTP to new email
      print('📧 Sending verification code to new email');
      final functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
      await functions
          .httpsCallable('sendEmailChangeOTP')
          .call({'email': newEmail});

      print('✅ Verification code sent successfully\n');
    } catch (e) {
      print('❌ Error initiating email change: $e');
      rethrow;
    }
  }

  Future<void> verifyAndUpdateEmail(String newEmail, String otp) async {
    try {
      print('\n🔄 VERIFYING AND UPDATING EMAIL');
      User? user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user found or user has no email');
      }

      if (_currentPassword == null) {
        throw Exception('Authentication required');
      }

      // Verify OTP
      print('🔍 Verifying OTP');
      print('📤 Sending verification request with:');
      print('   Email: $newEmail');
      print('   OTP: $otp');
      
      final functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
      final result = await functions
          .httpsCallable('verifyEmailChangeOTP')
          .call({
            'email': newEmail,
            'otp': otp
          });

      print('📥 Received verification result: ${result.data}');

      if (result.data['success']) {
        // Reauthenticate again before updating email
        print('🔄 Reauthenticating user');
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPassword!,
        );
        await user.reauthenticateWithCredential(credential);

        // First verify the new email
        print('📧 Verifying new email');
        await user.updateEmail(newEmail);

        // Update email in main User document
        print('💾 Updating email in User document');
        await _firestore
            .collection('User')
            .doc(user.uid)
            .update({'email': newEmail});

        // Update email in ProfileData document
        print('💾 Updating email in ProfileData');
        await _firestore
            .collection('User')
            .doc(user.uid)
            .collection('ProfileData')
            .doc(user.uid)
            .update({'email': newEmail});

        // Initialize and update local profile
        final userProfileService = UserProfileService();
        await userProfileService.batchUpdateProfile({
          'email': newEmail
        });

        // Clear stored password
        _currentPassword = null;

        print('✅ Email updated successfully in all locations\n');
      } else {
        throw Exception('Verification failed');
      }
    } catch (e) {
      // Clear stored password on error
      _currentPassword = null;
      print('❌ Error updating email: $e');
      rethrow;
    }
  }

  // Add these new methods to your AuthService class

  Future<void> sendPasswordResetOTP(String email) async {
    try {
      print('\n📧 SENDING PASSWORD RESET OTP');
      final functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
      
      print('📤 Sending OTP to email: $email');
      await functions
          .httpsCallable('sendPasswordResetOTP')
          .call({'email': email});
      
      print('✅ Password reset OTP sent successfully\n');
    } catch (e) {
      print('❌ Error sending password reset OTP: $e');
      rethrow;
    }
  }

  Future<void> verifyAndResetPassword(String email, String otp, String newPassword) async {
    try {
      print('\n🔄 VERIFYING AND RESETTING PASSWORD');
      final functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
      
      // First verify the OTP
      print('🔍 Verifying OTP');
      final result = await functions
          .httpsCallable('verifyPasswordResetOTP')
          .call({
            'email': email,
            'otp': otp
          });

      if (result.data['success']) {
        // If OTP is valid, reset the password
        print('🔐 Resetting password');
        await _auth.sendPasswordResetEmail(email: email);
        print('✅ Password reset email sent successfully\n');
      } else {
        throw Exception('Invalid verification code');
      }
    } catch (e) {
      print('❌ Error resetting password: $e');
      rethrow;
    }
  }

  // Update these methods in AuthService

  Future<void> verifyPasswordResetOTP(String email, String otp) async {
    try {
      print('\n🔍 VERIFYING PASSWORD RESET OTP');
      final functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
      
      final result = await functions
          .httpsCallable('verifyPasswordResetOTP')
          .call({
            'email': email,
            'otp': otp
          });

      if (!result.data['success']) {
        throw Exception('Invalid verification code');
      }
      
      print('✅ OTP verified successfully\n');
    } catch (e) {
      print('❌ Error verifying OTP: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email, String newPassword) async {
    try {
      print('\n🔐 RESETTING PASSWORD');
      
      // Get user by email
      var methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isEmpty) {
        throw Exception('No account found with this email');
      }

      try {
        // Get custom token for temporary auth
        final functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
        print('🔑 Getting custom token for temporary auth');
        final result = await functions
            .httpsCallable('createCustomToken')
            .call({'email': email});
        
        if (result.data == null || result.data['token'] == null) {
          throw Exception('Failed to get authentication token');
        }

        // Sign in with custom token
        print('🔄 Signing in temporarily');
        await _auth.signInWithCustomToken(result.data['token']);
        
        // Update password
        if (_auth.currentUser != null) {
          print('🔐 Updating password');
          await _auth.currentUser!.updatePassword(newPassword);
          
          // Sign out after password update
          print('🚪 Signing out');
          await _auth.signOut();
          
          print('✅ Password updated successfully\n');
        } else {
          throw Exception('Failed to authenticate for password reset');
        }
      } catch (e) {
        print('❌ Error during password reset: $e');
        rethrow;
      }
    } catch (e) {
      print('❌ Error resetting password: $e');
      rethrow;
    }
  }
}

class SyncManager {
  static final Map<String, bool> _syncInProgress = {};
  static final Map<String, DateTime> _lastSyncAttempt = {};
  static const Duration _minSyncInterval = Duration(minutes: 5);
  static final AuthService _authService = AuthService();

  static Future<void> handleSync(String tempId, Future<void> Function() syncOperation) async {
    // Check if sync is already in progress
    if (_syncInProgress[tempId] == true) {
      print('Sync already in progress for $tempId');
      return;
    }

    // Check if we're respecting the minimum sync interval
    final lastAttempt = _lastSyncAttempt[tempId];
    if (lastAttempt != null && 
        DateTime.now().difference(lastAttempt) < _minSyncInterval) {
      print('Too soon to retry sync for $tempId');
      return;
    }

    try {
      _syncInProgress[tempId] = true;
      _lastSyncAttempt[tempId] = DateTime.now();

      // Create backup using AuthService instance
      await _authService._backupOfflineData(tempId);

      // Perform sync
      await syncOperation();

      _syncInProgress[tempId] = false;
    } catch (e) {
      _syncInProgress[tempId] = false;
      print('Error during sync: $e');
      
      // Attempt recovery using AuthService instance
      await _authService.retryFailedSync(tempId);
    }
  }
}

class NetworkStateHandler {
  static final AuthService _authService = AuthService();
  
  static Future<void> _handleConnectivityChange(ConnectivityResult result) async {
    if (result != ConnectivityResult.none) {
      print('🌐 Network connection restored');
      await _authService.processOfflineQueue();
    }
  }

  static void dispose() {
    // No need to dispose anything in this implementation
  }
}
