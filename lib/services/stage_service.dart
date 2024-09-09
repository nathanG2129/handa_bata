import 'package:cloud_firestore/cloud_firestore.dart';

class StageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchStages(String language) async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('Game').doc('Stages').collection(language).get();
      if (querySnapshot.docs.isEmpty) {
        print('No stages found for language: $language');
      }
      return querySnapshot.docs.map((doc) {
        print('Fetched stage: ${doc.id}');
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['stageName'] = doc.id; // Add the document name as the stage name
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching stages: $e');
      return [];
    }
  }
}