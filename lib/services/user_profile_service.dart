// lib/services/user_profile_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'badge_service.dart';
import 'banner_service.dart';
import 'avatar_service.dart';

enum ProfileField {
  nickname,
  avatarId,
  bannerId,
  badgeShowcase,
  exp,
  level,
  totalBadgeUnlocked,
  totalStageCleared,
  unlockedBadge,
  unlockedBanner,
}

class ValidationResult {
  final bool isValid;
  final String? error;
  
  const ValidationResult({
    required this.isValid,
    this.error,
  });
}

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BannerService _bannerService;
  
  // Cache constants
  static const String PROFILE_CACHE_KEY = 'user_profile_cache';
  static const String PROFILE_BACKUP_KEY = 'user_profile_backup';
  static const String PROFILE_VERSION_KEY = 'user_profile_version';
  static const Duration CACHE_DURATION = Duration(hours: 1);
  static const int MAX_RETRY_ATTEMPTS = 3;
  
  // Memory cache
  final Map<String, UserProfile> _profileCache = {};
  final Map<String, DateTime> _cacheTimes = {};
  
  // Stream controllers for real-time updates
  final _profileUpdateController = StreamController<UserProfile>.broadcast();
  Stream<UserProfile> get profileUpdates => _profileUpdateController.stream;
  
  // Avatar update stream
  final _avatarController = StreamController<int>.broadcast();
  Stream<int> get avatarStream => _avatarController.stream;

  // Pending updates queue for offline support
  final Map<String, List<Map<String, dynamic>>> _pendingUpdates = {};
  
  // Singleton pattern with dependency injection
  static UserProfileService? _instance;
  
  static void initialize(BannerService bannerService) {
    _instance = UserProfileService._internal(bannerService);
  }
  
  factory UserProfileService() {
    if (_instance == null) {
      throw StateError('UserProfileService not initialized');
    }
    return _instance!;
  }
  
  UserProfileService._internal(this._bannerService) {
    _bannerService.setProfileUpdateCallback((field, value) {
      updateProfileWithIntegration(field, value);
    });
    _initializeService();
  }

  void _initializeService() {
    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        _syncPendingUpdates();
      }
    });

    // Set up Firestore listeners
    _setupFirestoreListeners();
  }

  Future<UserProfile?> fetchUserProfile() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      String userId = user.uid;
      print('🔍 Fetching profile for user: $userId');

      // Check memory cache first
      if (_profileCache.containsKey(userId) && _isCacheValid(userId)) {
        print('💾 Returning from memory cache');
        return _profileCache[userId];
      }

      // Check local storage
      UserProfile? localProfile = await _getProfileFromLocal(userId);
      if (localProfile != null) {
        print('📱 Found local profile');
        print('🎯 Local unlocked badges: ${localProfile.unlockedBadge}');
        _updateCache(userId, localProfile);
        return localProfile;
      }

      // Try to fetch from server if online
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        print('🌐 Online, fetching from Firestore');
        DocumentSnapshot doc = await _firestore
            .collection('User')
            .doc(userId)
            .collection('ProfileData')
            .doc(userId)
            .get();

        if (doc.exists) {
          print('📄 Found Firestore profile');
          UserProfile profile = UserProfile.fromMap(doc.data() as Map<String, dynamic>);
          print('🎯 Server unlocked badges: ${profile.unlockedBadge}');
          await _saveProfileLocally(userId, profile);
          _updateCache(userId, profile);
          _bannerService.updateCurrentProfile(profile);
          return profile;
        }
      }

      // If we get here, create a new profile with default values
      print('📝 Creating new profile with default values');
      UserProfile newProfile = await _createDefaultProfile(userId);
      await _saveProfileLocally(userId, newProfile);
      _updateCache(userId, newProfile);
      return newProfile;

    } catch (e) {
      print('❌ Error in fetchUserProfile: $e');
      return null;
    }
  }

  Future<UserProfile> _createDefaultProfile(String userId) async {
    // Get badge count for proper array initialization
    final badges = await BadgeService().fetchBadges();
    final banners = await BannerService().fetchBanners();
    
    return UserProfile(
      profileId: userId,
      username: 'Guest',
      nickname: 'Guest',
      avatarId: 0,
      badgeShowcase: [-1, -1, -1],
      bannerId: 0,
      exp: 0,
      expCap: 100,
      hasShownCongrats: false,
      level: 1,
      totalBadgeUnlocked: 0,
      totalStageCleared: 0,
      unlockedBadge: List<int>.filled(badges.length, 0),
      unlockedBanner: List<int>.filled(banners.length, 0),
      email: '',
      birthday: '',
    );
  }

  Future<void> updateProfile(String field, dynamic value) async {
    try {
      if (field == 'unlockedBadge') {
        print('🔄 Updating unlocked badges');
        print('📊 Previous value: ${(await fetchUserProfile())?.unlockedBadge}');
        print('📊 New value: $value');
        
        // Verify the update
        await _verifyBadgeUpdate(value as List<int>);
      }
      
      User? user = _auth.currentUser;
      if (user == null) return;

      String userId = user.uid;

      // Check rate limiting
      if (!_checkRateLimit(userId)) {
        throw Exception('Too many updates. Please wait a moment.');
      }

      // Validate the field and value
      ProfileField? profileField = _getProfileField(field);
      if (profileField == null) {
        throw Exception('Invalid field: $field');
      }

      ValidationResult validationResult = _validateField(profileField, value);
      if (!validationResult.isValid) {
        throw Exception(validationResult.error ?? 'Invalid value');
      }

      // Sanitize the value
      dynamic sanitizedValue = _sanitizeValue(value);

      // Create update data
      Map<String, dynamic> updateData = {
        field: sanitizedValue,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Update local first
      UserProfile? currentProfile = await fetchUserProfile();
      if (currentProfile != null) {
        UserProfile updatedProfile = currentProfile.copyWith(updates: {field: sanitizedValue});
        
        // Validate entire profile after update
        if (!_validateProfile(updatedProfile)) {
          throw Exception('Invalid profile state after update');
        }

        await _saveProfileLocally(userId, updatedProfile);
        _updateCache(userId, updatedProfile);
        _profileUpdateController.add(updatedProfile);
        _bannerService.updateCurrentProfile(updatedProfile);
      }

      // Rest of the update logic remains the same...
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _queueUpdate(userId, updateData);
        return;
      }

      await _retryOperation(() async {
        await _firestore
            .collection('User')
            .doc(userId)
            .collection('ProfileData')
            .doc(userId)
            .update(updateData);
      });

      // Update rate limit tracking
      _lastUpdateTime[userId] = DateTime.now();

      // Verify after update
      if (field == 'unlockedBadge') {
        UserProfile? updated = await fetchUserProfile();
        print('📊 After update: ${updated?.unlockedBadge}');
      }
    } catch (e) {
      await _logOperation('update_error', e.toString());
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> _verifyBadgeUpdate(List<int> newBadges) async {
    UserProfile? current = await fetchUserProfile();
    if (current == null) return;
    
    // Ensure we don't lose any unlocked badges
    List<int> currentUnlocks = current.unlockedBadge;
    for (int i = 0; i < currentUnlocks.length && i < newBadges.length; i++) {
      if (currentUnlocks[i] == 1 && newBadges[i] != 1) {
        print('⚠️ Warning: Badge $i would be unlocked->locked');
        newBadges[i] = 1;
      }
    }
  }

  void updateAvatar(int newAvatarId) {
    _avatarController.add(newAvatarId);
  }

  Future<void> _syncPendingUpdates() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      String userId = user.uid;
      
      var updates = _pendingUpdates[userId] ?? [];
      if (updates.isEmpty) return;

      for (var update in updates) {
        await _retryOperation(() async {
          await _firestore
              .collection('User')
              .doc(userId)
              .collection('ProfileData')
              .doc(userId)
              .update(update);
        });
      }

      _pendingUpdates[userId]?.clear();
    } catch (e) {
      await _logOperation('sync_error', e.toString());
    }
  }

  void _queueUpdate(String userId, Map<String, dynamic> update) {
    _pendingUpdates[userId] ??= [];
    _pendingUpdates[userId]!.add(update);
  }

  Future<void> _retryOperation(Future<void> Function() operation) async {
    int attempts = 0;
    while (attempts < MAX_RETRY_ATTEMPTS) {
      try {
        await operation();
        return;
      } catch (e) {
        attempts++;
        if (attempts == MAX_RETRY_ATTEMPTS) rethrow;
        await Future.delayed(Duration(seconds: attempts));
      }
    }
  }

  Future<void> _saveProfileLocally(String userId, UserProfile profile) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Save backup of current data
      String? existingData = prefs.getString('$PROFILE_CACHE_KEY$userId');
      if (existingData != null) {
        await prefs.setString('$PROFILE_BACKUP_KEY$userId', existingData);
      }

      // Save new data
      String profileJson = jsonEncode(profile.toMap());
      await prefs.setString('$PROFILE_CACHE_KEY$userId', profileJson);
      
      // Clear backup after successful save
      await prefs.remove('$PROFILE_BACKUP_KEY$userId');
    } catch (e) {
      await _logOperation('save_local_error', e.toString());
      await _restoreFromBackup(userId);
    }
  }

  Future<UserProfile?> _getProfileFromLocal(String userId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? profileJson = prefs.getString('$PROFILE_CACHE_KEY$userId');
      if (profileJson != null) {
        Map<String, dynamic> profileMap = jsonDecode(profileJson);
        return UserProfile.fromMap(profileMap);
      }
    } catch (e) {
      await _logOperation('get_local_error', e.toString());
    }
    return null;
  }

  void _updateCache(String userId, UserProfile profile) {
    _profileCache[userId] = profile;
    _cacheTimes[userId] = DateTime.now();
    _manageCacheSize();
  }

  bool _isCacheValid(String userId) {
    final cacheTime = _cacheTimes[userId];
    if (cacheTime == null) return false;
    return DateTime.now().difference(cacheTime) < CACHE_DURATION;
  }

  void _manageCacheSize() {
    if (_profileCache.length > 10) { // Limit cache size
      var oldestKey = _cacheTimes.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _profileCache.remove(oldestKey);
      _cacheTimes.remove(oldestKey);
    }
  }

  Future<void> _restoreFromBackup(String userId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? backup = prefs.getString('$PROFILE_BACKUP_KEY$userId');
      if (backup != null) {
        await prefs.setString('$PROFILE_CACHE_KEY$userId', backup);
      }
    } catch (e) {
      await _logOperation('restore_backup_error', e.toString());
    }
  }

  Future<UserProfile?> _recoverFromError(String operation) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      String userId = user.uid;
      
      await _logOperation('recovery_attempt', 'Attempting recovery from $operation');
      
      // Clear avatar cache for current profile
      UserProfile? profile = await _getProfileFromLocal(userId);
      if (profile != null) {
        _avatarService.clearAvatarCache(profile.avatarId);
      }
      
      // Try to restore from backup
      await _restoreFromBackup(userId);
      
      // Clear corrupted cache
      _profileCache.remove(userId);
      _cacheTimes.remove(userId);
      
      // Try to get profile again
      return await _getProfileFromLocal(userId);
    } catch (e) {
      await _logOperation('recovery_error', e.toString());
      return null;
    }
  }

  void _setupFirestoreListeners() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _firestore
            .collection('User')
            .doc(user.uid)
            .collection('ProfileData')
            .doc(user.uid)
            .snapshots()
            .listen(
          (snapshot) async {
            if (snapshot.exists) {
              // Get local profile first
              UserProfile? localProfile = await _getProfileFromLocal(user.uid);
              UserProfile serverProfile = UserProfile.fromMap(snapshot.data()!);

              if (localProfile != null) {
                // Calculate total XP for both profiles
                int serverTotalXP = (serverProfile.level - 1) * 100 + serverProfile.exp;
                int localTotalXP = (localProfile.level - 1) * 100 + localProfile.exp;
                
                // Take the higher XP value
                if (localTotalXP >= serverTotalXP) {
                  // Keep local values if they're higher
                  return;
                }
              }

              // Only update if we don't have local data or server data is higher
              _updateCache(user.uid, serverProfile);
              _profileUpdateController.add(serverProfile);
            }
          },
          onError: (e) => _logOperation('listener_error', e.toString()),
        );
      }
    });
  }

  Future<void> _logOperation(String operation, String details) async {
    try {
      await _firestore.collection('Logs').add({
        'type': 'profile_operation',
        'operation': operation,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging operation: $e');
    }
  }

  void dispose() {
    _profileUpdateController.close();
    _avatarController.close();
  }

  // Add field validation rules
  static const Map<ProfileField, Map<String, dynamic>> _validationRules = {
    ProfileField.nickname: {
      'type': String,
      'minLength': 3,
      'maxLength': 20,
      'pattern': r'^[a-zA-Z0-9_]+$',
    },
    ProfileField.avatarId: {
      'type': int,
      'min': 0,
    },
    ProfileField.bannerId: {
      'type': int,
      'min': 0,
    },
    ProfileField.badgeShowcase: {
      'type': List,
      'length': 3,
      'elementType': int,
    },
    ProfileField.exp: {
      'type': int,
      'min': 0,
    },
    ProfileField.level: {
      'type': int,
      'min': 1,
    },
    ProfileField.totalBadgeUnlocked: {
      'type': int,
      'min': 0,
    },
    ProfileField.totalStageCleared: {
      'type': int,
      'min': 0,
    },
    ProfileField.unlockedBadge: {
      'type': List,
      'elementType': int,
      'allowedValues': [0, 1],
    },
    ProfileField.unlockedBanner: {
      'type': List,
      'elementType': int,
      'allowedValues': [0, 1],
    },
  };

  // Add rate limiting
  final Map<String, DateTime> _lastUpdateTime = {};
  static const Duration _minUpdateInterval = Duration(milliseconds: 500);

  bool _checkRateLimit(String userId) {
    final lastUpdate = _lastUpdateTime[userId];
    if (lastUpdate == null) return true;

    return DateTime.now().difference(lastUpdate) >= _minUpdateInterval;
  }

  ProfileField? _getProfileField(String field) {
    try {
      return ProfileField.values.firstWhere(
        (e) => e.toString().split('.').last == field
      );
    } catch (_) {
      return null;
    }
  }

  ValidationResult _validateField(ProfileField field, dynamic value) {
    final rules = _validationRules[field];
    if (rules == null) {
      return const ValidationResult(isValid: true);
    }

    // Type checking
    if (rules['type'] == List && value is! List) {
      return const ValidationResult(isValid: false, error: 'Value must be a list');
    }

    // For array validations
    if (rules['type'] == List && value is List) {
      try {
        // Cast to List<int> - this will throw if any element isn't an int
        final typedList = List<int>.from(value);
        
        // Check allowed values if specified
        if (rules['allowedValues'] != null) {
          if (!typedList.every((item) => rules['allowedValues'].contains(item))) {
            return const ValidationResult(
              isValid: false,
              error: 'Invalid values in array'
            );
          }
        }
      } catch (e) {
        return const ValidationResult(
          isValid: false,
          error: 'All elements must be integers'
        );
      }
    }

    // Type checking
    if (rules['type'] == String && value is! String) {
      return const ValidationResult(isValid: false, error: 'Value must be a string');
    }
    if (rules['type'] == int && value is! int) {
      return const ValidationResult(isValid: false, error: 'Value must be a number');
    }

    // Specific validations based on field type
    switch (field) {
      case ProfileField.nickname:
        if (value.length < rules['minLength'] || value.length > rules['maxLength']) {
          return const ValidationResult(
            isValid: false,
            error: 'Nickname must be between 3 and 20 characters'
          );
        }
        if (!RegExp(rules['pattern']).hasMatch(value)) {
          return const ValidationResult(
            isValid: false,
            error: 'Nickname can only contain letters, numbers, and underscores'
          );
        }
        break;

      case ProfileField.badgeShowcase:
        if (value.length != rules['length']) {
          return const ValidationResult(
            isValid: false,
            error: 'Badge showcase must contain exactly 3 items'
          );
        }
        if (!value.every((item) => item is int)) {
          return const ValidationResult(
            isValid: false,
            error: 'All badge IDs must be numbers'
          );
        }
        break;

      default:
        if (rules['min'] != null && value < rules['min']) {
          return ValidationResult(
            isValid: false,
            error: 'Value must be at least ${rules['min']}'
          );
        }
    }

    return const ValidationResult(isValid: true);
  }

  dynamic _sanitizeValue(dynamic value) {
    if (value is String) {
      return value.trim();
    }
    if (value is List) {
      return value.map((item) => _sanitizeValue(item)).toList();
    }
    return value;
  }

  bool _validateProfile(UserProfile profile) {
    try {
      // Basic validation
      if (profile.profileId.isEmpty) return false;
      if (profile.username.isEmpty) return false;
      if (profile.nickname.isEmpty) return false;
      if (profile.level < 1) return false;
      if (profile.exp < 0) return false;
      if (profile.expCap <= 0) return false;

      // Badge showcase validation
      if (profile.badgeShowcase.length != 3) return false;

      // Level and exp validation
      if (profile.exp >= profile.expCap) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  // Add these new methods and fields to the UserProfileService class

  // Add constants for performance optimization
  static const int BATCH_SIZE = 10;
  static const Duration PREFETCH_COOLDOWN = Duration(minutes: 5);

  // Track prefetch timestamps
  final Map<String, DateTime> _lastPrefetchTime = {};
  
  // Batch operation queue
  final List<Map<String, dynamic>> _batchQueue = [];
  // Add batch update method
  Future<void> batchUpdateProfile(Map<String, dynamic> updates) async {
    try {
      // Validate avatar if included in updates
      if (updates.containsKey('avatarId')) {
        final avatar = await _avatarService.getAvatarDetails(updates['avatarId']);
        if (avatar == null) {
          throw Exception('Invalid avatar ID in batch update');
        }
      }

      User? user = _auth.currentUser;
      if (user == null) return;

      String userId = user.uid;

      // Validate all updates first
      for (var entry in updates.entries) {
        ProfileField? field = _getProfileField(entry.key);
        if (field == null) continue;

        ValidationResult result = _validateField(field, entry.value);
        if (!result.isValid) {
          throw Exception('Invalid value for ${entry.key}: ${result.error}');
        }
      }

      // Get current profile
      UserProfile? currentProfile = await fetchUserProfile();
      if (currentProfile == null) return;

      // Handle XP updates
      bool isXPUpdate = updates.containsKey('exp') || 
                       updates.containsKey('level') || 
                       updates.containsKey('expCap');

      if (isXPUpdate) {
        // Get current profile
        UserProfile? currentProfile = await fetchUserProfile();
        if (currentProfile == null) return;

        // Calculate current total XP
        int currentTotalXP = 0;
        for (int i = 1; i < currentProfile.level; i++) {
          currentTotalXP += i * 100;  // Add up XP required for previous levels
        }
        currentTotalXP += currentProfile.exp;
        print('Current total XP: $currentTotalXP');

        // Get the XP gain from updates
        int xpGain = updates['exp'] ?? 0;
        print('XP gain: $xpGain');

        // Add the gain to current total
        int newTotalXP = currentTotalXP + xpGain;
        print('New total XP: $newTotalXP');

        // Calculate new level and exp
        int remainingXP = newTotalXP;
        int finalLevel = 1;
        
        // Keep checking if we have enough XP for next level
        while (remainingXP >= (finalLevel * 100)) {
            remainingXP -= finalLevel * 100;
            finalLevel++;
        }

        int finalExp = remainingXP;
        int finalExpCap = finalLevel * 100;

        print('Final calculations:');
        print('  XP needed for next level: ${finalExpCap}');
        print('  Current total XP: $newTotalXP');
        print('  Level: $finalLevel');
        print('  Exp: $finalExp');
        print('  ExpCap: $finalExpCap');

        // Update the updates map
        updates = {
          'exp': finalExp,
          'level': finalLevel,
          'expCap': finalExpCap,
        };
      }

      // Apply updates locally
      UserProfile updatedProfile = currentProfile.copyWith(updates: updates);
      await _saveProfileLocally(userId, updatedProfile);
      _updateCache(userId, updatedProfile);
      _profileUpdateController.add(updatedProfile);

      // Add to batch queue
      _batchQueue.add({
        'userId': userId,
        'updates': updates,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Update Firestore if online
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        await _retryOperation(() async {
          await _firestore
              .collection('User')
              .doc(userId)
              .collection('ProfileData')
              .doc(userId)
              .update(updates);
        });
      }

    } catch (e) {
      print('❌ Error in batchUpdateProfile: $e');
      await _logOperation('batch_update_error', e.toString());
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> _processBatchQueue() async {
    if (_batchQueue.isEmpty) return;

    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        await _storeBatchLocally();
        return;
      }

      // Get the current server state
      User? user = _auth.currentUser;
      if (user == null) return;

      // Get both server and local states
      DocumentSnapshot doc = await _firestore
          .collection('User')
          .doc(user.uid)
          .collection('ProfileData')
          .doc(user.uid)
          .get();

      if (!doc.exists) return;

      UserProfile? localProfile = await fetchUserProfile();
      if (localProfile == null) return;

      UserProfile serverProfile = UserProfile.fromMap(doc.data() as Map<String, dynamic>);

      // Merge exp/level changes
      if (localProfile.exp != serverProfile.exp || 
          localProfile.level != serverProfile.level || 
          localProfile.expCap != serverProfile.expCap) {
        
        // Calculate total XP for both profiles
        int serverTotalXP = ((serverProfile.level - 1) * 100) + serverProfile.exp;
        int localTotalXP = ((localProfile.level - 1) * 100) + localProfile.exp;
        
        print('XP Sync:');
        print('  Server: Level ${serverProfile.level}, Exp ${serverProfile.exp} (Total: $serverTotalXP)');
        print('  Local: Level ${localProfile.level}, Exp ${localProfile.exp} (Total: $localTotalXP)');
        
        // Take the higher XP value
        int finalTotalXP = max(serverTotalXP, localTotalXP);
        
        // Calculate final values
        int finalLevel = (finalTotalXP ~/ 100) + 1;
        int finalExp = finalTotalXP % 100;
        int finalExpCap = finalLevel * 100;
        
        print('  Final: Level $finalLevel, Exp $finalExp (Total: $finalTotalXP)');

        _batchQueue.add({
          'userId': user.uid,
          'updates': {
            'exp': finalExp,
            'level': finalLevel,
            'expCap': finalExpCap,
          },
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }

      // Process all queued updates
      WriteBatch batch = _firestore.batch();
      Map<String, UserProfile> updatedProfiles = {};

      for (var update in _batchQueue) {
        String userId = update['userId'];
        Map<String, dynamic> updates = update['updates'];

        DocumentReference docRef = _firestore
            .collection('User')
            .doc(userId)
            .collection('ProfileData')
            .doc(userId);

        batch.update(docRef, {
          ...updates,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        UserProfile updatedProfile = localProfile.copyWith(updates: updates);
        updatedProfiles[userId] = updatedProfile;
      }

      await batch.commit();

      // Update local storage and cache
      for (var entry in updatedProfiles.entries) {
        await _saveProfileLocally(entry.key, entry.value);
        _updateCache(entry.key, entry.value);
        _profileUpdateController.add(entry.value);
      }

      _batchQueue.clear();
      
    } catch (e) {
      print('❌ Error processing batch queue: $e');
      await _logOperation('batch_processing_error', e.toString());
    }
  }

  // Add prefetching
  Future<void> prefetchProfile(String userId) async {
    try {
      if (!_canPrefetch(userId)) return;

      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) return;

      DocumentSnapshot doc = await _firestore
          .collection('User')
          .doc(userId)
          .collection('ProfileData')
          .doc(userId)
          .get();

      if (doc.exists) {
        UserProfile profile = UserProfile.fromMap(doc.data() as Map<String, dynamic>);
        await _saveProfileLocally(userId, profile);
        _updateCache(userId, profile);
        _lastPrefetchTime[userId] = DateTime.now();
      }
    } catch (e) {
      await _logOperation('prefetch_error', e.toString());
    }
  }

  bool _canPrefetch(String userId) {
    final lastPrefetch = _lastPrefetchTime[userId];
    if (lastPrefetch == null) return true;
    return DateTime.now().difference(lastPrefetch) >= PREFETCH_COOLDOWN;
  }

  // Add method to store batch updates locally
  Future<void> _storeBatchLocally() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String batchJson = jsonEncode(_batchQueue);
      await prefs.setString('pending_batch_updates', batchJson);
    } catch (e) {
      await _logOperation('store_batch_error', e.toString());
    }
  }

  // Add service instances
  BadgeService get _badgeService => BadgeService();
  final AvatarService _avatarService = AvatarService();

  // Add stream subscriptions for coordinated updates
  late StreamSubscription<List<Map<String, dynamic>>> _badgeSubscription;
  late StreamSubscription<List<Map<String, dynamic>>> _bannerSubscription;
  late StreamSubscription<List<Map<String, dynamic>>> _avatarSubscription;

  // Add integration methods
  Future<void> initializeIntegrations() async {
    // Listen to badge updates
    _badgeSubscription = _badgeService.badgeUpdates.listen((badges) async {
      User? user = _auth.currentUser;
      if (user == null) return;

      UserProfile? profile = await fetchUserProfile();
      if (profile == null) return;

      // Update unlocked badges array size if needed
      if (profile.unlockedBadge.length != badges.length) {
        List<int> newUnlockedBadge = List<int>.filled(badges.length, 0);
        for (int i = 0; i < profile.unlockedBadge.length && i < badges.length; i++) {
          newUnlockedBadge[i] = profile.unlockedBadge[i];
        }
        await updateProfile('unlockedBadge', newUnlockedBadge);
      }

      // Validate badge showcase
      bool needsUpdate = false;
      List<int> updatedShowcase = List<int>.from(profile.badgeShowcase);
      for (int i = 0; i < profile.badgeShowcase.length; i++) {
        int badgeId = profile.badgeShowcase[i];
        if (badgeId != -1 && !await _badgeService.getBadgeById(badgeId)) {
          updatedShowcase[i] = -1;
          needsUpdate = true;
        }
      }
      if (needsUpdate) {
        await updateProfile('badgeShowcase', updatedShowcase);
      }
    });

    // Listen to banner updates
    _bannerSubscription = _bannerService.bannerUpdates.listen((banners) async {
      User? user = _auth.currentUser;
      if (user == null) return;

      UserProfile? profile = await fetchUserProfile();
      if (profile == null) return;

      // Update unlocked banners array size if needed
      if (profile.unlockedBanner.length != banners.length) {
        List<int> newUnlockedBanner = List<int>.filled(banners.length, 0);
        for (int i = 0; i < profile.unlockedBanner.length && i < banners.length; i++) {
          newUnlockedBanner[i] = profile.unlockedBanner[i];
        }
        await updateProfile('unlockedBanner', newUnlockedBanner);
      }

      // Validate current banner
      if (!await _bannerService.getBannerById(profile.bannerId)) {
        await updateProfile('bannerId', 0); // Reset to default banner
      }
    });

    // Listen to avatar updates
    _avatarSubscription = _avatarService.avatarUpdates.listen((avatars) async {
      User? user = _auth.currentUser;
      if (user == null) return;

      UserProfile? profile = await fetchUserProfile();
      if (profile == null) return;

      // Validate current avatar
      if (!await _avatarService.getAvatarById(profile.avatarId)) {
        await updateProfile('avatarId', 0); // Reset to default avatar
      }
    }) as StreamSubscription<List<Map<String, dynamic>>>;
  }

  // Override updateProfile to handle integrated updates
  Future<void> updateProfileWithIntegration(String field, dynamic value) async {
    try {
      // Handle array fields specifically
      if (field == 'unlockedBadge' || field == 'unlockedBanner') {
        if (value is String) {
          // Decode the string back to a proper List<int>
          final decoded = jsonDecode(value) as Map<String, dynamic>;
          if (decoded['type'] == 'badge_array') {
            // Explicitly construct List<int> from the decoded data
            value = (decoded['data'] as List).map((e) => e as int).toList();
          }
        }
      }
      
      // Update profile
      await updateProfile(field, value);
      
      // Broadcast update
      final updatedProfile = await fetchUserProfile();
      if (updatedProfile != null) {
        _profileUpdateController.add(updatedProfile);
      }
    } catch (e) {
      print('Error in updateProfileWithIntegration: $e');
      rethrow;
    }
  }

  // Rename the second dispose method to disposeIntegrations
  void disposeIntegrations() {
    _badgeSubscription.cancel();
    _bannerSubscription.cancel();
    _avatarSubscription.cancel();
  }

  // Add method to sync all integrated data
  Future<void> syncIntegratedData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      UserProfile? profile = await fetchUserProfile();
      if (profile == null) return;

      // Add avatar sync check
      if (profile.avatarId != 0) {  // 0 is default avatar
        final avatar = await _avatarService.getAvatarDetails(profile.avatarId);
        if (avatar == null) {
          // Avatar no longer exists, reset to default
          await updateProfile('avatarId', 0);
        }
      }

      // Sync with badge service
      List<Map<String, dynamic>> badges = await _badgeService.fetchBadges();
      if (profile.unlockedBadge.length != badges.length) {
        await updateProfile('unlockedBadge', List<int>.filled(badges.length, 0));
      }

      // Sync with banner service
      List<Map<String, dynamic>> banners = await _bannerService.fetchBanners();
      if (profile.unlockedBanner.length != banners.length) {
        await updateProfile('unlockedBanner', List<int>.filled(banners.length, 0));
      }

      // Validate current selections
      bool needsUpdate = false;
      Map<String, dynamic> updates = {};

      if (!await _avatarService.getAvatarById(profile.avatarId)) {
        updates['avatarId'] = 0;
        needsUpdate = true;
      }

      if (!await _bannerService.getBannerById(profile.bannerId)) {
        updates['bannerId'] = 0;
        needsUpdate = true;
      }

      if (needsUpdate) {
        await batchUpdateProfile(updates);
      }
    } catch (e) {
      await _logOperation('sync_error', e.toString());
      rethrow;
    }
  }
}