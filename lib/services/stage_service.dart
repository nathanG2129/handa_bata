import 'package:cloud_firestore/cloud_firestore.dart';

class StageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchStages(String language, String category) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Game')
          .doc('Stage')
          .collection(language)
          .doc(category)
          .collection('stages')
          .get();
      if (snapshot.docs.isEmpty) {
      } else {
      }
      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> fetchStageDocument(String language, String category, String stageName) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('Game')
          .doc('Stage')
          .collection(language)
          .doc(category)
          .collection('stages')
          .doc(stageName)
          .get();
      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> fetchQuestions(String language, String category, String stageName) async {
    try {
      Map<String, dynamic> stageDocument = await fetchStageDocument(language, category, stageName);
      if (stageDocument.isEmpty) {
        throw Exception('Stage document is empty');
      }
      List<Map<String, dynamic>> questions = List<Map<String, dynamic>>.from(stageDocument['questions'] ?? []);
      return questions;
    } catch (e) {
      return [];
    }
  }

  Future<void> addStage(String language, String category, String stageName, Map<String, dynamic> stageData) async {
    await _firestore
        .collection('Game')
        .doc('Stage')
        .collection(language)
        .doc(category)
        .collection('stages')
        .doc(stageName)
        .set(stageData);
  }

  Future<void> updateStage(String language, String category, String stageName, Map<String, dynamic> stageData) async {
    await _firestore
        .collection('Game')
        .doc('Stage')
        .collection(language)
        .doc(category)
        .collection('stages')
        .doc(stageName)
        .update(stageData);
  }

  Future<void> deleteStage(String language, String category, String stageName) async {
    await _firestore
        .collection('Game')
        .doc('Stage')
        .collection(language)
        .doc(category)
        .collection('stages')
        .doc(stageName)
        .delete();
  }

  Future<List<Map<String, dynamic>>> fetchCategories(String language) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Game')
          .doc('Stage')
          .collection(language)
          .get();
      if (snapshot.docs.isEmpty) {
      } else {
      }
      List<Map<String, dynamic>> categories = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'],
          'description': doc['description'],
        };
      }).toList();
      return categories;
    } catch (e) {
      return [];
    }
  }

  Future<void> updateCategory(String language, String categoryId, Map<String, dynamic> categoryData) async {
    await _firestore
        .collection('Game')
        .doc('Stage')
        .collection(language)
        .doc(categoryId)
        .update(categoryData);
  }

  Future<int> fetchMaxScore(String language, String category, String stageName) async {
    try {
      Map<String, dynamic> stageDocument = await fetchStageDocument(language, category, stageName);
      if (stageDocument.isEmpty) {
        throw Exception('Stage document is empty');
      }
      return stageDocument['maxScore'] as int;
    } catch (e) {
      return 0;
    }
  }
}