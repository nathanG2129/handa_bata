import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> registerWithEmailAndPassword(String email, String password, String nickname) async {
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
        );

        await _firestore.collection('User').doc(user.uid).set({
          'profile': userProfile.toMap(),
          'games': {}, // Placeholder for the Game collection
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

  Future<User?> signInWithUsernameAndPassword(String username, String password) async {
    try {
      // Query Firestore to find the user by username
      QuerySnapshot querySnapshot = await _firestore.collection('User').where('profile.nickname', isEqualTo: username).get();
      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      // Get the email associated with the username
      String email = querySnapshot.docs.first.get('profile.email');

      // Sign in with email and password
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
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
}