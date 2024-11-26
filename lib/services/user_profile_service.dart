// lib/services/user_profile_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:handabatamae/models/game_save_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'badge_service.dart';
import 'banner_service.dart';
import 'avatar_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

// Add at top level
class ServiceState {
  final bool isInitialized;
  final DateTime lastSync;
  final String? lastError;
  final bool isHealthy;
  
  const ServiceState({
    required this.isInitialized,
    required this.lastSync,
    this.lastError,
    this.isHealthy = true,
  });

  ServiceState copyWith({
    bool? isInitialized,
    DateTime? lastSync,
    String? lastError,
    bool? isHealthy,
  }) {
    return ServiceState(
      isInitialized: isInitialized ?? this.isInitialized,
      lastSync: lastSync ?? this.lastSync,
      lastError: lastError ?? this.lastError,
      isHealthy: isHealthy ?? this.isHealthy,
    );
  }
}

class ArrayValidationResult {
  final bool isValid;
  final String? error;
  final List<int>? correctedArray;
  final bool needsRecover;

  const ArrayValidationResult({
    required this.isValid,
    this.error,
    this.correctedArray,
    this.needsRecover = false,
  });

  factory ArrayValidationResult.valid([List<int>? array]) {
    return ArrayValidationResult(
      isValid: true,
      correctedArray: array,
    );
  }

  factory ArrayValidationResult.invalid(String error, {bool needsRecover = false}) {
    return ArrayValidationResult(
      isValid: false,
      error: error,
      needsRecover: needsRecover,
    );
  }
}

// Add at the top with other type definitions
typedef ServiceCallback = void Function(String field, dynamic value);

// Add after existing enums/classes
class ServiceCallbacks {
  final ServiceCallback? onBadgeUpdate;
  final ServiceCallback? onBannerUpdate;
  final ServiceCallback? onAvatarUpdate;

