import 'package:cloud_firestore/cloud_firestore.dart';

class StageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchStages(String language, String category) async {
    QuerySnapshot snapshot = await _firestore
        .collection('Game')
        .doc('Stage')
        .collection(language)
        .doc(category)
        .collection('stages')
        .get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> fetchStageDocument(String language, String category, String stageName) async {
    DocumentSnapshot doc = await _firestore
        .collection('Game')
        .doc('Stage')
        .collection(language)
        .doc(category)
        .collection('stages')
        .doc(stageName)
        .get();
    return doc.data() as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> fetchQuestions(String language, String category, String stageName) async {
    Map<String, dynamic> stageDocument = await fetchStageDocument(language, category, stageName);
    List<Map<String, dynamic>> questions = List<Map<String, dynamic>>.from(stageDocument['questions'] ?? []);
    return questions;
  }

  Future<void> addStage(String language, String category, String stageName, Map<String, dynamic> stageData) async {
    // Add the stage document
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
      print('Fetching categories from Firestore...');
      QuerySnapshot snapshot = await _firestore
          .collection('Game')
          .doc('Stage')
          .collection(language)
          .get();
      if (snapshot.docs.isEmpty) {
        print('No categories found.');
      } else {
        print('Categories found: ${snapshot.docs.length}');
      }
      
      List<Map<String, dynamic>> categories = snapshot.docs.map((doc) {
        print('Fetched category document: ${doc.id}');
        return {
          'id': doc.id,
          'name': doc['name'],
          'description': doc['description'],
          
        };
      }).toList();
      print('Fetched categories from Firestore: $categories');
      return categories;
    } catch (e) {
      print('Error fetching categories: $e');
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
}