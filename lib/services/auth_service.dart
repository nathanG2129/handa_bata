import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:handabatamae/services/avatar_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/game_save_data.dart'; // Add this import
import '../services/stage_service.dart'; // Add this import
import '../services/banner_service.dart'; // Add this import
import '../services/badge_service.dart'; // Add this import
import 'package:flutter/material.dart';  // For BuildContext and VoidCallback

/// Service for handling authentication and user profile management.
/// Supports both regular users and guest accounts with offline capabilities.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StageService _stageService = StageService(); // Initialize StageService
  final BannerService _bannerService = BannerService(); // Initialize BannerService
  final BadgeService _badgeService = BadgeService(); // Add this line
  final String defaultLanguage;

  static const String USER_PROFILE_KEY = 'user_profile';
  static const String GUEST_PROFILE_KEY = 'guest_profile';
  static const String GUEST_UID_KEY = 'guest_uid';

  List<StreamSubscription> _subscriptions = [];

  AuthService({this.defaultLanguage = 'en'}) {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        syncProfiles();
      }
    });
    _listenToFirestoreChanges();
  }

  Future<User?> registerWithEmailAndPassword(String email, String password, String username, String nickname, String birthday, {String role = 'user'}) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      if (user != null) {
        String finalNickname = nickname.isEmpty ? _generateRandomNickname() : nickname;
        
        // Get the number of banners and badges
        List<Map<String, dynamic>> banners = await _bannerService.fetchBanners();
        List<Map<String, dynamic>> badges = await _badgeService.fetchBadges();
        int bannerCount = banners.length;
        int badgeCount = badges.length;
        
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
          unlockedBadge: List<int>.filled(badgeCount, 0), // Dynamic size based on badge count
          unlockedBanner: List<int>.filled(bannerCount, 0),
          email: email,
          birthday: birthday,
        );

        await _firestore.collection('User').doc(user.uid).collection('ProfileData').doc(user.uid).set(userProfile.toMap());

        // Fetch categories and create gameSaveData documents
        List<Map<String, dynamic>> categories = await _stageService.fetchCategories(defaultLanguage); // Assuming 'en' as the language
        CollectionReference gameSaveDataRef = _firestore.collection('User').doc(user.uid).collection('GameSaveData');
        for (Map<String, dynamic> category in categories) {
          // Fetch stages for the category
          List<Map<String, dynamic>> stages = await _stageService.fetchStages(defaultLanguage, category['id']);
          int stageCount = stages.length;
          
          // Initialize arrays with default values
          List<bool> unlockedNormalStages = List<bool>.filled(stageCount, false, growable: true);
          List<bool> unlockedHardStages = List<bool>.filled(stageCount, false, growable: true);
          List<bool> hasSeenPrerequisite = List<bool>.filled(stageCount, false, growable: true);
          List<int> normalStageStars = List<int>.filled(stageCount, 0, growable: true);
          List<int> hardStageStars = List<int>.filled(stageCount, 0, growable: true);
          
          // Unlock the first stage by default
          if (stageCount > 0) {
            unlockedNormalStages[0] = true;
            unlockedHardStages[0] = true;
          }
          
          // Create stageData map
          Map<String, Map<String, dynamic>> stageData = {};
          for (var stage in stages) {
            String stageName = stage['stageName'];
            if (stageName.contains('Arcade')) {
              stageData[stageName] = {
                'bestRecord': -1,
                'crntRecord': -1,
              };
            } else {
              int maxScore = (stage['questions'] as List).fold(0, (sum, question) {
                if (question['type'] == 'Multiple Choice') {
                  return sum + 1;
                } else if (question['type'] == 'Fill in the Blanks') {
                  return sum + (question['answer'] as List).length;
                } else if (question['type'] == 'Identification') {
                  return sum + 1;
                } else if (question['type'] == 'Matching Type') {
                  return sum + (question['answerPairs'] as List).length;
                } else {
                  return sum;
                }
              });
              stageData[stageName] = {
                'maxScore': maxScore,
                'scoreHard': 0,
                'scoreNormal': 0,
              };
            }
          }
          
          // Create gameSaveData document
          GameSaveData gameSaveData = GameSaveData(
            stageData: stageData,
            normalStageStars: normalStageStars,
            hardStageStars: hardStageStars,
            unlockedNormalStages: unlockedNormalStages,
            unlockedHardStages: unlockedHardStages,
            hasSeenPrerequisite: hasSeenPrerequisite,
          );
          
          // Remove arcade stages from stars related fields
          for (var stage in stages) {
            String stageName = stage['stageName'];
            if (stageName.contains('Arcade')) {
              int index = stages.indexOf(stage);
              normalStageStars.removeAt(index);
              hardStageStars.removeAt(index);
              unlockedHardStages.removeAt(index);
            }
          }
          
          await gameSaveDataRef.doc(category['id']).set(gameSaveData.toMap());
        }

        await _firestore.collection('User').doc(user.uid).set({
          'email': email,
          'role': role,
        });

        // Save user profile locally
        await saveUserProfileLocally(userProfile);
      }

      return user;
    } catch (e) {
      return null;
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
      GameSaveData gameSaveData = await _createInitialGameSaveData(stages);
      
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
        // If updating level, check for banner unlocks
        if (field == 'level') {
          UserProfile? currentProfile = await getUserProfile();
          if (currentProfile != null && value > currentProfile.level) {
            // Level increased, update unlockedBanner array if needed
            List<int> unlockedBanners = currentProfile.unlockedBanner;
            if (value <= unlockedBanners.length && unlockedBanners[value - 1] != 1) {
              unlockedBanners[value - 1] = 1;
              await _firestore
                  .collection('User')
                  .doc(user.uid)
                  .collection('ProfileData')
                  .doc(user.uid)
                  .update({'unlockedBanner': unlockedBanners});
            }
          }
        }

        // Update the specified field
        await _firestore
            .collection('User')
            .doc(user.uid)
            .collection('ProfileData')
            .doc(user.uid)
            .update({field: value});

        // Update local cache if needed
        UserProfile? profile = await getUserProfile();
        if (profile != null) {
          profile = profile.copyWith(updates: {field: value});
          await saveUserProfileLocally(profile);
        }
      }
    } catch (e) {
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
      return result.user;
    } catch (e) {
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
      await _auth.signOut();
      await clearAllLocalData(); // Clear all local data, not just guest details
    } catch (e) {
      rethrow;
    }
  }

  Future<UserProfile?> getUserProfile() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return UserProfile.guestProfile;
      }

      // Always check local storage first
      UserProfile? localProfile = await getLocalUserProfile();
      if (localProfile != null) {
        return localProfile;
      }

      // Only if no local profile, get from Firebase
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot profileDoc = await _firestore
            .collection('User')
            .doc(user.uid)
            .collection('ProfileData')
            .doc(user.uid)
            .get();
        
        if (!profileDoc.exists) {
          return UserProfile.guestProfile;
        }

        Map<String, dynamic> data = profileDoc.data() as Map<String, dynamic>;
        UserProfile profile = UserProfile.fromMap(data);
        
        // Save to local storage
        await saveUserProfileLocally(profile);
        
        return profile;
      }
      
      return UserProfile.guestProfile;
    } catch (e) {
      return UserProfile.guestProfile;
    }
  }

  Future<void> deleteUserAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        String? role = await getUserRole(user.uid);
        
        // Delete from Firestore regardless of role
        await _deleteFirestoreData(user.uid);

        // For guest accounts, we need to delete the anonymous auth user
        if (role == 'guest') {
          await user.delete();  // Delete the anonymous auth user
        } else {
          // For regular users, reauthenticate if needed and then delete
          await user.delete();
        }

        // Clear all local data
        await clearAllLocalData();
      }
    } catch (e) {
      print('❌ Error deleting user account: $e');
      rethrow;
    }
  }

  // Helper method to handle Firestore deletion
  Future<void> _deleteFirestoreData(String uid) async {
    try {
      // Define all subcollections to delete
      List<String> subcollections = [
        'ProfileData', 
        'GameSaveData',
        'GameProgress', // Add GameProgress to the list
      ];
      
      WriteBatch batch = _firestore.batch();
      
      // Delete all documents in each subcollection
      for (String subcollection in subcollections) {
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
      
      print('🗑️ Deleted all user data including GameProgress collection');
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

            // Check if we have local changes pending sync
            bool hasLocalChanges = await hasLocalUserProfile();
            if (hasLocalChanges) {
              // Don't overwrite local changes
              return;
            }

            var connectivityResult = await (Connectivity().checkConnectivity());
            if (connectivityResult != ConnectivityResult.none) {
              UserProfile userProfile = UserProfile.fromMap(docSnapshot.data() as Map<String, dynamic>);
              await saveUserProfileLocally(userProfile);
            }
          },
          onError: (error) {
          },
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
            var connectivityResult = await (Connectivity().checkConnectivity());
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
    }
  }

  Future<void> _syncFirestoreToLocal(DocumentSnapshot doc) async {
    String userId = doc.id;
    DocumentSnapshot userProfileDoc = await _firestore.collection('User').doc(userId).collection('ProfileData').doc(userId).get();
    if (userProfileDoc.exists) {
      UserProfile userProfile = UserProfile.fromMap(userProfileDoc.data() as Map<String, dynamic>);
      await saveUserProfileLocally(userProfile);
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
      List<String> keysToRemove = [
        USER_PROFILE_KEY,
        GUEST_PROFILE_KEY,
        GUEST_UID_KEY,
      ];
      
      // Add GameSaveData keys
      List<Map<String, dynamic>> categories = await _stageService.fetchCategories(defaultLanguage);
      for (var category in categories) {
        keysToRemove.add('game_save_data_${category['id']}');
      }
      
      await Future.wait(
        keysToRemove.map((key) => prefs.remove(key))
      );
    } catch (e) {
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
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      // Get current guest profile and game save data
      UserProfile? guestProfile = await getLocalUserProfile();
      if (guestProfile == null) return null;

      // Use the provided nickname or generate one if not provided
      String finalNickname = nickname.isEmpty ? _generateRandomNickname() : nickname;

      // Store conversion data for later use after OTP verification
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_conversion', jsonEncode({
        'email': email,
        'password': password,
        'username': username,
        'nickname': finalNickname,
        'birthday': birthday,
        'guestProfile': guestProfile.toMap(),
      }));

      return currentUser;
    } catch (e) {
      rethrow;
    }
  }

  // Add new method to complete the conversion after OTP verification
  Future<User?> completeGuestConversion() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? pendingConversionData = prefs.getString('pending_conversion');
      if (pendingConversionData == null) return null;

      Map<String, dynamic> conversionData = jsonDecode(pendingConversionData);
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      // Get the guest profile data which includes the nickname
      Map<String, dynamic> guestProfileData = conversionData['guestProfile'];
      UserProfile guestProfile = UserProfile.fromMap(guestProfileData);

      // Create email/password credentials and link account
      AuthCredential credential = EmailAuthProvider.credential(
        email: conversionData['email'],
        password: conversionData['password'],
      );
      await currentUser.linkWithCredential(credential);

      // Update profile data, keeping the original nickname
      UserProfile updatedProfile = UserProfile(
        profileId: currentUser.uid,
        username: conversionData['username'],
        nickname: guestProfile.nickname,  // Keep the original nickname
        avatarId: guestProfile.avatarId,
        badgeShowcase: guestProfile.badgeShowcase,
        bannerId: guestProfile.bannerId,
        exp: guestProfile.exp,
        expCap: guestProfile.expCap,
        hasShownCongrats: guestProfile.hasShownCongrats,
        level: guestProfile.level,
        totalBadgeUnlocked: guestProfile.totalBadgeUnlocked,
        totalStageCleared: guestProfile.totalStageCleared,
        unlockedBadge: guestProfile.unlockedBadge,
        unlockedBanner: guestProfile.unlockedBanner,
        email: conversionData['email'],
        birthday: conversionData['birthday'],
      );

      // Update Firestore if online
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        WriteBatch batch = _firestore.batch();
        
        batch.set(_firestore.collection('User').doc(currentUser.uid), {
          'email': conversionData['email'],
          'role': 'user'
        });

        batch.set(
          _firestore
              .collection('User')
              .doc(currentUser.uid)
              .collection('ProfileData')
              .doc(currentUser.uid),
          updatedProfile.toMap()
        );

        await _executeBatchWithRetry(batch);
      }

      // Save updated profile locally
      await saveUserProfileLocally(updatedProfile);
      
      // Clear pending conversion data
      await prefs.remove('pending_conversion');

      return currentUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveGameSaveDataLocally(String categoryId, GameSaveData data) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String saveDataJson = jsonEncode(data.toMap());
      await prefs.setString('game_save_data_$categoryId', saveDataJson);
    } catch (e) {
      rethrow;
    }
  }

  Future<GameSaveData?> getLocalGameSaveData(String categoryId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? saveDataJson = prefs.getString('game_save_data_$categoryId');
      if (saveDataJson != null) {
        Map<String, dynamic> saveDataMap = jsonDecode(saveDataJson);
        return GameSaveData.fromMap(saveDataMap);
      }
      return null;
    } catch (e) {
      return null;
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

  Future<GameSaveData> _createInitialGameSaveData(List<Map<String, dynamic>> stages) async {
    int stageCount = stages.length;
    
    // Initialize arrays with default values
    List<bool> unlockedNormalStages = List<bool>.filled(stageCount, false, growable: true);
    List<bool> unlockedHardStages = List<bool>.filled(stageCount, false, growable: true);
    List<bool> hasSeenPrerequisite = List<bool>.filled(stageCount, false, growable: true);
    List<int> normalStageStars = List<int>.filled(stageCount, 0, growable: true);
    List<int> hardStageStars = List<int>.filled(stageCount, 0, growable: true);
    
    // Unlock the first stage by default
    if (stageCount > 0) {
      unlockedNormalStages[0] = true;
      unlockedHardStages[0] = true;
    }
    
    // Create stageData map
  Map<String, Map<String, dynamic>> stageData = {};
  for (var stage in stages) {
    String stageName = stage['stageName'];
    if (stageName.contains('Arcade')) {
      stageData[stageName] = {
        'bestRecord': -1,
        'crntRecord': -1,
      };
    } else {
      //Calculate maxScore
      int maxScore = (stage['questions'] as List).fold(0, (sum, question) {
        if (question['type'] == 'Multiple Choice') {
          return sum + 1;
        } else if (question['type'] == 'Fill in the Blanks') {
          return sum + (question['answer'] as List).length;
        } else if (question['type'] == 'Identification') {
          return sum + 1;
        } else if (question['type'] == 'Matching Type') {
          return sum + (question['answerPairs'] as List).length;
        } else {
          return sum;
        }
      });
      stageData[stageName] = {
        'maxScore': maxScore,
        'scoreHard': 0,
        'scoreNormal': 0,
      };
    }
  }
    
    return GameSaveData(
      stageData: stageData,
      normalStageStars: normalStageStars,
      hardStageStars: hardStageStars,
      unlockedNormalStages: unlockedNormalStages,
      unlockedHardStages: unlockedHardStages,
      hasSeenPrerequisite: hasSeenPrerequisite,
    );
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
    if (connectivityResult != ConnectivityResult.none) {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        String? role = await getUserRole(currentUser.uid);
        
        // Sync profile data
        if (role == 'guest') {
          await syncProfile('guest');
        } else {
          await syncProfile('user');
        }

        // Sync GameSaveData
        // First get local data for each category
        List<Map<String, dynamic>> categories = await _stageService.fetchCategories(defaultLanguage);
        for (var category in categories) {
          String categoryId = category['id'];
          GameSaveData? localData = await getLocalGameSaveData(categoryId);
          
          if (localData != null) {
            // If we have local data, sync it to Firestore
            await _firestore
                .collection('User')
                .doc(currentUser.uid)
                .collection('GameSaveData')
                .doc(categoryId)
                .set(localData.toMap());
          } else {
            // If no local data, get from Firestore and save locally
            DocumentSnapshot firestoreData = await _firestore
                .collection('User')
                .doc(currentUser.uid)
                .collection('GameSaveData')
                .doc(categoryId)
                .get();

            if (firestoreData.exists) {
              GameSaveData gameSaveData = GameSaveData.fromMap(
                firestoreData.data() as Map<String, dynamic>
              );
              await saveGameSaveDataLocally(categoryId, gameSaveData);
            }
          }
        }
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
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      GameSaveData? localData = await getLocalGameSaveData(categoryId);
      if (localData == null) return;

      // Update local data
      if (isArcade && record != null) {
        // For arcade mode, find the correct stage key
        String arcadeStageKey = localData.stageData.keys
            .firstWhere((key) => key.contains('Arcade'), 
            orElse: () => stageName);
        
        // Get current records
        int currentBestRecord = localData.stageData[arcadeStageKey]?['bestRecord'];
        int currentRecord = localData.stageData[arcadeStageKey]?['crntRecord'];
        
        // Update records only if:
        // 1. Current record is -1 (no record yet)
        // 2. New record is lower than current record (better time)

        //Update personal best record
        if (currentBestRecord == -1 || record < currentBestRecord) {
          localData.stageData[arcadeStageKey]?['bestRecord'] = record;
        }

        //Update current season record
        if (currentRecord == -1 || record < currentRecord) {
          localData.stageData[arcadeStageKey]?['crntRecord'] = record;
        }

      } else {
        // For normal mode, find the correct stage key
        String stageKey = localData.stageData.keys
            .firstWhere((key) => key.endsWith(stageName.split(' ').last),
            orElse: () => stageName);
        
        // Update score
        String scoreKey = mode == 'normal' ? 'scoreNormal' : 'scoreHard';
        if (localData.stageData[stageKey] != null) {
          localData.stageData[stageKey]![scoreKey] = score;
        }
        
        // Update stars
        List<int> stageStars = mode == 'normal' 
            ? localData.normalStageStars 
            : localData.hardStageStars;
        
        // Extract stage number from stageName (e.g., "Stage 1" -> 1)
        int stageNumber = int.parse(stageName.replaceAll(RegExp(r'[^0-9]'), ''));
        int stageIndex = stageNumber - 1;
        
        if (stageIndex >= 0 && stageIndex < stageStars.length) {
          if (stars > stageStars[stageIndex]) {
            stageStars[stageIndex] = stars;
          }
        }
      }

      // Save locally
      await saveGameSaveDataLocally(categoryId, localData);

      // Sync with Firestore if online
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _firestore
            .collection('User')
            .doc(currentUser.uid)
            .collection('GameSaveData')
            .doc(categoryId)
            .set(localData.toMap());
      }
    } catch (e) {
      rethrow;
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
      QuerySnapshot querySnapshot = await _firestore
          .collectionGroup('ProfileData')
          .where('username', isEqualTo: username)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
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

  /// Saves the current game state both locally and to Firebase when online
  Future<void> saveGameState({
    required String userId,
    required String categoryId,
    required String stageName,
    required String mode,
    required String gamemode,
    required Map<String, dynamic> gameState,
  }) async {
    // Skip saving for arcade mode
    if (gamemode == 'arcade') return;

    try {
      // Create document ID in consistent format
      final docId = '${categoryId}_${stageName}_${mode.toLowerCase()}';
      
      // First save locally
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String gameStateJson = jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        ...gameState
      });
      await prefs.setString('game_progress_$docId', gameStateJson);

      // Then save to Firebase if online
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await FirebaseFirestore.instance
            .collection('User')
            .doc(userId)
            .collection('GameProgress')
            .doc(docId)
            .set({
          'timestamp': DateTime.now(),
          ...gameState
        });
      }
    } catch (e) {
      print('❌ Error saving game state: $e');
      rethrow;
    }
  }

  /// Handles game quit including saving state and cleanup
  Future<void> handleGameQuit({
    required String userId,
    required String categoryId,
    required String stageName,
    required String mode,
    required String gamemode,
    required Map<String, dynamic> gameState,
    required VoidCallback onCleanup,
    required Function(BuildContext) navigateBack,
    required BuildContext context,
  }) async {
    print('🎮 Starting handleGameQuit in AuthService');

    try {
      // Only save state for non-arcade modes
      if (gamemode != 'arcade') {
        await saveGameState(
          userId: userId,
          categoryId: categoryId,
          stageName: stageName,
          mode: mode,
          gamemode: gamemode,
          gameState: gameState,
        );
        print('🎮 Game state saved');
      }

      // Execute cleanup callback
      onCleanup();
      print('🎮 Cleanup completed');

      // Navigate back
      if (context.mounted) {
        navigateBack(context);
      }
      print('🎮 Navigation completed');

    } catch (e) {
      print('❌ Error in handleGameQuit: $e');
      rethrow;
    }
  }

  /// Retrieves saved game state
  Future<Map<String, dynamic>?> getSavedGameState({
    required String userId,
    required String categoryId,
    required String stageName,
    required String mode,
  }) async {
    try {
      final docId = '${categoryId}_${stageName}_${mode.toLowerCase()}';
      
      // Check local storage first
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? localGameState = prefs.getString('game_progress_$docId');
      
      if (localGameState != null) {
        return jsonDecode(localGameState);
      }

      // If not in local storage and online, check Firebase
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot doc = await _firestore
            .collection('User')
            .doc(userId)
            .collection('GameProgress')
            .doc(docId)
            .get();
          
        if (doc.exists) {
          return doc.data() as Map<String, dynamic>;
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Error retrieving game state: $e');
      return null;
    }
  }
}