  const ServiceCallbacks({
    this.onBadgeUpdate,
    this.onBannerUpdate,
    this.onAvatarUpdate,
  });
}

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BannerService _bannerService;

  // At top of UserProfileService class
  static const List<String> ARRAY_FIELDS = [
    'unlockedBadge',
    'unlockedBanner',
    'badgeShowcase'
  ];

  static const List<String> UNLOCK_ARRAYS = [
    'unlockedBadge',
    'unlockedBanner'
  ];
  
  // Cache constants
    // Add these constants at the top of UserProfileService
  static const int CURRENT_PROFILE_VERSION = 1;  // Increment this when profile structure changes
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

  void _initializeService() async {
    try {
      
      // 1. Version check first
      await _validateProfileVersion();
      
      // 2. Setup connectivity listener
      Connectivity().onConnectivityChanged.listen((result) {
        if (result != ConnectivityResult.none) {
          _syncPendingUpdates();
        }
      });

      // 3. Setup Firestore listeners
      _setupFirestoreListeners();

      // 4. Initialize service integrations
      await initializeIntegrations();

    } catch (e) {
      // Don't rethrow as this is called in constructor
    }
  }

  Future<UserProfile?> fetchUserProfile() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      String userId = user.uid;

      // Check memory cache first
      if (_profileCache.containsKey(userId) && _isCacheValid(userId)) {
        return _profileCache[userId];
      }

      // Check local storage
      UserProfile? localProfile = await _getProfileFromLocal(userId);
      if (localProfile != null) {
        _updateCache(userId, localProfile);
        return localProfile;
      }

      // Try to fetch from server if online
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
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
          _bannerService.updateCurrentProfile(profile);
          return profile;
        }
      }

      // If we get here, create a new profile with default values
      UserProfile newProfile = await _createDefaultProfile(userId);
      await _saveProfileLocally(userId, newProfile);
      _updateCache(userId, newProfile);
      return newProfile;

    } catch (e) {
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
      'minLength': 1,
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
  
  // Add batch update method
  Future<void> batchUpdateProfile(Map<String, dynamic> updates) async {
    try {

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
      bool isXPUpdate = updates.containsKey('exp');

      if (isXPUpdate) {
        
        // 1. Calculate current total XP
        int currentTotalXP = 0;
        for (int i = 1; i < currentProfile.level; i++) {
          currentTotalXP += i * 100;  // Add up XP required for previous levels
        }
        currentTotalXP += currentProfile.exp;  // Add current level's XP

        // 2. Add new XP gain
        int xpGain = updates['exp'] as int;
        int newTotalXP = currentTotalXP + xpGain;

        // 3. Calculate new level and exp
        int remainingXP = newTotalXP;
        int newLevel = 1;
        
        // Keep checking if we have enough XP for next level
        while (remainingXP >= (newLevel * 100)) {
          remainingXP -= newLevel * 100;
          newLevel++;
        }

        int newExp = remainingXP;
        int newExpCap = newLevel * 100;


        // Check for banner unlocks on level up
        if (newLevel > currentProfile.level || currentProfile.unlockedBanner[0] != 1) {
          
          List<int> newUnlockedBanner = List<int>.from(currentProfile.unlockedBanner);
          for (int i = 0; i < newLevel && i < newUnlockedBanner.length; i++) {
            newUnlockedBanner[i] = 1;
          }
          
          updates['unlockedBanner'] = newUnlockedBanner;
        }

        // Update the updates map with new XP values
        updates.addAll({
          'exp': newExp,
          'level': newLevel,
          'expCap': newExpCap,
        });
      }

      // Apply updates locally
      UserProfile updatedProfile = currentProfile.copyWith(updates: updates);
      await _saveProfileLocally(userId, updatedProfile);
      _updateCache(userId, updatedProfile);
      _profileUpdateController.add(updatedProfile);

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
      } else {
        _queueUpdate(userId, updates);
      }


    } catch (e) {
      await _logOperation('batch_update_error', e.toString());
      throw Exception('Failed to update profile: $e');
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

  final AvatarService _avatarService = AvatarService();

  // Add integration methods
  Future<void> initializeIntegrations() async {
    try {
      
      // Initialize service states
      _updateServiceState(BADGE_SERVICE, isInitialized: true);
      _updateServiceState(BANNER_SERVICE, isInitialized: true);
      _updateServiceState(AVATAR_SERVICE, isInitialized: true);

      // Initial sync
      UserProfile? profile = await fetchUserProfile();
      if (profile != null) {
        await synchronizeServices();
      }

    } catch (e) {
      await _logProfileUpdate(
        field: 'initialization',
        oldValue: 'error',
        newValue: 'failed',
        details: 'Integration initialization failed: $e',
      );
    }
  }

  // Add these fields after existing ones
  final Map<String, ServiceCallback> _serviceCallbacks = {};
  final Map<String, DateTime> _lastServiceSync = {};
  
  static const String BADGE_SERVICE = 'badge_service';
  static const String BANNER_SERVICE = 'banner_service';
  static const String AVATAR_SERVICE = 'avatar_service';

  // Add registration methods
  void registerServiceCallback(String service, ServiceCallback callback) {
    _serviceCallbacks[service] = callback;
    _lastServiceSync[service] = DateTime.now();
  }

  void unregisterServiceCallback(String service) {
    _serviceCallbacks.remove(service);
    _lastServiceSync.remove(service);
    _updateServiceState(service, isInitialized: true);  // Add this
  }

  // Add notification method
  Future<void> notifyServices(String field, dynamic value) async {

    try {
      // Determine which service to notify based on field
      String? targetService = switch (field) {
        'unlockedBadge' => BADGE_SERVICE,
        'unlockedBanner' => BANNER_SERVICE,
        'avatarId' => AVATAR_SERVICE,
        _ => null,
      };

      if (targetService != null && _serviceCallbacks.containsKey(targetService)) {
        await Future.microtask(() {
          _serviceCallbacks[targetService]?.call(field, value);
        });
        _lastServiceSync[targetService] = DateTime.now();
      }

    } catch (e) {
      await _logProfileUpdate(
        field: field,
        oldValue: 'notification_error',
        newValue: value,
        details: 'Service notification failed: $e',
      );
    }
  }

  // Update updateProfileWithIntegration to use service notification
  Future<void> updateProfileWithIntegration(String field, dynamic value) async {
    try {

      // 1. Get current profile
      UserProfile? currentProfile = await fetchUserProfile();
      if (currentProfile == null) {
        throw Exception('No profile available for update');
      }

      // 2. For avatar updates, ensure the avatar is cached
      if (field == 'avatarId') {
        final avatar = await _avatarService.getAvatarDetails(
          value as int,
          priority: LoadPriority.CRITICAL
        );
        if (avatar == null) {
          throw Exception('Avatar not found');
        }
      }

      // 3. Apply updates locally first
      User? user = _auth.currentUser;
      if (user == null) return;
      
      final updates = {field: value};
      UserProfile updatedProfile = currentProfile.copyWith(updates: updates);
      
      await _saveProfileLocally(user.uid, updatedProfile);
      _updateCache(user.uid, updatedProfile);
      
      _profileUpdateController.add(updatedProfile);

      // 4. Update Firestore if online
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        await _retryOperation(() async {
          await _firestore
              .collection('User')
              .doc(user.uid)
              .collection('ProfileData')
              .doc(user.uid)
              .update(updates);
        });
        
        // Notify services only when online
        await notifyServices(field, value);
      } else {
        // Queue update for later sync
        _queueUpdate(user.uid, updates);
      }


      // Add this: Update total badge count when badges change
      if (field == 'unlockedBadge') {
        await updateTotalBadgeCount();
      }
    } catch (e) {
      await _logOperation('profile_update_error', e.toString());
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _prepareProfileUpdate({
    required String field,
    required dynamic value,
    required UserProfile currentProfile,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      // Handle array fields
      if (ARRAY_FIELDS.contains(field)) {
        if (value is! List<int>) {
          throw Exception('Invalid array value for $field');
        }

        // Get current array based on field
        List<int> currentArray;
        switch (field) {
          case 'unlockedBadge':
            currentArray = currentProfile.unlockedBadge;
            break;
          case 'unlockedBanner':
            currentArray = currentProfile.unlockedBanner;
            break;
          case 'badgeShowcase':
            currentArray = currentProfile.badgeShowcase;
            break;
          default:
            throw Exception('Unknown array field: $field');
        }

        // Validate array update
        final validationResult = _validateArrayUpdate(
          field: field,
          newArray: value,
          currentArray: currentArray,
        );

        if (!validationResult.isValid) {
          if (validationResult.needsRecover) {
            // Handle recovery if needed
            throw Exception('Array validation failed: ${validationResult.error}');
          }
          // Use corrected array if provided
          updates[field] = validationResult.correctedArray ?? currentArray;
        } else {
          // For unlock arrays, merge with existing
          if (UNLOCK_ARRAYS.contains(field)) {
            updates[field] = _mergeUnlockArrays(
              current: currentArray,
              update: value,
            );
          } else {
            // For other arrays (like badgeShowcase), use new value directly
            updates[field] = value;
          }
        }
      } else {
        // Non-array field - preserve existing arrays
        updates = {
          field: value,
          'unlockedBadge': currentProfile.unlockedBadge,
          'unlockedBanner': currentProfile.unlockedBanner,
          'badgeShowcase': currentProfile.badgeShowcase,
        };
      }

      return updates;
    } catch (e) {
      rethrow;
    }
  }

  ArrayValidationResult _validateArrayUpdate({
    required String field,
    required List<int> newArray,
    required List<int> currentArray,
  }) {
    try {

      // Common validations for all arrays
      if (newArray.isEmpty) {
        return ArrayValidationResult.invalid('Array cannot be empty');
      }

      // Specific validations based on array type
      if (UNLOCK_ARRAYS.contains(field)) {
        return _validateUnlockArray(
          field: field,
          newArray: newArray,
          currentArray: currentArray,
        );
      } else if (field == 'badgeShowcase') {
        return _validateBadgeShowcase(
          newArray: newArray,
          currentArray: currentArray,
        );
      }

      return ArrayValidationResult.invalid(
        'Unknown array field: $field',
        needsRecover: true
      );
    } catch (e) {
      return ArrayValidationResult.invalid(
        'Validation error: $e',
        needsRecover: true
      );
    }
  }

  ArrayValidationResult _validateUnlockArray({
    required String field,
    required List<int> newArray,
    required List<int> currentArray,
  }) {

    // 1. Size validation
    if (newArray.length != currentArray.length) {
      return ArrayValidationResult.invalid(
        'Array size mismatch',
        needsRecover: true
      );
    }

    // 2. Value validation (must be 0 or 1)
    if (!newArray.every((value) => value == 0 || value == 1)) {
      return ArrayValidationResult.invalid('Array must contain only 0s and 1s');
    }

    // 3. Unlock preservation (cannot change 1 to 0)
    List<int> correctedArray = List<int>.from(newArray);
    bool needsCorrection = false;

    for (int i = 0; i < currentArray.length; i++) {
      if (currentArray[i] == 1 && newArray[i] == 0) {
        correctedArray[i] = 1;
        needsCorrection = true;
      }
    }

    if (needsCorrection) {
      return ArrayValidationResult.valid(correctedArray);
    }

    return ArrayValidationResult.valid(newArray);
  }

  ArrayValidationResult _validateBadgeShowcase({
    required List<int> newArray,
    required List<int> currentArray,
  }) {

    // 1. Size validation (must be exactly 3)
    if (newArray.length != 3) {
      return ArrayValidationResult.invalid('Showcase must have exactly 3 slots');
    }

    // 2. Value validation (-1 or valid badge id)
    if (!newArray.every((value) => value >= -1)) {
      return ArrayValidationResult.invalid('Invalid badge IDs in showcase');
    }

    // 3. Check for duplicates (except -1)
    final validBadges = newArray.where((id) => id != -1).toList();
    if (validBadges.toSet().length != validBadges.length) {
      return ArrayValidationResult.invalid('Duplicate badges not allowed');
    }

    return ArrayValidationResult.valid(newArray);
  }

  List<int> _mergeUnlockArrays({
    required List<int> current,
    required List<int> update,
  }) {

    // Create new array preserving all unlocks
    List<int> merged = List<int>.filled(current.length, 0);
    for (int i = 0; i < current.length; i++) {
      // Keep unlock if either array has it
      merged[i] = current[i] | (i < update.length ? update[i] : 0);
    }

    return merged;
  }

  Future<void> _logProfileUpdate({
    required String field,
    required dynamic oldValue,
    required dynamic newValue,
    String? details,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (details != null) {
      }

      // Get user info for context
      User? user = _auth.currentUser;
      String userId = user?.uid ?? 'unknown';

      // Create detailed log entry
      Map<String, dynamic> logEntry = {
        'type': 'profile_update',
        'userId': userId,
        'field': field,
        'oldValue': oldValue.toString(),
        'newValue': newValue.toString(),
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'isArrayField': ARRAY_FIELDS.contains(field),
        'metadata': {
          ...?metadata,
          'platform': 'mobile',
          'version': await _getAppVersion(),
          if (ARRAY_FIELDS.contains(field)) ...{
            'arraySize': (newValue as List).length,
            'isUnlockArray': UNLOCK_ARRAYS.contains(field),
          },
        },
      };

      // Store in Firestore
      await _firestore
          .collection('Logs')
          .doc(userId)
          .collection('profile_updates')
          .add(logEntry);

    } catch (e) {
    }
  }

  Future<String> _getAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return 'unknown';
    }
  }

  Future<Map<String, dynamic>> _recoverProfileUpdate({
    required String field,
    required UserProfile currentProfile,
    String? error,
  }) async {
    try {

      // 1. Try to restore from backup first
      UserProfile? backupProfile = await _getProfileBackup();
      if (backupProfile != null) {
        return {
          field: switch (field) {
            'unlockedBadge' => backupProfile.unlockedBadge,
            'unlockedBanner' => backupProfile.unlockedBanner,
            'badgeShowcase' => backupProfile.badgeShowcase,
            _ => currentProfile.toMap()[field],
          },
          // Always preserve arrays in recovery
          'unlockedBadge': backupProfile.unlockedBadge,
          'unlockedBanner': backupProfile.unlockedBanner,
          'badgeShowcase': backupProfile.badgeShowcase,
        };
      }

      // 2. If no backup, try to repair arrays
      if (ARRAY_FIELDS.contains(field)) {
        return await _repairArrayField(field, currentProfile);
      }

      // 3. Last resort: Reset to safe defaults
      return _getSafeDefaults(field, currentProfile);
    } catch (e) {
      throw Exception('Profile recovery failed: $e');
    }
  }

  Future<Map<String, dynamic>> _repairArrayField(
    String field,
    UserProfile currentProfile,
  ) async {
    
    switch (field) {
      case 'unlockedBadge':
        final badges = await BadgeService().fetchBadges();
        await updateTotalBadgeCount();  // Add this
        return {
          'unlockedBadge': List<int>.filled(badges.length, 0),
          'unlockedBanner': currentProfile.unlockedBanner,
          'badgeShowcase': [-1, -1, -1],
        };

      case 'unlockedBanner':
        final banners = await BannerService().fetchBanners();
        return {
          'unlockedBadge': currentProfile.unlockedBadge,
          'unlockedBanner': List<int>.filled(banners.length, 0),
          'badgeShowcase': currentProfile.badgeShowcase,
        };

      case 'badgeShowcase':
        return {
          'unlockedBadge': currentProfile.unlockedBadge,
          'unlockedBanner': currentProfile.unlockedBanner,
          'badgeShowcase': [-1, -1, -1],
        };

      default:
        throw Exception('Unknown array field: $field');
    }
  }

  Map<String, dynamic> _getSafeDefaults(String field, UserProfile currentProfile) {
    return {
      field: switch (field) {
        'avatarId' => 0,
        'bannerId' => 0,
        'unlockedBadge' => currentProfile.unlockedBadge,
        'unlockedBanner' => currentProfile.unlockedBanner,
        'badgeShowcase' => [-1, -1, -1],
        _ => currentProfile.toMap()[field],
      },
      // Always preserve arrays
      'unlockedBadge': currentProfile.unlockedBadge,
      'unlockedBanner': currentProfile.unlockedBanner,
      'badgeShowcase': currentProfile.badgeShowcase,
    };
  }

  Future<UserProfile?> _getProfileBackup() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? backupJson = prefs.getString(PROFILE_BACKUP_KEY);
      if (backupJson != null) {
        return UserProfile.fromMap(jsonDecode(backupJson));
      }
    } catch (e) {
    }
    return null;
  }

  Future<void> synchronizeServices() async {
    try {
      
      // Get current profile
      UserProfile? profile = await fetchUserProfile();
      if (profile == null) {
        throw Exception('No profile available for sync');
      }

      // Validate states across services
      await validateServiceStates();

      // Sync each service
      await Future.wait([
        _syncBadgeService(profile),
        _syncBannerService(profile),
        _syncAvatarService(profile),
      ]);

    } catch (e) {
      await _logProfileUpdate(
        field: 'service_sync',
        oldValue: 'sync_error',
        newValue: 'failed',
        details: 'Service sync failed: $e',
      );
    }
  }

  Future<void> validateServiceStates() async {
    try {
      
      // Check each service's last sync time
      for (var entry in _lastServiceSync.entries) {
        final timeSinceSync = DateTime.now().difference(entry.value);
        if (timeSinceSync > const Duration(minutes: 30)) {
          await handleServiceConflicts(entry.key);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> handleServiceConflicts(String service) async {
    try {
      
      UserProfile? profile = await fetchUserProfile();
      if (profile == null) return;

      switch (service) {
        case BADGE_SERVICE:
          await _resolveBadgeConflicts(profile);
          break;
        case BANNER_SERVICE:
          await _resolveBannerConflicts(profile);
          break;
        case AVATAR_SERVICE:
          await _resolveAvatarConflicts(profile);
          break;
      }
    } catch (e) {
      await handleServiceError(service, 'Conflict resolution failed: $e');
    }
  }

  Future<void> _syncBadgeService(UserProfile profile) async {
    try {
      if (_serviceCallbacks.containsKey(BADGE_SERVICE)) {
        _serviceCallbacks[BADGE_SERVICE]!('unlockedBadge', profile.unlockedBadge);
        _lastServiceSync[BADGE_SERVICE] = DateTime.now();
      } 
      _updateServiceState(BADGE_SERVICE,
        lastSync: DateTime.now(),
        isHealthy: true
      ); 
    } catch (e) {
      await handleBadgeServiceError('Sync failed: $e');
    }
  }

  Future<void> handleServiceError(String service, String error) async {

    try {
      switch (service) {
        case BADGE_SERVICE:
          await handleBadgeServiceError(error);
          break;
        case BANNER_SERVICE:
          await handleBannerServiceError(error);
          break;
        case AVATAR_SERVICE:
          await handleAvatarServiceError(error);
          break;
      }

      _updateServiceState(service, 
        isHealthy: false,
        lastError: error
      ); 
      
      await _autoRecoverProfile();  // Attempt recovery after error

    } catch (e) {
      await _logProfileUpdate(
        field: 'service_error',
        oldValue: service,
        newValue: 'error',
        details: 'Error handler failed: $e',
      );
    }
  }

  Future<void> handleBadgeServiceError(String error) async {
    try {
      
      // 1. Log the error
      await _logProfileUpdate(
        field: 'badge_service',
        oldValue: 'error',
        newValue: 'recovery',
        details: error,
      );

      // 2. Get current profile
      UserProfile? profile = await fetchUserProfile();
      if (profile == null) return;

      // 3. Validate badge array
      final badges = await BadgeService().fetchBadges();
      if (profile.unlockedBadge.length != badges.length) {
        // Fix array size
        List<int> newUnlockedBadge = List<int>.filled(badges.length, 0);
        for (int i = 0; i < profile.unlockedBadge.length && i < badges.length; i++) {
          newUnlockedBadge[i] = profile.unlockedBadge[i];
        }
        await updateProfileWithIntegration('unlockedBadge', newUnlockedBadge);
      }

      // 4. Reset showcase if needed
      if (profile.badgeShowcase.any((id) => id >= badges.length)) {
        await updateProfileWithIntegration('badgeShowcase', [-1, -1, -1]);
      }
    } catch (e) {
    }
  }

  Future<void> handleBannerServiceError(String error) async {
    try {
      
      // Similar to badge error handling but for banners
      await _logProfileUpdate(
        field: 'banner_service',
        oldValue: 'error',
        newValue: 'recovery',
        details: error,
      );

      UserProfile? profile = await fetchUserProfile();
      if (profile == null) return;

      final banners = await BannerService().fetchBanners();
      if (profile.unlockedBanner.length != banners.length) {
        List<int> newUnlockedBanner = List<int>.filled(banners.length, 0);
        for (int i = 0; i < profile.unlockedBanner.length && i < banners.length; i++) {
          newUnlockedBanner[i] = profile.unlockedBanner[i];
        }
        await updateProfileWithIntegration('unlockedBanner', newUnlockedBanner);
      }

      // Reset banner if invalid
      if (profile.bannerId >= banners.length) {
        await updateProfileWithIntegration('bannerId', 0);
      }
    } catch (e) {
    }
  }

  Future<void> handleAvatarServiceError(String error) async {
    try {
      
      await _logProfileUpdate(
        field: 'avatar_service',
        oldValue: 'error',
        newValue: 'recovery',
        details: error,
      );

      UserProfile? profile = await fetchUserProfile();
      if (profile == null) return;

      // Validate current avatar
      if (!await AvatarService().getAvatarById(profile.avatarId)) {
        await updateProfileWithIntegration('avatarId', 0);
      }
    } catch (e) {
    }
  }

  Future<void> _syncBannerService(UserProfile profile) async {
  try {
    if (_serviceCallbacks.containsKey(BANNER_SERVICE)) {
      _serviceCallbacks[BANNER_SERVICE]?.call('unlockedBanner', profile.unlockedBanner);
      _lastServiceSync[BANNER_SERVICE] = DateTime.now();
    }
  } catch (e) {
    await handleBannerServiceError('Sync failed: $e');
  }
}

Future<void> _syncAvatarService(UserProfile profile) async {
  try {
    if (_serviceCallbacks.containsKey(AVATAR_SERVICE)) {
      _serviceCallbacks[AVATAR_SERVICE]?.call('avatarId', profile.avatarId);
      _lastServiceSync[AVATAR_SERVICE] = DateTime.now();
    }
  } catch (e) {
    await handleAvatarServiceError('Sync failed: $e');
  }
}

Future<void> _resolveBadgeConflicts(UserProfile profile) async {
  try {
    final badges = await BadgeService().fetchBadges();
    
    // Check array size
    if (profile.unlockedBadge.length != badges.length) {
      await handleBadgeServiceError('Array size mismatch');
      return;
    }

    // Validate showcase
    if (profile.badgeShowcase.any((id) => id >= badges.length)) {
      await handleBadgeServiceError('Invalid showcase badges');
    }
  } catch (e) {
    rethrow;
  }
}

Future<void> _resolveBannerConflicts(UserProfile profile) async {
  try {
    final banners = await BannerService().fetchBanners();
    
    // Check array size
    if (profile.unlockedBanner.length != banners.length) {
      await handleBannerServiceError('Array size mismatch');
      return;
    }

    // Validate current banner
    if (profile.bannerId >= banners.length) {
      await handleBannerServiceError('Invalid banner selection');
    }
  } catch (e) {
    rethrow;
  }
}

Future<void> _resolveAvatarConflicts(UserProfile profile) async {
  try {
    if (!await AvatarService().getAvatarById(profile.avatarId)) {
      await handleAvatarServiceError('Invalid avatar selection');
    }
  } catch (e) {
    rethrow;
  }
}

// Add to UserProfileService class
final Map<String, ServiceState> _serviceStates = {
  BADGE_SERVICE: ServiceState(
    isInitialized: false,
    lastSync: DateTime.now(),
  ),
  BANNER_SERVICE: ServiceState(
    isInitialized: false,
    lastSync: DateTime.now(),
  ),
  AVATAR_SERVICE: ServiceState(
    isInitialized: false,
    lastSync: DateTime.now(),
  ),
};

void _updateServiceState(String service, {
  bool? isInitialized,
  DateTime? lastSync,
  String? lastError,
  bool? isHealthy,
}) {
  final currentState = _serviceStates[service];
  if (currentState != null) {
    _serviceStates[service] = currentState.copyWith(
      isInitialized: isInitialized,
      lastSync: lastSync,
      lastError: lastError,
      isHealthy: isHealthy,
    );
  }
}

ServiceState? getServiceState(String service) {
  return _serviceStates[service];
}

// Add these methods to UserProfileService
Future<void> _storeProfileVersion() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PROFILE_VERSION_KEY, CURRENT_PROFILE_VERSION);
  } catch (e) {
    await _logProfileUpdate(
      field: 'version',
      oldValue: 'unknown',
      newValue: CURRENT_PROFILE_VERSION,
      details: 'Version storage failed: $e',
    );
  }
}

Future<void> _validateProfileVersion() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getInt(PROFILE_VERSION_KEY) ?? 0;
    

    if (storedVersion < CURRENT_PROFILE_VERSION) {
      await _migrateProfile(fromVersion: storedVersion);
    }
  } catch (e) {
    await _logProfileUpdate(
      field: 'version_check',
      oldValue: 'error',
      newValue: 'failed',
      details: 'Version validation failed: $e',
    );
  }
}

