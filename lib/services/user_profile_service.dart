// lib/services/user_profile_service.dart

import 'dart:async';
import 'package:handabatamae/models/user_model.dart';
import 'package:handabatamae/services/auth_service.dart';

class UserProfileService {
  final AuthService _authService = AuthService();
  
  // Add a stream controller for avatar updates
  final _avatarController = StreamController<int>.broadcast();
  Stream<int> get avatarStream => _avatarController.stream;

  // Singleton pattern
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  Future<UserProfile?> fetchUserProfile() async {
    return await _authService.getUserProfile();
  }

  // Method to update avatar
  void updateAvatar(int newAvatarId) {
    _avatarController.add(newAvatarId);
  }

  void dispose() {
    _avatarController.close();
  }
}