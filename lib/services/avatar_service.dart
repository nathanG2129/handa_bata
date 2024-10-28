import 'package:cloud_firestore/cloud_firestore.dart';

class AvatarService {
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
          int maxId = avatars.map((avatar) => avatar['id'] as int).reduce((a, b) => a > b ? a : b);
          return maxId + 1;
        }
      }
      return 0; // Start with 0 if no avatars exist
    } catch (e) {
      print('Error getting next ID: $e');
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
      print('Error adding avatar: $e');
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
      print('Error updating avatar: $e');
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
      print('Error deleting avatar: $e');
    }
  }

  Future<String> getAvatarNameById(int avatarId) async {
    try {
      DocumentSnapshot snapshot = await _avatarDoc.get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> avatars = data['avatars'] != null ? List<Map<String, dynamic>>.from(data['avatars']) : [];
        final avatar = avatars.firstWhere((avatar) => avatar['id'] == avatarId, orElse: () => {});
        if (avatar.isNotEmpty) {
          return avatar['title'] as String;
        }
      }
      return 'Kladis.png'; // Return a default avatar name if not found
    } catch (e) {
      print('Error fetching avatar name: $e');
      return 'Kladis.png'; // Return a default avatar name in case of error
    }
  }
}