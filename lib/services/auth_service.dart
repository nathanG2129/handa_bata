import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> registerWithEmailAndPassword(String email, String password, String nickname, String birthday) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      if (user != null) {
        String profileId = _firestore.collection('User').doc().id;

        UserProfile userProfile = UserProfile(
          profileId: profileId,
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
          email: '', 
          birthday: birthday, // Store birthday within the ProfileData document
        );

        // Create ProfileData collection within the user's document
        await _firestore.collection('User').doc(user.uid).collection('ProfileData').doc(profileId).set({
          ...userProfile.toMap(),
          'email': email, // Store email within the ProfileData document
        });
      }

      return user;
    } catch (e) {
      print(e.toString());
      return null;
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

      QuerySnapshot querySnapshot = await _firestore.collection('User').doc(user.uid).collection('ProfileData').get();
      if (querySnapshot.docs.isEmpty) {
        return UserProfile.guestProfile;
      }

      var document = querySnapshot.docs.first;
      Map<String, dynamic> data = document.data() as Map<String, dynamic>;
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
}