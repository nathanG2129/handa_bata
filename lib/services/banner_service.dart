import 'package:cloud_firestore/cloud_firestore.dart';

class BannerService {
  final DocumentReference _bannerDoc = FirebaseFirestore.instance.collection('Game').doc('Banner');

  Future<List<Map<String, dynamic>>> fetchBanners() async {
    try {
      DocumentSnapshot snapshot = await _bannerDoc.get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        print('Fetched data: $data'); // Debug print
        return data['banners'] != null ? List<Map<String, dynamic>>.from(data['banners']) : [];
      } else {
        print('Banner document does not exist'); // Debug print
        return [];
      }
    } catch (e) {
      print('Error fetching banners: $e');
      return [];
    }
  }

  Future<int> getNextId() async {
    try {
      DocumentSnapshot snapshot = await _bannerDoc.get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> banners = data['banners'] != null ? List<Map<String, dynamic>>.from(data['banners']) : [];
        if (banners.isNotEmpty) {
          int maxId = banners.map((banner) => banner['id'] as int).reduce((a, b) => a > b ? a : b);
          return maxId + 1;
        }
      }
      return 1;
    } catch (e) {
      print('Error getting next ID: $e');
      return 1;
    }
  }

  Future<void> addBanner(Map<String, dynamic> banner) async {
    try {
      int nextId = await getNextId();
      banner['id'] = nextId;
      DocumentSnapshot snapshot = await _bannerDoc.get();
      List<Map<String, dynamic>> banners = [];
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        banners = data['banners'] != null ? List<Map<String, dynamic>>.from(data['banners']) : [];
      }
      banners.add(banner);
      await _bannerDoc.update({'banners': banners});
    } catch (e) {
      print('Error adding banner: $e');
    }
  }

  Future<void> updateBanner(int id, Map<String, dynamic> updatedBanner) async {
    try {
      DocumentSnapshot snapshot = await _bannerDoc.get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> banners = data['banners'] != null ? List<Map<String, dynamic>>.from(data['banners']) : [];
        int index = banners.indexWhere((banner) => banner['id'] == id);
        if (index != -1) {
          banners[index] = updatedBanner;
          await _bannerDoc.update({'banners': banners});
        }
      }
    } catch (e) {
      print('Error updating banner: $e');
    }
  }

  Future<void> deleteBanner(int id) async {
    try {
      DocumentSnapshot snapshot = await _bannerDoc.get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> banners = data['banners'] != null ? List<Map<String, dynamic>>.from(data['banners']) : [];
        banners.removeWhere((banner) => banner['id'] == id);
        await _bannerDoc.update({'banners': banners});
      }
    } catch (e) {
      print('Error deleting banner: $e');
    }
  }
}