import 'package:cloud_firestore/cloud_firestore.dart';

class AvatarService {
  final DocumentReference _avatarDoc = FirebaseFirestore.instance.collection('Game').doc('Avatar');

  Future<List<Map<String, dynamic>>> fetchAvatars() async {
    try {
      DocumentSnapshot snapshot = await _avatarDoc.get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        // Debug print
        return data['avatars'] != null ? List<Map<String, dynamic>>.from(data['avatars']) : [];
      } else {
        // Debug print
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<int> getNextId() async {
    try {
      DocumentSnapshot snapshot = await _avatarDoc.get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> avatars = data['avatars'] != null ? List<Map<String, dynamic>>.from(data['avatars']) : [];
        if (avatars.isNotEmpty) {
          int maxId = avatars.map((avatar) => avatar['id'] as int).reduce((a, b) => a > b ? a : b);
          return maxId + 1;
        }
      }
      return 0; // Start with 0 if no avatars exist
    } catch (e) {
      return 0; // Start with 0 in case of error
    }
  }

  Future<void> addAvatar(Map<String, dynamic> avatar) async {
    try {
      int nextId = await getNextId();
      avatar['id'] = nextId; // Set id as int
      DocumentSnapshot snapshot = await _avatarDoc.get();
      List<Map<String, dynamic>> avatars = [];
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        avatars = data['avatars'] != null ? List<Map<String, dynamic>>.from(data['avatars']) : [];
      }
      avatars.add(avatar);
      await _avatarDoc.update({'avatars': avatars});
    } catch (e) {
    }
  }

  Future<void> updateAvatar(int id, Map<String, dynamic> updatedAvatar) async {
    try {
      DocumentSnapshot snapshot = await _avatarDoc.get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> avatars = data['avatars'] != null ? List<Map<String, dynamic>>.from(data['avatars']) : [];
        int index = avatars.indexWhere((avatar) => avatar['id'] == id);
        if (index != -1) {
          avatars[index] = updatedAvatar;
          await _avatarDoc.update({'avatars': avatars});
        }
      }
    } catch (e) {
    }
  }

  Future<void> deleteAvatar(int id) async {
    try {
      DocumentSnapshot snapshot = await _avatarDoc.get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> avatars = data['avatars'] != null ? List<Map<String, dynamic>>.from(data['avatars']) : [];
        avatars.removeWhere((avatar) => avatar['id'] == id);
        await _avatarDoc.update({'avatars': avatars});
      }
    } catch (e) {
    }
  }
}