Future<void> _migrateProfile({required int fromVersion}) async {
  try {

    // Get current profile
    UserProfile? profile = await fetchUserProfile();
    if (profile == null) {
      throw Exception('No profile available for migration');
    }

    // Apply migrations sequentially
    for (int version = fromVersion + 1; version <= CURRENT_PROFILE_VERSION; version++) {
      await _applyMigration(profile, version);
    }

    await updateTotalStagesCleared();  // Add this after migrations
    
    // Store new version
    await _storeProfileVersion();

  } catch (e) {
    await _logProfileUpdate(
      field: 'migration',
      oldValue: fromVersion.toString(),
      newValue: CURRENT_PROFILE_VERSION.toString(),
      details: 'Migration failed: $e',
    );
    rethrow;
  }
}

Future<void> _applyMigration(UserProfile profile, int toVersion) async {
  
  switch (toVersion) {
    case 1:
      await _migrateToV1(profile);
      break;
    // Add cases for future versions
    default:
  }
}

Future<void> _migrateToV1(UserProfile profile) async {
  try {
    
    // Example migration: Ensure arrays have correct sizes
    final badges = await BadgeService().fetchBadges();
    final banners = await BannerService().fetchBanners();

    Map<String, dynamic> updates = {};
    bool needsUpdate = false;

    // Check badge array
    if (profile.unlockedBadge.length != badges.length) {
      List<int> newUnlockedBadge = List<int>.filled(badges.length, 0);
      for (int i = 0; i < profile.unlockedBadge.length && i < badges.length; i++) {
        newUnlockedBadge[i] = profile.unlockedBadge[i];
      }
      updates['unlockedBadge'] = newUnlockedBadge;
      needsUpdate = true;
    }

    // Check banner array
    if (profile.unlockedBanner.length != banners.length) {
      List<int> newUnlockedBanner = List<int>.filled(banners.length, 0);
      for (int i = 0; i < profile.unlockedBanner.length && i < banners.length; i++) {
        newUnlockedBanner[i] = profile.unlockedBanner[i];
      }
      updates['unlockedBanner'] = newUnlockedBanner;
      needsUpdate = true;
    }

    // Apply updates if needed
    if (needsUpdate) {
      await batchUpdateProfile(updates);
    }

  } catch (e) {
    rethrow;
  }
}

