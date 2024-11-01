import 'package:cloud_firestore/cloud_firestore.dart';

class BadgeService {
  final DocumentReference _badgeDoc = FirebaseFirestore.instance.collection('Game').doc('Badge');

  Future<List<Map<String, dynamic>>> fetchBadges() async {
    try {
      DocumentSnapshot snapshot = await _badgeDoc.get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        print('Fetched data: $data'); // Debug print
        return data['badges'] != null ? List<Map<String, dynamic>>.from(data['badges']) : [];
      } else {
        print('Badge document does not exist'); // Debug print
        return [];
      }
    } catch (e) {
      print('Error fetching badges: $e');
      return [];
    }
  }

  Future<int> getNextId() async {
    try {
      DocumentSnapshot snapshot = await _badgeDoc.get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> badges = data['badges'] != null ? List<Map<String, dynamic>>.from(data['badges']) : [];
        if (badges.isNotEmpty) {
          int maxId = badges.map((badge) => badge['id'] as int).reduce((a, b) => a > b ? a : b);
          return maxId + 1;
        }
      }
      return 0;
    } catch (e) {
      print('Error getting next ID: $e');
      return 0;
    }
  }

  Future<void> addBadge(Map<String, dynamic> badge) async {
    try {
      int nextId = await getNextId();
      badge['id'] = nextId;
      DocumentSnapshot snapshot = await _badgeDoc.get();
      List<Map<String, dynamic>> badges = [];
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        badges = data['badges'] != null ? List<Map<String, dynamic>>.from(data['badges']) : [];
      }
      badges.add(badge);
      await _badgeDoc.update({'badges': badges});
    } catch (e) {
      print('Error adding badge: $e');
    }
  }

  Future<void> updateBadge(int id, Map<String, dynamic> updatedBadge) async {
    try {
      DocumentSnapshot snapshot = await _badgeDoc.get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> badges = data['badges'] != null ? List<Map<String, dynamic>>.from(data['badges']) : [];
        int index = badges.indexWhere((badge) => badge['id'] == id);
        if (index != -1) {
          badges[index] = updatedBadge;
          await _badgeDoc.update({'badges': badges});
        }
      }
    } catch (e) {
      print('Error updating badge: $e');
    }
  }

  Future<void> deleteBadge(int id) async {
    try {
      DocumentSnapshot snapshot = await _badgeDoc.get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> badges = data['badges'] != null ? List<Map<String, dynamic>>.from(data['badges']) : [];
        badges.removeWhere((badge) => badge['id'] == id);
        await _badgeDoc.update({'badges': badges});
      }
    } catch (e) {
      print('Error deleting badge: $e');
    }
  }
}