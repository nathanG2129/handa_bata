import 'package:cloud_firestore/cloud_firestore.dart';

class StageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchStages(String language) async {
    QuerySnapshot snapshot = await _firestore
        .collection('Game')
        .doc('Stage')
        .collection(language)
        .get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> fetchStageDocument(String language, String stageName) async {
    DocumentSnapshot doc = await _firestore
        .collection('Game')
        .doc('Stage')
        .collection(language)
        .doc(stageName)
        .get();
    return doc.data() as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> fetchQuestions(String language, String stageName) async {
    Map<String, dynamic> stageDocument = await fetchStageDocument(language, stageName);
    List<Map<String, dynamic>> questions = List<Map<String, dynamic>>.from(stageDocument['questions'] ?? []);
    return questions;
  }

  Future<void> addStage(String language, String stageName, List<Map<String, dynamic>> questions) async {
    await _firestore
        .collection('Game')
        .doc('Stage')
        .collection(language)
        .doc(stageName)
        .set({
      'language': language,
      'stageName': stageName,
      'questions': questions,
    });
  }

  Future<void> updateStage(String language, String stageName, List<Map<String, dynamic>> questions) async {
    await _firestore
        .collection('Game')
        .doc('Stage')
        .collection(language)
        .doc(stageName)
        .update({
      'questions': questions,
    });
  }

  Future<void> deleteStage(String language, String stageName) async {
    await _firestore
        .collection('Game')
        .doc('Stage')
        .collection(language)
        .doc(stageName)
        .delete();
  }
}