// Add these constants at the top of UserProfileService
static const int MAX_RECOVERY_ATTEMPTS = 3;
static const Duration RECOVERY_COOLDOWN = Duration(minutes: 30);

// Add to UserProfileService class
Future<void> _autoRecoverProfile() async {
  try {
    
    // Check if we should attempt recovery
    if (!await _shouldAttemptRecovery()) {
      return;
    }

    // Get current profile
    UserProfile? profile = await fetchUserProfile();
    if (profile == null) {
      throw Exception('No profile available for recovery');
    }

    // Validate profile integrity
    final validationResult = await _validateProfileIntegrity(profile);
    if (!validationResult.isValid) {
      await _repairProfileData(profile, validationResult.error);
    }

    // Log recovery attempt
    await _logRecoveryAttempt(
      success: true,
      details: 'Auto recovery completed successfully'
    );

  } catch (e) {
    await _logRecoveryAttempt(
      success: false,
      details: 'Auto recovery failed: $e'
    );
  }
}

Future<ValidationResult> _validateProfileIntegrity(UserProfile profile) async {
  try {

    // 1. Check array sizes
    final badges = await BadgeService().fetchBadges();
    final banners = await BannerService().fetchBanners();

    if (profile.unlockedBadge.length != badges.length) {
      return const ValidationResult(
        isValid: false,
        error: 'Badge array size mismatch'
      );
    }

    if (profile.unlockedBanner.length != banners.length) {
      return const ValidationResult(
        isValid: false,
        error: 'Banner array size mismatch'
      );
    }

    // 2. Check showcase validity
    if (profile.badgeShowcase.length != 3) {
      return const ValidationResult(
        isValid: false,
        error: 'Invalid showcase size'
      );
    }

    // 3. Check avatar and banner validity
    if (!await AvatarService().getAvatarById(profile.avatarId)) {
      return const ValidationResult(
        isValid: false,
        error: 'Invalid avatar ID'
      );
    }

    if (!await BannerService().getBannerById(profile.bannerId)) {
      return const ValidationResult(
        isValid: false,
        error: 'Invalid banner ID'
      );
    }

    return const ValidationResult(isValid: true);
  } catch (e) {
    return ValidationResult(
      isValid: false,
      error: 'Validation error: $e'
    );
  }
}

