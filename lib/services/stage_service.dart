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
}