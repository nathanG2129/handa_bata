import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class StageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String STAGES_CACHE_KEY_PREFIX = 'stages_';
  static const String CATEGORIES_CACHE_KEY_PREFIX = 'categories_';

  Future<List<Map<String, dynamic>>> fetchStages(String language, String category) async {
    try {
      // Try to get from Firebase first if online
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        QuerySnapshot snapshot = await _firestore
            .collection('Game')
            .doc('Stage')
            .collection(language)
            .doc(category)
            .collection('stages')
            .get();
        List<Map<String, dynamic>> stages = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['stageDescription'] = data['stageDescription'] ?? '';
          return data;
        }).toList();
        
        // Cache the fetched data
        await _storeStagesLocally(language, category, stages);
        return stages;
      }
      
      // If offline or Firebase fetch failed, get from local storage
      return await _getStagesFromLocal(language, category);
    } catch (e) {
      // On error, try to get from local storage
      return await _getStagesFromLocal(language, category);
    }
  }

  Future<void> _storeStagesLocally(String language, String category, List<Map<String, dynamic>> stages) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String key = '$STAGES_CACHE_KEY_PREFIX$language.$category';
      String stagesJson = jsonEncode(stages);
      await prefs.setString(key, stagesJson);
    } catch (e) {
      // Handle error silently - local storage is a fallback
    }
  }

  Future<List<Map<String, dynamic>>> _getStagesFromLocal(String language, String category) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String key = '$STAGES_CACHE_KEY_PREFIX$language.$category';
      String? stagesJson = prefs.getString(key);
      if (stagesJson != null) {
        List<dynamic> stagesList = jsonDecode(stagesJson);
        return stagesList.map((stage) => stage as Map<String, dynamic>).toList();
      }
    } catch (e) {
      // Handle error silently
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchStageDocument(String language, String category, String stageName) async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot doc = await _firestore
            .collection('Game')
            .doc('Stage')
            .collection(language)
            .doc(category)
            .collection('stages')
            .doc(stageName)
            .get();
        Map<String, dynamic> stageData = doc.data() as Map<String, dynamic>;
        
        // Cache individual stage data
        await _storeStageDocumentLocally(language, category, stageName, stageData);
        return stageData;
      }
      
      // If offline, get from local storage
      return await _getStageDocumentFromLocal(language, category, stageName);
    } catch (e) {
      return await _getStageDocumentFromLocal(language, category, stageName);
    }
  }

  Future<void> _storeStageDocumentLocally(String language, String category, String stageName, Map<String, dynamic> stageData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String key = '${STAGES_CACHE_KEY_PREFIX}doc_$language.$category.$stageName';
      String stageJson = jsonEncode(stageData);
      await prefs.setString(key, stageJson);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<Map<String, dynamic>> _getStageDocumentFromLocal(String language, String category, String stageName) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String key = '${STAGES_CACHE_KEY_PREFIX}doc_$language.$category.$stageName';
      String? stageJson = prefs.getString(key);
      if (stageJson != null) {
        return jsonDecode(stageJson) as Map<String, dynamic>;
      }
    } catch (e) {
      // Handle error silently
    }
    return {};
  }

  Future<List<Map<String, dynamic>>> fetchQuestions(String language, String category, String stageName) async {
    try {
      Map<String, dynamic> stageDocument = await fetchStageDocument(language, category, stageName);
      if (stageDocument.isEmpty) {
        throw Exception('Stage document is empty');
      }
      return List<Map<String, dynamic>>.from(stageDocument['questions'] ?? []);
    } catch (e) {
      return [];
    }
  }

  Future<void> addStage(String language, String category, String stageName, Map<String, dynamic> stageData) async {
    try {
      stageData['stageDescription'] = stageData['stageDescription'] ?? '';
      
      // Update local storage first
      List<Map<String, dynamic>> stages = await _getStagesFromLocal(language, category);
      stages.add(stageData);
      await _storeStagesLocally(language, category, stages);
      await _storeStageDocumentLocally(language, category, stageName, stageData);
      
      // Then update Firebase if online
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _firestore
            .collection('Game')
            .doc('Stage')
            .collection(language)
            .doc(category)
            .collection('stages')
            .doc(stageName)
            .set(stageData);
      }
    } catch (e) {
      // If Firebase update fails, at least we have local storage
    }
  }

  Future<void> updateStage(String language, String category, String stageName, Map<String, dynamic> stageData) async {
    try {
      stageData['stageDescription'] = stageData['stageDescription'] ?? '';
      
      // Update local storage first
      await _storeStageDocumentLocally(language, category, stageName, stageData);
      List<Map<String, dynamic>> stages = await _getStagesFromLocal(language, category);
      int index = stages.indexWhere((stage) => stage['stageName'] == stageName);
      if (index != -1) {
        stages[index] = stageData;
        await _storeStagesLocally(language, category, stages);
      }
      
      // Then update Firebase if online
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _firestore
            .collection('Game')
            .doc('Stage')
            .collection(language)
            .doc(category)
            .collection('stages')
            .doc(stageName)
            .update(stageData);
      }
    } catch (e) {
      // If Firebase update fails, at least we have local storage
    }
  }

  Future<void> deleteStage(String language, String category, String stageName) async {
    try {
      // Delete from local storage first
      List<Map<String, dynamic>> stages = await _getStagesFromLocal(language, category);
      stages.removeWhere((stage) => stage['stageName'] == stageName);
      await _storeStagesLocally(language, category, stages);
      
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String key = '${STAGES_CACHE_KEY_PREFIX}doc_$language.$category.$stageName';
      await prefs.remove(key);
      
      // Then delete from Firebase if online
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _firestore
            .collection('Game')
            .doc('Stage')
            .collection(language)
            .doc(category)
            .collection('stages')
            .doc(stageName)
            .delete();
      }
    } catch (e) {
      // If Firebase delete fails, at least we've updated local storage
    }
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