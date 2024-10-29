import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/game_save_data.dart'; // Add this import
import '../services/stage_service.dart'; // Add this import

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StageService _stageService = StageService(); // Initialize StageService

  AuthService() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        syncGuestProfile();
        syncUserProfile();
      }
    });
    _listenToFirestoreChanges(); // Add this line
  }

  Future<User?> registerWithEmailAndPassword(String email, String password, String username, String nickname, String birthday, {String role = 'user'}) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      if (user != null) {
        UserProfile userProfile = UserProfile(
          profileId: user.uid,
          username: username,
          nickname: nickname,
          avatarId: 0,
          badgeShowcase: [0, 0, 0],
          bannerId: 0,
          exp: 0,
          expCap: 100,
          hasShownCongrats: false,
          level: 1,
          totalBadgeUnlocked: 0,
          totalStageCleared: 0,
          unlockedBadge: List<int>.filled(40, 0),
          unlockedBanner: List<int>.filled(10, 0),
          email: email,
          birthday: birthday,
        );

        await _firestore.collection('User').doc(user.uid).collection('ProfileData').doc(user.uid).set(userProfile.toMap());

        // Fetch categories and create gameSaveData documents
        List<Map<String, dynamic>> categories = await _stageService.fetchCategories('en'); // Assuming 'en' as the language
        CollectionReference gameSaveDataRef = _firestore.collection('User').doc(user.uid).collection('GameSaveData');
        for (Map<String, dynamic> category in categories) {
          // Fetch stages for the category
          List<Map<String, dynamic>> stages = await _stageService.fetchStages('en', category['id']);
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
      }

      return user;
    } catch (e) {
      return null;
    }
  }

  Future<void> createGuestProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      UserProfile guestProfile = UserProfile(
        profileId: user.uid,
        username: 'Guest',
        nickname: 'Guest',
        avatarId: 0,
        badgeShowcase: [0, 0, 0],
        bannerId: 0,
        exp: 0,
        expCap: 100,
        hasShownCongrats: false,
        level: 1,
        totalBadgeUnlocked: 0,
        totalStageCleared: 0,
        unlockedBadge: List<int>.filled(40, 0),
        unlockedBanner: List<int>.filled(10, 0),
        email: 'guest@example.com',
        birthday: '2000-01-01',
      );

      await _firestore.collection('User').doc(user.uid).collection('ProfileData').doc(user.uid).set(guestProfile.toMap());

      // Fetch categories and create gameSaveData documents
      List<Map<String, dynamic>> categories = await _stageService.fetchCategories('en'); // Assuming 'en' as the language
      CollectionReference gameSaveDataRef = _firestore.collection('User').doc(user.uid).collection('GameSaveData');
      for (Map<String, dynamic> category in categories) {
        // Fetch stages for the category
        List<Map<String, dynamic>> stages = await _stageService.fetchStages('en', category['id']);
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
        'email': 'guest@example.com',
        'role': 'guest',
      });

      // Save guest account details locally
      await saveGuestAccountDetails(user.uid);
      await saveGuestProfileLocally(guestProfile); // Save guest profile locally
    }
  }

    Future<void> syncUserProfile() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userProfileString = prefs.getString('userProfile');
      if (userProfileString != null) {
        Map<String, dynamic> userProfileMap = jsonDecode(userProfileString);
        UserProfile userProfile = UserProfile.fromMap(userProfileMap);
        try {
          await _firestore.collection('User').doc(userProfile.profileId).collection('ProfileData').doc(userProfile.profileId).set(userProfile.toMap());
          prefs.remove('userProfile'); // Remove local data after successful sync
        } catch (e) {
        }
      }
    }
  }

  Future<void> syncGuestProfile() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult != ConnectivityResult.none) {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? guestProfileString = prefs.getString('guestProfile');
    if (guestProfileString != null) {
      Map<String, dynamic> guestProfileMap = jsonDecode(guestProfileString);
      UserProfile guestProfile = UserProfile.fromMap(guestProfileMap);
      try {
        await _firestore.collection('User').doc(guestProfile.profileId).collection('ProfileData').doc(guestProfile.profileId).set(guestProfile.toMap());
        prefs.remove('guestProfile'); // Remove local data after successful sync
      } catch (e) {
      }
    }
  }
}

  Future<void> saveGuestProfileLocally(UserProfile profile) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String profileJson = jsonEncode(profile.toMap());
    await prefs.setString('guest_profile', profileJson);
  }

  Future<UserProfile?> getLocalGuestProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? profileJson = prefs.getString('guest_profile');
    if (profileJson != null) {
      Map<String, dynamic> profileMap = jsonDecode(profileJson);
      return UserProfile.fromMap(profileMap);
    }
    return null;
  }

  Future<void> clearLocalGuestProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('guest_profile');
  }

  Future<bool> isSignedIn() async {
    User? user = _auth.currentUser;
    return user != null;
  }

  Future<void> saveGuestAccountDetails(String uid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('guest_uid', uid);
  }

  Future<String?> getGuestAccountDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('guest_uid');
  }

  Future<void> clearGuestAccountDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('guest_uid');
  }

  Future<void> updateUserProfile(String field, String newValue) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('User').doc(user.uid).collection('ProfileData').doc(user.uid).update({field: newValue});
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
      await clearGuestAccountDetails(); // Clear guest account details on sign out
    } catch (e) {
    }
  }

  Future<UserProfile?> getUserProfile() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return UserProfile.guestProfile;
      }

      DocumentSnapshot profileDoc = await _firestore.collection('User').doc(user.uid).collection('ProfileData').doc(user.uid).get();
      if (!profileDoc.exists) {
        return UserProfile.guestProfile;
      }

      Map<String, dynamic> data = profileDoc.data() as Map<String, dynamic>;
      return UserProfile(
        profileId: data['profileId'],
        username: data['username'],
        nickname: data['nickname'],
        avatarId: data['avatarId'],
        badgeShowcase: List<int>.from(data['badgeShowcase']),
        bannerId: data['bannerId'],
        exp: data['exp'],
        expCap: data['expCap'],
        hasShownCongrats: data['hasShownCongrats'],
        level: data['level'],
        totalBadgeUnlocked: data['totalBadgeUnlocked'],
        totalStageCleared: data['totalStageCleared'],
        unlockedBadge: List<int>.from(data['unlockedBadge']),
        unlockedBanner: List<int>.from(data['unlockedBanner']),
        email: data['email'],
        birthday: data['birthday'],
      );
    } catch (e) {
      return UserProfile.guestProfile;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      await clearGuestAccountDetails(); // Clear guest account details on logout
    } catch (e) {
    }
  }

  Future<void> deleteUserAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Specify the subcollections you want to delete
        List<String> subcollections = ['ProfileData', 'GameSaveData'];
  
        // Delete all documents in each subcollection
        for (String subcollection in subcollections) {
          var subcollectionDocs = await _firestore.collection('User').doc(user.uid).collection(subcollection).get();
          for (var doc in subcollectionDocs.docs) {
            await doc.reference.delete();
          }
        }
  
        // Delete user document from Firestore
        await _firestore.collection('User').doc(user.uid).delete();
        
        // Delete user from Firebase Authentication
        await user.delete();
      }
    } catch (e) {
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
    _firestore.collectionGroup('ProfileData').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added ||
            change.type == DocumentChangeType.modified ||
            change.type == DocumentChangeType.removed) {
          _syncFirestoreToLocal(change.doc);
        }
      }
    });
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String profileJson = jsonEncode(profile.toMap());
    await prefs.setString('user_profile', profileJson); // Ensure the key is 'user_profile'
  }

  Future<void> updateAvatarId(int avatarId) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('User')
            .doc(user.uid)
            .collection('ProfileData')
            .doc(user.uid)
            .update({'avatarId': avatarId});
      }
    } catch (e) {
      print('Error updating avatar ID: $e');
      rethrow;
    }
  }
}