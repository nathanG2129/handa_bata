import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/stage_service.dart'; // Add this import

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StageService _stageService = StageService(); // Initialize StageService

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
          await gameSaveDataRef.doc(category['id']).set(<String, dynamic>{});
        }

        await _firestore.collection('User').doc(user.uid).set({
          'email': email,
          'role': role,
        });
      }

      return user;
    } catch (e) {
      print(e.toString());
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
        await gameSaveDataRef.doc(category['id']).set(<String, dynamic>{});
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

  Future<bool> getStaySignedInPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('stay_signed_in') ?? false;
  }

  Future<void> setStaySignedInPreference(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('stay_signed_in', value);
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
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<User?> signInWithUsernameAndPassword(String username, String password) async {
    try {
      String? email = await getEmailByUsername(username);
      if (email == null) {
        print('No user found with username: $username');
        return null;
      }

      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      print(e.toString());
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
      print(e.toString());
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await clearGuestAccountDetails(); // Clear guest account details on sign out
    } catch (e) {
      print(e.toString());
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
      print(e.toString());
      return UserProfile.guestProfile;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      await clearGuestAccountDetails(); // Clear guest account details on logout
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> deleteUserAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Delete user document from Firestore
        await _firestore.collection('User').doc(user.uid).delete();
        // Delete user from Firebase Authentication
        await user.delete();
      }
    } catch (e) {
      print('Error deleting user account: $e');
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
}