Future<void> _repairProfileData(UserProfile profile, String? error) async {
  try {

    Map<String, dynamic> updates = {};
    bool needsUpdate = false;

    // Fix arrays if needed
    if (error?.contains('array size') ?? false) {
      final badges = await BadgeService().fetchBadges();
      final banners = await BannerService().fetchBanners();

      updates['unlockedBadge'] = List<int>.filled(badges.length, 0);
      updates['unlockedBanner'] = List<int>.filled(banners.length, 0);
      needsUpdate = true;
    }

    // Fix showcase if needed
    if (error?.contains('showcase') ?? false) {
      updates['badgeShowcase'] = [-1, -1, -1];
      needsUpdate = true;
    }

    // Fix avatar if needed
    if (error?.contains('avatar') ?? false) {
      updates['avatarId'] = 0;
      needsUpdate = true;
    }

    // Fix banner if needed
    if (error?.contains('banner') ?? false) {
      updates['bannerId'] = 0;
      needsUpdate = true;
    }

    // Apply updates if needed
    if (needsUpdate) {
      await batchUpdateProfile(updates);
    }

  } catch (e) {
    rethrow;
  }
}

Future<bool> _shouldAttemptRecovery() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Check attempt count
    int attempts = prefs.getInt('recovery_attempts') ?? 0;
    if (attempts >= MAX_RECOVERY_ATTEMPTS) {
      return false;
    }

    // Check cooldown
    String? lastAttemptStr = prefs.getString('last_recovery_attempt');
    if (lastAttemptStr != null) {
      DateTime lastAttempt = DateTime.parse(lastAttemptStr);
      if (DateTime.now().difference(lastAttempt) < RECOVERY_COOLDOWN) {
        return false;
      }
    }

    return true;
  } catch (e) {
    return false;
  }
}

