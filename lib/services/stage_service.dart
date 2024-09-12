import 'package:cloud_firestore/cloud_firestore.dart';

class StageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addStage(String language, String category, String stageName, List<Map<String, dynamic>> questions) async {
    await _firestore
        .collection('Game')
        .doc('Stage')
        .collection(language)
        .doc(category)
        .collection('stages')
        .doc(stageName)
        .set({
      'language': language,
      'category': category,
      'stageName': stageName,
      'questions': questions,
    });
  }

  Future<void> updateStage(String language, String category, String stageName, List<Map<String, dynamic>> questions) async {
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

  Future<List<Map<String, dynamic>>> fetchStages(String language) async {
    QuerySnapshot categorySnapshot = await _firestore
        .collection('Game')
        .doc('Stage')
        .collection(language)
        .get();
    List<Map<String, dynamic>> stages = [];
    for (var categoryDoc in categorySnapshot.docs) {
      QuerySnapshot stageSnapshot = await categoryDoc.reference.collection('stages').get();
      for (var stageDoc in stageSnapshot.docs) {
        stages.add(stageDoc.data() as Map<String, dynamic>);
      }
    }
    return stages;
  }

  Future<List<Map<String, dynamic>>> fetchQuestions(String language, String category, String stageName) async {
    DocumentSnapshot docSnapshot = await _firestore
        .collection('Game')
        .doc('Stage')
        .collection(language)
        .doc(category)
        .collection('stages')
        .doc(stageName)
        .get();
    return (docSnapshot.data() as Map<String, dynamic>)['questions'];
  }
}