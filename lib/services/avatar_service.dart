import 'package:cloud_firestore/cloud_firestore.dart';

class AvatarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DocumentReference _avatarDoc = FirebaseFirestore.instance.collection('Game').doc('Avatar');

  Future<List<Map<String, dynamic>>> fetchAvatars() async {
    try {
      DocumentSnapshot snapshot = await _avatarDoc.get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        print('Fetched data: $data'); // Debug print
        return data['avatars'] != null ? List<Map<String, dynamic>>.from(data['avatars']) : [];
      } else {
        print('Avatar document does not exist'); // Debug print
        return [];
      }
    } catch (e) {
      print('Error fetching avatars: $e');
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
          int maxId = avatars.map((avatar) => int.parse(avatar['id'])).reduce((a, b) => a > b ? a : b);
          return maxId + 1;
        }
      }
      return 1;
    } catch (e) {
      print('Error getting next ID: $e');
      return 1;
    }
  }

  Future<void> addAvatar(Map<String, dynamic> avatar) async {
    try {
      int nextId = await getNextId();
      avatar['id'] = nextId.toString();
      DocumentSnapshot snapshot = await _avatarDoc.get();
      List<Map<String, dynamic>> avatars = [];
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        avatars = data['avatars'] != null ? List<Map<String, dynamic>>.from(data['avatars']) : [];
      }
      avatars.add(avatar);
      await _avatarDoc.update({'avatars': avatars});
    } catch (e) {
      print('Error adding avatar: $e');
    }
  }

  Future<void> updateAvatar(String id, Map<String, dynamic> updatedAvatar) async {
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
      print('Error updating avatar: $e');
    }
  }

  Future<void> deleteAvatar(String id) async {
    try {
      DocumentSnapshot snapshot = await _avatarDoc.get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> avatars = data['avatars'] != null ? List<Map<String, dynamic>>.from(data['avatars']) : [];
        avatars.removeWhere((avatar) => avatar['id'] == id);
        await _avatarDoc.update({'avatars': avatars});
      }
    } catch (e) {
      print('Error deleting avatar: $e');
    }
  }
}