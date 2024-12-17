import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';

class ResourceService {
  static final ResourceService _instance = ResourceService._internal();
  factory ResourceService() => _instance;
  ResourceService._internal();

  // Firestore reference
  final _resourceDoc = FirebaseFirestore.instance.collection('Resources').doc('resources');

  // Stream controllers
  final _resourceUpdateController = StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get resourceUpdates => _resourceUpdateController.stream;

  // Cache keys
  static const String RESOURCE_CACHE_KEY = 'resource_cache';
  static const String RESOURCE_REVISION_KEY = 'resource_revision';

  final StreamController<bool> _syncStatusController = StreamController<bool>.broadcast();
  Stream<bool> get syncStatus => _syncStatusController.stream;

  Future<List<Map<String, dynamic>>> fetchResources({bool isAdmin = false}) async {
    try {
      if (isAdmin) {
        // For admin, always fetch from server
        DocumentSnapshot snapshot = await _resourceDoc.get();
        if (!snapshot.exists) return [];

        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> resources = 
            data['resources'] != null ? List<Map<String, dynamic>>.from(data['resources']) : [];
            
        // Convert string IDs to integers for UI
        return resources.map((resource) {
          var converted = Map<String, dynamic>.from(resource);
          converted['id'] = int.parse(resource['id'].toString());
          return converted;
        }).toList();
      }

      // For users, try local cache first
      List<Map<String, dynamic>> localResources = await _getResourcesFromLocal();
      
      // If local storage is empty, try fetching from server
      if (localResources.isEmpty) {
        var connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          DocumentSnapshot snapshot = await _resourceDoc.get();
          if (snapshot.exists) {
            Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
            localResources = data['resources'] != null ? 
                List<Map<String, dynamic>>.from(data['resources']) : [];
            
            await _storeResourcesLocally(localResources);
          }
        }
      }
      
      // Convert string IDs to integers for UI
      return localResources.map((resource) {
        var converted = Map<String, dynamic>.from(resource);
        converted['id'] = int.parse(resource['id'].toString());
        return converted;
      }).toList();
    } catch (e) {
      await _logResourceOperation('fetch_error', -1, e.toString());
      return [];
    }
  }

  Future<void> addResource(Map<String, dynamic> resource) async {
    try {
      int nextId = await getNextId();
      var resourceToStore = Map<String, dynamic>.from(resource);
      resourceToStore['id'] = nextId.toString(); // Store as string in Firestore
      
      List<Map<String, dynamic>> resources = await fetchResources();
      resources.add(resourceToStore);
      
      // Convert IDs back to strings for storage
      var resourcesToStore = resources.map((r) {
        var converted = Map<String, dynamic>.from(r);
        converted['id'] = r['id'].toString();
        return converted;
      }).toList();
      
      await _storeResourcesLocally(resourcesToStore);
      await _updateServerResources(resourcesToStore);

      // Notify listeners of the update with integer IDs
      _resourceUpdateController.add(resources);

      await _logResourceOperation(
        'admin_create',
        nextId,
        'Resource created',
        metadata: {
          'title': resource['title'],
          'type': resource['type'],
        }
      );
    } catch (e) {
      await _logResourceOperation('add_error', -1, e.toString());
      rethrow;
    }
  }

  Future<void> updateResource(Map<String, dynamic> resource) async {
    try {
      List<Map<String, dynamic>> resources = await fetchResources();
      int index = resources.indexWhere((r) => r['id'] == resource['id']);
      
      if (index != -1) {
        resources[index] = resource;
        
        // Convert IDs to strings for storage
        var resourcesToStore = resources.map((r) {
          var converted = Map<String, dynamic>.from(r);
          converted['id'] = r['id'].toString();
          return converted;
        }).toList();
        
        await _storeResourcesLocally(resourcesToStore);
        await _updateServerResources(resourcesToStore);

        // Notify listeners of the update with integer IDs
        _resourceUpdateController.add(resources);

        await _logResourceOperation(
          'admin_update',
          resource['id'],
          'Resource updated',
          metadata: {
            'title': resource['title'],
            'type': resource['type'],
          }
        );
      }
    } catch (e) {
      await _logResourceOperation('update_error', -1, e.toString());
      rethrow;
    }
  }

  Future<void> deleteResource(int id) async {
    try {
      List<Map<String, dynamic>> resources = await fetchResources();
      resources.removeWhere((resource) => resource['id'] == id);
      
      // Convert IDs to strings for storage
      var resourcesToStore = resources.map((r) {
        var converted = Map<String, dynamic>.from(r);
        converted['id'] = r['id'].toString();
        return converted;
      }).toList();
      
      await _storeResourcesLocally(resourcesToStore);
      await _updateServerResources(resourcesToStore);

      // Notify listeners of the update with integer IDs
      _resourceUpdateController.add(resources);

      await _logResourceOperation('admin_delete', id, 'Resource deleted');
    } catch (e) {
      await _logResourceOperation('delete_error', -1, e.toString());
      rethrow;
    }
  }

  Future<void> _storeResourcesLocally(List<Map<String, dynamic>> resources) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(RESOURCE_CACHE_KEY, json.encode(resources));
    } catch (e) {
      await _logResourceOperation('local_store_error', -1, e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> _getResourcesFromLocal() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cachedData = prefs.getString(RESOURCE_CACHE_KEY);
      if (cachedData != null) {
        List<dynamic> decoded = List<dynamic>.from(
          (cachedData.startsWith('[') && cachedData.endsWith(']'))
              ? json.decode(cachedData)
              : []
        );
        return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      await _logResourceOperation('local_fetch_error', -1, e.toString());
    }
    return [];
  }

  Future<void> _updateServerResources(List<Map<String, dynamic>> resources) async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // Use set with merge option instead of update to create the document if it doesn't exist
        await _resourceDoc.set({
          'resources': resources,
          'revision': FieldValue.increment(1),
          'lastModified': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        await _logResourceOperation('server_update', -1, 'Updated ${resources.length} resources');
      }
    } catch (e) {
      await _logResourceOperation('server_update_error', -1, e.toString());
      rethrow;
    }
  }

  Future<int> getNextId() async {
    try {
      List<Map<String, dynamic>> resources = await fetchResources();
      if (resources.isEmpty) {
        return 0;
      }
      
      int maxId = resources
        .map((resource) => int.tryParse(resource['id'].toString()) ?? -1)
        .reduce((a, b) => a > b ? a : b);
      return maxId + 1;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _logResourceOperation(
    String operation,
    dynamic resourceId,
    String details, {
    Map<String, dynamic>? metadata
  }) async {
    try {
      await FirebaseFirestore.instance.collection('Logs').add({
        'type': 'resource_operation',
        'operation': operation,
        'resourceId': resourceId.toString(),
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        if (metadata != null) 'metadata': metadata,
      });
    } catch (e) {
      // Silently fail logging
    }
  }

  bool _validateResourceData(Map<String, dynamic> resource) {
    return resource.containsKey('id') &&
           resource.containsKey('title') &&
           resource.containsKey('type') &&
           resource.containsKey('src') &&
           resource.containsKey('reference') &&
           (resource['type'] != 'infographic' || resource.containsKey('thumbnailPath'));
  }

  void dispose() {
    _resourceUpdateController.close();
    _syncStatusController.close();
  }
} 