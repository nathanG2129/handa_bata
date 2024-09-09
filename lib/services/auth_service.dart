import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> registerWithEmailAndPassword(String email, String password, String nickname, String birthday, {String role = 'user'}) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      if (user != null) {
        UserProfile userProfile = UserProfile(
          profileId: user.uid, // Use the user's UID as the profile ID
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
          birthday: birthday, // Store birthday within the ProfileData document
        );

        // Create ProfileData collection within the user's document
        await _firestore.collection('User').doc(user.uid).collection('ProfileData').doc(user.uid).set(userProfile.toMap());

        // Initialize GameSaveData collection with documents
        CollectionReference gameSaveDataRef = _firestore.collection('User').doc(user.uid).collection('GameSaveData');

        await gameSaveDataRef.doc('AdventureQuake').set(<String, dynamic>{});
        await gameSaveDataRef.doc('AdventureStorm').set(<String, dynamic>{});
        await gameSaveDataRef.doc('ArcadeQuake').set(<String, dynamic>{});

        // Store user role in Firestore
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

  Future<void> updateUserProfile(String field, String newValue) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Update the specific field in the user's document in Firestore
        await _firestore.collection('User').doc(user.uid).collection('ProfileData').doc(user.uid).update({field: newValue});
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<String?> getEmailByUsername(String username) async {
    try {
      // Query Firestore to find the user by username
      QuerySnapshot querySnapshot = await _firestore.collectionGroup('ProfileData').where('nickname', isEqualTo: username).get();
      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      // Get the email associated with the username
      return querySnapshot.docs.first.get('email');
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
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
      // Clear any cached user data if necessary
      print('User logged out successfully');
    } catch (e) {
      print('Error logging out: $e');
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
    try {
      DocumentSnapshot docSnapshot = await _firestore.collection('User').doc(uid).get();
      if (docSnapshot.exists) {
        return docSnapshot['role'];
      }
      return null;
    } catch (e) {
      print('Error fetching user role: $e');
      return null;
    }
  }
}