import 'package:cloud_firestore/cloud_firestore.dart';

class BannerService {
  final DocumentReference _bannerDoc = FirebaseFirestore.instance.collection('Game').doc('Banner');

  Future<List<Map<String, dynamic>>> fetchBanners() async {
    try {
      DocumentSnapshot snapshot = await _bannerDoc.get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        // Debug print
        return data['banners'] != null ? List<Map<String, dynamic>>.from(data['banners']) : [];
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
      DocumentSnapshot snapshot = await _bannerDoc.get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> banners = data['banners'] != null ? List<Map<String, dynamic>>.from(data['banners']) : [];
        if (banners.isNotEmpty) {
          int maxId = banners.map((banner) => banner['id'] as int).reduce((a, b) => a > b ? a : b);
          return maxId + 1;
        }
      }
      return 0; // Start with 0 if no banners exist
    } catch (e) {
      return 0; // Start with 0 in case of error
    }
  }

  Future<void> addBanner(Map<String, dynamic> banner) async {
    try {
      int nextId = await getNextId();
      banner['id'] = nextId; // Set id as int
      DocumentSnapshot snapshot = await _bannerDoc.get();
      List<Map<String, dynamic>> banners = [];
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        banners = data['banners'] != null ? List<Map<String, dynamic>>.from(data['banners']) : [];
      }
      banners.add(banner);
      await _bannerDoc.update({'banners': banners});
    } catch (e) {
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
    }
  }
}