// Add these constants at top of UserProfileService
static const String RECOVERY_ATTEMPTS_KEY = 'recovery_attempts';
static const String LAST_RECOVERY_KEY = 'last_recovery_attempt';
static const String RECOVERY_LOGS_KEY = 'recovery_logs';

// Add to UserProfileService class
Future<void> _logRecoveryAttempt({
  required bool success,
  required String details,
  Map<String, dynamic>? metadata,
}) async {
  try {

    // Get user info
    User? user = _auth.currentUser;
    String userId = user?.uid ?? 'unknown';

    // Create recovery log entry
    Map<String, dynamic> logEntry = {
      'type': 'profile_recovery',
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
      'success': success,
      'details': details,
      'metadata': {
        ...?metadata,
        'version': await _getAppVersion(),
        'recoveryAttempts': await _getRecoveryAttempts(),
      },
    };

    // Store in Firestore
    await _firestore
        .collection('Logs')
        .doc(userId)
        .collection('recovery_attempts')
        .add(logEntry);

    // Update local tracking
    await _trackRecoverySuccess(success);

  } catch (e) {
  }
}

Future<void> _trackRecoverySuccess(bool success) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Update attempt count
    int attempts = prefs.getInt(RECOVERY_ATTEMPTS_KEY) ?? 0;
    await prefs.setInt(RECOVERY_ATTEMPTS_KEY, attempts + 1);

    // Update last attempt timestamp
    await prefs.setString(
      LAST_RECOVERY_KEY,
      DateTime.now().toIso8601String()
    );

    // Store success/failure stats
    List<String> logs = prefs.getStringList(RECOVERY_LOGS_KEY) ?? [];
    logs.add(jsonEncode({
      'timestamp': DateTime.now().toIso8601String(),
      'success': success,
    }));

    // Keep only last 10 logs
    if (logs.length > 10) {
      logs = logs.sublist(logs.length - 10);
    }
    
    await prefs.setStringList(RECOVERY_LOGS_KEY, logs);
    

  } catch (e) {
  }
}

