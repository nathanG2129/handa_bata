import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Existing imports
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
      List<Map<String, dynamic>> stages = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['stageDescription'] = data['stageDescription'] ?? ''; // Ensure stageDescription is included
        return data;
      }).toList();
      await _storeStagesLocally(language, category, stages);
      return stages;
    } catch (e) {
      return await _getStagesFromLocal(language, category);
    }
  }

  Future<void> _storeStagesLocally(String language, String category, List<Map<String, dynamic>> stages) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'stages_$language.$category';
    String stagesJson = jsonEncode(stages);
    await prefs.setString(key, stagesJson);
  }

  Future<List<Map<String, dynamic>>> _getStagesFromLocal(String language, String category) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'stages_$language.$category';
    String? stagesJson = prefs.getString(key);
    if (stagesJson != null) {
      List<dynamic> stagesList = jsonDecode(stagesJson);
      return stagesList.map((stage) => stage as Map<String, dynamic>).toList();
    }
    return [];
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
    stageData['stageDescription'] = stageData['stageDescription'] ?? ''; // Ensure stageDescription is included
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
    stageData['stageDescription'] = stageData['stageDescription'] ?? ''; // Ensure stageDescription is included
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
      List<Map<String, dynamic>> categories = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'],
          'description': doc['description'],
        };
      }).toList();
      await _storeCategoriesLocally(language, categories);
      return categories;
    } catch (e) {
      return await _getCategoriesFromLocal(language);
    }
  }

    Future<void> _storeCategoriesLocally(String language, List<Map<String, dynamic>> categories) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'categories_$language';
    String categoriesJson = jsonEncode(categories);
    await prefs.setString(key, categoriesJson);
  }

  Future<List<Map<String, dynamic>>> _getCategoriesFromLocal(String language) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'categories_$language';
    String? categoriesJson = prefs.getString(key);
    if (categoriesJson != null) {
      List<dynamic> categoriesList = jsonDecode(categoriesJson);
      return categoriesList.map((category) => category as Map<String, dynamic>).toList();
    }
    return [];
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