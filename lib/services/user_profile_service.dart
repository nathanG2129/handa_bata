// lib/services/user_profile_service.dart

import 'package:handabatamae/models/user_model.dart';
import 'package:handabatamae/services/auth_service.dart';

class UserProfileService {
  final AuthService _authService = AuthService();

  Future<UserProfile?> fetchUserProfile() async {
    return await _authService.getUserProfile();
  }
}