Future<int> _getRecoveryAttempts() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(RECOVERY_ATTEMPTS_KEY) ?? 0;
  } catch (e) {
    return 0;
  }
}

Future<List<Map<String, dynamic>>> getRecoveryHistory() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList(RECOVERY_LOGS_KEY) ?? [];
    
    return logs.map((log) => 
      Map<String, dynamic>.from(jsonDecode(log))
    ).toList();
  } catch (e) {
    return [];
  }
}

Future<void> resetRecoveryTracking() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(RECOVERY_ATTEMPTS_KEY);
    await prefs.remove(LAST_RECOVERY_KEY);
    await prefs.remove(RECOVERY_LOGS_KEY);
  } catch (e) {
  }
}

Future<void> updateTotalStagesCleared() async {
  try {
    User? user = _auth.currentUser;
    if (user == null) return;

    // Get current profile
    UserProfile? profile = await fetchUserProfile();
    if (profile == null) return;

    // Get all categories' game save data
    List<String> categories = ['Quake', 'Storm', 'Volcanic', 'Drought', 'Tsunami', 'Flood'];
    int totalCleared = 0;

    // Check each category's stages from local storage first
    for (String category in categories) {
      
      // Try to get local save data first
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? saveDataJson = prefs.getString('game_save_data_$category');
      
      GameSaveData? saveData;
      
      if (saveDataJson != null) {
        // Use local data if available
        Map<String, dynamic> data = jsonDecode(saveDataJson);
        saveData = GameSaveData.fromMap(data);
      } else {
        // Fallback to Firestore if online
        var connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          DocumentSnapshot doc = await _firestore
              .collection('User')
              .doc(user.uid)
              .collection('GameSaveData')
              .doc(category)
              .get();

          if (doc.exists) {
            saveData = GameSaveData.fromMap(doc.data() as Map<String, dynamic>);
          }
        }
      }

      if (saveData != null) {
        // Count stages with stars > 0 in both modes separately
        List<int> normalStars = saveData.normalStageStars;
        List<int> hardStars = saveData.hardStageStars;

        // Count stages that are cleared in each mode
        for (int i = 0; i < normalStars.length; i++) {
          // Count normal mode clears
          if (normalStars[i] > 0) {
            totalCleared++;
          }
          
          // Count hard mode clears
          if (hardStars[i] > 0) {
            totalCleared++;
          }
        }
      }
    }


    // Update locally first
    UserProfile updatedProfile = profile.copyWith(
      totalStageCleared: totalCleared
    );

    await _saveProfileLocally(user.uid, updatedProfile);
    _updateCache(user.uid, updatedProfile);

    // Update Firebase if online
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      await _firestore
          .collection('User')
          .doc(user.uid)
          .collection('ProfileData')
          .doc(user.uid)
          .update({'totalStageCleared': totalCleared});
    }

  } catch (e) {
  }
}

// Add this method to update total badge count
Future<void> updateTotalBadgeCount() async {
  try {
    User? user = _auth.currentUser;
    if (user == null) return;

    // Get current profile using fetchUserProfile() instead of getUserProfile()
    UserProfile? profile = await fetchUserProfile();
    if (profile == null) return;

    // Count badges
    int totalBadges = profile.unlockedBadge.where((value) => value == 1).length;

    // Update locally first
    UserProfile updatedProfile = profile.copyWith(
      totalBadgeUnlocked: totalBadges
    );

    // Use _saveProfileLocally() and _addToCache() which are internal methods
    await _saveProfileLocally(user.uid, updatedProfile);
    _updateCache(user.uid, updatedProfile);

    // Update Firebase if online
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      await _firestore
          .collection('User')
          .doc(user.uid)
          .collection('ProfileData')
          .doc(user.uid)
          .update({'totalBadgeUnlocked': totalBadges});
    }
  } catch (e) {
  }
}
}