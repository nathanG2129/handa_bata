import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class StageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DocumentReference _stageDoc = FirebaseFirestore.instance.collection('Game').doc('Stage');
  static const String STAGES_CACHE_KEY = 'stages_cache';
  static const String CATEGORIES_CACHE_KEY = 'categories_cache';
  static const String STAGE_REVISION_KEY = 'stage_revision';
  static const String STAGES_CACHE_KEY_PREFIX = 'stages_';
  static const int MAX_STORED_VERSIONS = 5;
  static const int MAX_CACHE_SIZE = 100;

  // Memory cache for stages and categories
  final Map<String, Map<String, dynamic>> _stageCache = {};
  final Map<String, List<Map<String, dynamic>>> _categoryCache = {};

  // Stream controllers for real-time updates
  final _stageUpdateController = StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get stageUpdates => _stageUpdateController.stream;

  final _categoryUpdateController = StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get categoryUpdates => _categoryUpdateController.stream;

  // Add cache expiration
  final Map<String, DateTime> _cacheTimes = {};
  static const Duration CACHE_DURATION = Duration(hours: 1);

  // Add defaultLanguage field
  static const String defaultLanguage = 'en';

  void _manageCacheExpiry() {
    final now = DateTime.now();
    _cacheTimes.removeWhere((key, time) {
      if (now.difference(time) > CACHE_DURATION) {
        _stageCache.remove(key);
        _categoryCache.remove(key);
        return true;
      }
      return false;
    });
  }

  Future<List<Map<String, dynamic>>> fetchCategories(String language) async {
    try {
      // Check memory cache first
      if (_categoryCache.containsKey(language)) {
        return _categoryCache[language]!;
      }

      // Then check local storage
      List<Map<String, dynamic>> localCategories = await _getCategoriesFromLocal(language);
      
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        // Get all documents in the language collection
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('Game')
            .doc('Stage')
            .collection(language)
            .get();

        List<Map<String, dynamic>> categories = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'] ?? '',
            'description': doc['description'] ?? '',
          };
        }).toList();

        // Cache the results
        _categoryCache[language] = categories;
        await _storeCategoriesLocally(categories, language);
        return categories;
      }
      return localCategories;
    } catch (e) {
      print('Error in fetchCategories: $e');
      return await _getCategoriesFromLocal(language);
    }
  }

  Future<List<Map<String, dynamic>>> fetchStages(String language, String categoryId) async {
    try {
      String cacheKey = '${language}_${categoryId}_stages';
      if (_stageCache.containsKey(cacheKey)) {
        return List<Map<String, dynamic>>.from(_stageCache[cacheKey]!['stages']);
      }

      List<Map<String, dynamic>> localStages = await _getStagesFromLocal(categoryId);
      
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        // Get all stage documents in the stages subcollection
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('Game')
            .doc('Stage')
            .collection(language)
            .doc(categoryId)
            .collection('stages')
            .get();

        List<Map<String, dynamic>> stages = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            'stageName': doc.id,
            ...data,
          };
        }).toList();

        // Cache the results
        _stageCache[cacheKey] = {
          'stages': stages,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        
        await _storeStagesLocally(stages, categoryId);
        return stages;
      }
      return localStages;
    } catch (e) {
      print('Error in fetchStages: $e');
      return await _getStagesFromLocal(categoryId);
    }
  }

  Future<List<Map<String, dynamic>>> _getCategoriesFromLocal(String language) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? categoriesJson = prefs.getString('${CATEGORIES_CACHE_KEY}_$language');
      if (categoriesJson != null) {
        List<dynamic> categoriesList = jsonDecode(categoriesJson);
        return categoriesList.map((category) => category as Map<String, dynamic>).toList();
      }
    } catch (e) {
      print('Error getting categories from local: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _getStagesFromLocal(String categoryId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? stagesJson = prefs.getString('${STAGES_CACHE_KEY}_$categoryId');
      if (stagesJson != null) {
        List<dynamic> stagesList = jsonDecode(stagesJson);
        return stagesList.map((stage) => stage as Map<String, dynamic>).toList();
      }
    } catch (e) {
      print('Error getting stages from local: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _fetchAndUpdateLocal(
    DocumentSnapshot snapshot, 
    String language, 
    String categoryId
  ) async {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    List<Map<String, dynamic>> stages = 
        data['stages'] != null ? List<Map<String, dynamic>>.from(data['stages']) : [];
    
    await _storeStagesLocally(stages, categoryId);
    await _storeLocalRevision(snapshot.get('revision') ?? 0);
    await cleanupOldVersions();
    
    return stages;
  }

  Future<List<Map<String, dynamic>>> _fetchAndUpdateLocalCategories(
    DocumentSnapshot snapshot,
    String language
  ) async {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    List<Map<String, dynamic>> categories = 
        data['categories'] != null ? List<Map<String, dynamic>>.from(data['categories']) : [];
    
    await _storeCategoriesLocally(categories, language);
    await _storeLocalRevision(snapshot.get('revision') ?? 0);
    await cleanupOldVersions();
    
    return categories;
  }

  Future<Map<String, dynamic>?> getStageById(String categoryId, String stageId) async {
    try {
      String cacheKey = '${categoryId}_$stageId';
      if (_stageCache.containsKey(cacheKey)) {
        return _stageCache[cacheKey];
      }
      
      List<Map<String, dynamic>> stages = await _getStagesFromLocal(categoryId);
      var stage = stages.firstWhere((s) => s['id'] == stageId, orElse: () => {});
      
      if (stage.isNotEmpty) {
        _stageCache[cacheKey] = stage;
        _manageCacheSize();
        return stage;
      }

      // Fetch from server if not found locally
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        // Similar to avatar service server fetch
      }
      
      return null;
    } catch (e) {
      print('Error in getStageById: $e');
      return null;
    }
  }

  void _manageCacheSize() {
    if (_stageCache.length > MAX_CACHE_SIZE) {
      final keysToRemove = _stageCache.keys.take(_stageCache.length - MAX_CACHE_SIZE);
      for (var key in keysToRemove) {
        _stageCache.remove(key);
      }
    }
  }

  Future<void> invalidateCache() async {
    _stageCache.clear();
    _categoryCache.clear();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(STAGES_CACHE_KEY);
  }

  // Add data integrity checks
  Future<void> _verifyDataIntegrity() async {
    try {
      List<Map<String, dynamic>> serverStages = [];
      List<Map<String, dynamic>> localStages = await _getStagesFromLocal('all');
      
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot snapshot = await _stageDoc.get();
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          serverStages = List<Map<String, dynamic>>.from(data['stages'] ?? []);
          
          // Compare and repair data
          bool needsRepair = false;
          
          // Check for duplicate stages
          Set<String> seenStages = {};
          for (var stage in localStages) {
            String stageKey = '${stage['language']}_${stage['categoryId']}_${stage['stageName']}';
            if (seenStages.contains(stageKey)) {
              needsRepair = true;
              break;
            }
            seenStages.add(stageKey);
          }

          // Compare with server data
          if (serverStages.length != localStages.length) {
            needsRepair = true;
          }

          if (needsRepair) {
            await _resolveStageConflicts(serverStages, localStages);
            await _logStageOperation('integrity_repair', 'all', 'Data repaired');
          }
        }
      }

      // Clear cache after verification
      _stageCache.clear();
      
    } catch (e) {
      print('Error verifying data integrity: $e');
      await _logStageOperation('integrity_check_error', 'all', e.toString());
    }
  }

  Future<void> _resolveStageConflicts(
    List<Map<String, dynamic>> serverStages, 
    List<Map<String, dynamic>> localStages
  ) async {
    try {
      Map<String, Map<String, dynamic>> mergedStages = {};
      
      // Add server stages
      for (var stage in serverStages) {
        String key = '${stage['language']}_${stage['categoryId']}_${stage['stageName']}';
        mergedStages[key] = stage;
      }
      
      // Compare with local stages
      for (var localStage in localStages) {
        String key = '${localStage['language']}_${localStage['categoryId']}_${localStage['stageName']}';
        if (!mergedStages.containsKey(key) || 
            (localStage['lastModified'] ?? 0) > (mergedStages[key]!['lastModified'] ?? 0)) {
          mergedStages[key] = localStage;
        }
      }
      
      List<Map<String, dynamic>> resolvedStages = mergedStages.values.toList();
      await _storeStagesLocally(resolvedStages, 'all');
      await _updateServerStages(resolvedStages);
    } catch (e) {
      print('Error resolving stage conflicts: $e');
      await _logStageOperation('conflict_resolution_error', 'all', e.toString());
    }
  }

  // Add operation logging
  Future<void> _logStageOperation(String operation, String categoryId, String details) async {
    try {
      await FirebaseFirestore.instance.collection('Logs').add({
        'type': 'stage_operation',
        'operation': operation,
        'categoryId': categoryId,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging operation: $e');
    }
  }

  Future<void> _storeStagesLocally(List<Map<String, dynamic>> stages, String categoryId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // Store backup before updating
      String? existingData = prefs.getString('${STAGES_CACHE_KEY}_$categoryId');
      if (existingData != null) {
        await prefs.setString('${STAGES_CACHE_KEY}_${categoryId}_backup', existingData);
      }
      
      String stagesJson = jsonEncode(stages);
      await prefs.setString('${STAGES_CACHE_KEY}_$categoryId', stagesJson);
      
      // Clear backup after successful update
      await prefs.remove('${STAGES_CACHE_KEY}_${categoryId}_backup');
    } catch (e) {
      await _restoreFromBackup(categoryId);
      print('Error storing stages locally: $e');
    }
  }

  Future<void> _storeCategoriesLocally(List<Map<String, dynamic>> categories, String language) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? existingData = prefs.getString('${CATEGORIES_CACHE_KEY}_$language');
      if (existingData != null) {
        await prefs.setString('${CATEGORIES_CACHE_KEY}_${language}_backup', existingData);
      }
      
      String categoriesJson = jsonEncode(categories);
      await prefs.setString('${CATEGORIES_CACHE_KEY}_$language', categoriesJson);
      
      await prefs.remove('${CATEGORIES_CACHE_KEY}_${language}_backup');
    } catch (e) {
      await _restoreFromBackup(language);
      print('Error storing categories locally: $e');
    }
  }

  Future<void> _restoreFromBackup(String key) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? backup = prefs.getString('${STAGES_CACHE_KEY}_${key}_backup');
      if (backup != null) {
        await prefs.setString('${STAGES_CACHE_KEY}_$key', backup);
      }
    } catch (e) {
      print('Error restoring from backup: $e');
    }
  }

  Future<int?> _getLocalRevision() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(STAGE_REVISION_KEY);
  }

  Future<void> _storeLocalRevision(int revision) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(STAGE_REVISION_KEY, revision);
  }

  Future<void> cleanupOldVersions() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final oldKeys = prefs.getKeys()
          .where((key) => key.startsWith('stage_version_'))
          .toList();
      
      if (oldKeys.length > MAX_STORED_VERSIONS) {
        oldKeys.sort();
        for (var key in oldKeys.take(oldKeys.length - MAX_STORED_VERSIONS)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Error cleaning up versions: $e');
    }
  }

  void dispose() {
    _stageUpdateController.close();
    _categoryUpdateController.close();
  }

  // Admin Methods
  Future<void> addStage(String language, String categoryId, String stageName, Map<String, dynamic> stageData) async {
    try {
      // Validate stage data
      if (!_validateStageData(stageData)) {
        throw Exception('Invalid stage data');
      }

      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot snapshot = await transaction.get(_stageDoc);
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          
          // Get current stages
          List<Map<String, dynamic>> stages = 
              data['stages'] != null ? List<Map<String, dynamic>>.from(data['stages']) : [];
          
          // Add new stage
          stages.add({
            'categoryId': categoryId,
            'stageName': stageName,
            'language': language,
            ...stageData,
          });

          // Update Firestore
          transaction.update(_stageDoc, {
            'stages': stages,
            'revision': FieldValue.increment(1),
            'lastModified': FieldValue.serverTimestamp(),
          });

          // Update local storage
          await _storeStagesLocally(stages, categoryId);
          await _logStageOperation('add_stage', categoryId, 'Added stage: $stageName');
        });
      } else {
        throw Exception('No internet connection');
      }
    } catch (e) {
      print('Error adding stage: $e');
      await _logStageOperation('add_stage_error', categoryId, e.toString());
      rethrow;
    }
  }

  bool _validateStageData(Map<String, dynamic> data) {
    // Debug print to see what data we're getting
    print('Validating stage data: $data');
    
    // More lenient validation for stage updates
    return data.containsKey('stageDescription') || // Stage description is optional
           data.containsKey('questions') ||        // Questions might be updated separately
           data.containsKey('maxScore') ||         // Score might be updated separately
           data.containsKey('totalQuestions');     // Total questions might be updated separately
  }

  Future<void> updateStage(String language, String categoryId, String stageName, Map<String, dynamic> updatedData) async {
    try {
      // Debug print to see what we're trying to update
      print('Attempting to update stage with data: $updatedData');

      if (!_validateStageData(updatedData)) {
        print('Stage data validation failed for: $updatedData');
        throw Exception('Invalid stage data');
      }

      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          // Get the stage document
          DocumentSnapshot stageDoc = await transaction.get(
            _firestore
                .collection('Game')
                .doc('Stage')
                .collection(language)
                .doc(categoryId)
                .collection('stages')
                .doc(stageName)
          );

          // Merge existing data with updates
          Map<String, dynamic> existingData = stageDoc.data() as Map<String, dynamic>;
          Map<String, dynamic> mergedData = {
            ...existingData,
            ...updatedData,
            'lastModified': FieldValue.serverTimestamp(),
          };

          // Update the document
          transaction.update(stageDoc.reference, mergedData);

          // Update local storage
          List<Map<String, dynamic>> stages = await _getStagesFromLocal(categoryId);
          int index = stages.indexWhere((s) => 
              s['stageName'] == stageName &&
              s['language'] == language);

          if (index != -1) {
            stages[index] = mergedData;
            await _storeStagesLocally(stages, categoryId);
          }

          await _logStageOperation('update_stage', categoryId, 'Updated stage: $stageName');
        });
      } else {
        throw Exception('No internet connection');
      }
    } catch (e) {
      print('Error updating stage: $e');
      await _logStageOperation('update_stage_error', categoryId, e.toString());
      rethrow;
    }
  }

  Future<void> deleteStage(String language, String categoryId, String stageName) async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot snapshot = await transaction.get(_stageDoc);
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          
          List<Map<String, dynamic>> stages = 
              data['stages'] != null ? List<Map<String, dynamic>>.from(data['stages']) : [];
          
          stages.removeWhere((stage) => 
              stage['categoryId'] == categoryId && 
              stage['stageName'] == stageName &&
              stage['language'] == language);

          transaction.update(_stageDoc, {
            'stages': stages,
            'revision': FieldValue.increment(1),
            'lastModified': FieldValue.serverTimestamp(),
          });

          await _storeStagesLocally(stages, categoryId);
          await _logStageOperation('delete_stage', categoryId, 'Deleted stage: $stageName');
        });
      } else {
        throw Exception('No internet connection');
      }
    } catch (e) {
      print('Error deleting stage: $e');
      await _logStageOperation('delete_stage_error', categoryId, e.toString());
      rethrow;
    }
  }

  Future<void> updateCategory(String language, String categoryId, Map<String, dynamic> updatedData) async {
    try {
      if (!_validateCategoryData(updatedData)) {
        throw Exception('Invalid category data');
      }

      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot snapshot = await transaction.get(_stageDoc);
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          
          List<Map<String, dynamic>> categories = 
              data['categories'] != null ? List<Map<String, dynamic>>.from(data['categories']) : [];
          
          int index = categories.indexWhere((cat) => 
              cat['id'] == categoryId && cat['language'] == language);

          if (index != -1) {
            categories[index] = {
              'id': categoryId,
              'language': language,
              ...updatedData,
            };

            transaction.update(_stageDoc, {
              'categories': categories,
              'revision': FieldValue.increment(1),
              'lastModified': FieldValue.serverTimestamp(),
            });

            await _storeCategoriesLocally(categories, language);
            await _logStageOperation('update_category', categoryId, 'Updated category');
          }
        });
      } else {
        throw Exception('No internet connection');
      }
    } catch (e) {
      print('Error updating category: $e');
      await _logStageOperation('update_category_error', categoryId, e.toString());
      rethrow;
    }
  }

  bool _validateCategoryData(Map<String, dynamic> data) {
    return data.containsKey('name') &&
           data.containsKey('description');
  }

  Future<List<Map<String, dynamic>>> fetchQuestions(String language, String categoryId, String stageName) async {
    try {
      // Check cache first
      String cacheKey = '${language}_${categoryId}_${stageName}_questions';
      if (_stageCache.containsKey(cacheKey)) {
        final cachedData = _stageCache[cacheKey];
        if (cachedData != null && cachedData.containsKey('questions')) {
          return List<Map<String, dynamic>>.from(cachedData['questions']);
        }
      }

      // Get the stage document first
      Map<String, dynamic> stageDoc = await fetchStageDocument(language, categoryId, stageName);
      
      if (stageDoc.isNotEmpty && stageDoc.containsKey('questions')) {
        List<Map<String, dynamic>> questions = List<Map<String, dynamic>>.from(stageDoc['questions']);
        // Cache the questions
        _stageCache[cacheKey] = {'questions': questions};
        return questions;
      }

      return [];
    } catch (e) {
      print('Error fetching questions: $e');
      await _logStageOperation('fetch_questions_error', categoryId, e.toString());
      return [];
    }
  }

  Future<Map<String, dynamic>> fetchStageDocument(String language, String categoryId, String stageName) async {
    try {
      // Check cache first
      String cacheKey = '${language}_${categoryId}_${stageName}_doc';
      if (_stageCache.containsKey(cacheKey)) {
        final cachedData = _stageCache[cacheKey];
        if (cachedData != null) {
          return Map<String, dynamic>.from(cachedData);
        }
      }

      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot doc = await _firestore
            .collection('Game')
            .doc('Stage')
            .collection(language)
            .doc(categoryId)
            .collection('stages')
            .doc(stageName)
            .get();

        if (doc.exists) {
          Map<String, dynamic> stageData = doc.data() as Map<String, dynamic>;
          // Cache the document
          _stageCache[cacheKey] = stageData;
          await _storeStageDocumentLocally(language, categoryId, stageName, stageData);
          return stageData;
        }
      }

      // If offline or not found, try local storage
      return await _getStageDocumentFromLocal(language, categoryId, stageName);
    } catch (e) {
      print('Error fetching stage document: $e');
      return await _getStageDocumentFromLocal(language, categoryId, stageName);
    }
  }

  Future<void> _storeStageDocumentLocally(String language, String categoryId, String stageName, Map<String, dynamic> stageData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String key = '${STAGES_CACHE_KEY_PREFIX}doc_$language.$categoryId.$stageName';
      String stageJson = jsonEncode(stageData);
      await prefs.setString(key, stageJson);
    } catch (e) {
      print('Error storing stage document locally: $e');
    }
  }

  Future<Map<String, dynamic>> _getStageDocumentFromLocal(String language, String categoryId, String stageName) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String key = '${STAGES_CACHE_KEY_PREFIX}doc_$language.$categoryId.$stageName';
      String? stageJson = prefs.getString(key);
      if (stageJson != null) {
        return jsonDecode(stageJson) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error getting stage document from local: $e');
    }
    return {};
  }

  Future<void> _updateServerStages(List<Map<String, dynamic>> stages) async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _stageDoc.update({
          'stages': stages,
          'revision': FieldValue.increment(1),
          'lastModified': FieldValue.serverTimestamp(),
        });
        await _logStageOperation('server_update', 'all', 'Updated ${stages.length} stages');
      }
    } catch (e) {
      print('Error updating server stages: $e');
      await _logStageOperation('server_update_error', 'all', e.toString());
      rethrow;
    }
  }

  // Add batch operations for better performance
  Future<void> batchUpdateStages(List<Map<String, dynamic>> stages) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(_stageDoc, {
          'stages': stages,
          'revision': FieldValue.increment(1),
          'lastModified': FieldValue.serverTimestamp(),
        });

        await _storeStagesLocally(stages, 'all');
        await _logStageOperation('batch_update', 'all', 'Updated ${stages.length} stages');
      });
    } catch (e) {
      print('Error in batch update: $e');
      await _logStageOperation('batch_update_error', 'all', e.toString());
      rethrow;
    }
  }

  // Add prefetching for better UX
  Future<void> prefetchCategory(String categoryId) async {
    try {
      if (_stageCache.containsKey(categoryId)) return;

      var stages = await fetchStages(defaultLanguage, categoryId);
      _stageCache[categoryId] = {
        'stages': stages,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      print('Error prefetching category: $e');
    }
  }

  // Add bulk operations
  Future<Map<String, List<Map<String, dynamic>>>> fetchMultipleCategories(
    List<String> categoryIds
  ) async {
    Map<String, List<Map<String, dynamic>>> results = {};
    
    await Future.wait(
      categoryIds.map((id) async {
        results[id] = await fetchStages(defaultLanguage, id);
      })
    );

    return results;
  }

  Future<bool> validateStageData(Map<String, dynamic> stageData) async {
    try {
      // Basic validation
      if (!_validateStageData(stageData)) return false;

      // Deep validation
      bool isValid = true;
      
      // Check questions
      if (stageData['questions'] != null) {
        for (var question in stageData['questions']) {
          if (!_validateQuestionData(question)) {
            isValid = false;
            break;
          }
        }
      }

      // Check stage progression
      if (stageData['prerequisites'] != null) {
        isValid = await _validatePrerequisites(stageData['prerequisites']);
      }

      return isValid;
    } catch (e) {
      print('Error validating stage data: $e');
      return false;
    }
  }

  bool _validateQuestionData(Map<String, dynamic> question) {
    // Add specific question validation logic
    return question.containsKey('type') &&
           question.containsKey('question') &&
           question.containsKey('answers');
  }

  Future<bool> _validatePrerequisites(List<String> prerequisites) async {
    try {
      for (var prereq in prerequisites) {
        var stageExists = await checkStageExists(prereq);
        if (!stageExists) return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> performMaintenance() async {
    try {
      // Clean up old versions
      await cleanupOldVersions();
      
      // Clear expired cache
      _manageCacheExpiry();
      
      // Verify data integrity
      await _verifyDataIntegrity();
      
      // Clean up old logs
      await _cleanupOldLogs();
      
      // Optimize storage
      await _optimizeStorage();
    } catch (e) {
      print('Error during maintenance: $e');
      await _logStageOperation('maintenance_error', 'all', e.toString());
    }
  }

  Future<void> _optimizeStorage() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Remove unused cache entries
      final allKeys = prefs.getKeys();
      for (var key in allKeys) {
        if (key.startsWith('stage_') && !key.contains('_backup')) {
          final lastAccess = await _getLastAccess(key);
          if (DateTime.now().difference(lastAccess) > const Duration(days: 30)) {
            await prefs.remove(key);
          }
        }
      }
    } catch (e) {
      print('Error optimizing storage: $e');
    }
  }

  Future<bool> checkStageExists(String stageId) async {
    try {
      var stages = await _getStagesFromLocal('all');
      return stages.any((stage) => stage['id'] == stageId);
    } catch (e) {
      print('Error checking stage existence: $e');
      return false;
    }
  }

  Future<void> _cleanupOldLogs() async {
    try {
      // Delete logs older than 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      await FirebaseFirestore.instance
          .collection('Logs')
          .where('type', isEqualTo: 'stage_operation')
          .where('timestamp', isLessThan: thirtyDaysAgo)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });
    } catch (e) {
      print('Error cleaning up logs: $e');
    }
  }

  Future<DateTime> _getLastAccess(String key) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? timestamp = prefs.getInt('${key}_last_access');
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      print('Error getting last access: $e');
    }
    return DateTime.now().subtract(const Duration(days: 31)); // Return old date to trigger cleanup
  }

  Future<void> _updateLastAccess(String key) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${key}_last_access', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error updating last access: $e');
    }
  }

  Future<void> _handleOfflineChanges() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        // Sync any pending changes
        SharedPreferences prefs = await SharedPreferences.getInstance();
        final pendingChanges = prefs.getStringList('pending_stage_changes') ?? [];
        
        for (var changeJson in pendingChanges) {
          Map<String, dynamic> change = jsonDecode(changeJson);
          await _syncChange(change);
        }
        
        // Clear pending changes after successful sync
        await prefs.setStringList('pending_stage_changes', []);
      }
    } catch (e) {
      print('Error handling offline changes: $e');
    }
  }

  Future<void> _syncChange(Map<String, dynamic> change) async {
    try {
      switch (change['type']) {
        case 'update':
          await _updateServerStages(change['data']);
          break;
        case 'delete':
          // Handle delete sync
          break;
        // Add other cases as needed
      }
    } catch (e) {
      print('Error syncing change: $e');
    }
  }

  Future<void> _recoverFromError(String operation, String categoryId, dynamic error) async {
    try {
      await _logStageOperation('error_recovery', categoryId, 'Attempting recovery from $operation error');
      
      // Verify data integrity
      await _verifyDataIntegrity();
      
      // Clear corrupted cache
      _stageCache.clear();
      _categoryCache.clear();
      
      // Attempt to restore from backup
      await _restoreFromBackup(categoryId);
      
      await _logStageOperation('recovery_complete', categoryId, 'Successfully recovered from error');
    } catch (e) {
      print('Error during recovery: $e');
      await _logStageOperation('recovery_failed', categoryId, e.toString());
    }
  }

  Future<void> _syncData() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        // Handle offline changes first
        await _handleOfflineChanges();
        
        // Then sync with server
        DocumentSnapshot snapshot = await _stageDoc.get();
        if (snapshot.exists) {
          int serverRevision = snapshot.get('revision') ?? 0;
          int localRevision = await _getLocalRevision() ?? -1;
          
          if (serverRevision > localRevision) {
            // Server has newer data
            await _fetchAndUpdateLocal(snapshot, defaultLanguage, 'all');
          }
        }
      }
    } catch (e) {
      print('Error syncing data: $e');
    }
  }
}