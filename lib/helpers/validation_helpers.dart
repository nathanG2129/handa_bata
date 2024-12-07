// lib/helpers/validation_helpers.dart

import '../localization/validation/localization.dart';
import '../utils/profanity_filter.dart';

String? validateEmail(String? value, String language) {
  if (value == null || value.isEmpty) {
    return ValidationLocalization.translate('required_email', language);
  }
  final RegExp emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  if (!emailRegex.hasMatch(value)) {
    return ValidationLocalization.translate('invalid_email', language);
  }
  return null;
}

String? passwordValidator(
  String? value, 
  bool isPasswordLengthValid, 
  bool hasUppercase, 
  bool hasNumber, 
  bool hasSymbol,
  String language,
) {
  if (value == null || value.isEmpty) {
    return ValidationLocalization.translate('required_password', language);
  }
  if (!isPasswordLengthValid || !hasUppercase || !hasNumber || !hasSymbol) {
    return ValidationLocalization.translate('password_requirements_not_met', language);
  }
  return null;
}

void validatePassword(String value, Function(bool, bool, bool, bool) updatePasswordValidation) {
  final bool isPasswordLengthValid = value.length >= 8;
  final bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
  final bool hasNumber = value.contains(RegExp(r'\d'));
  final bool hasSymbol = value.contains(RegExp(r'[!@#\$&*~]'));

  updatePasswordValidation(isPasswordLengthValid, hasUppercase, hasNumber, hasSymbol);
}

String? validateUsername(String? value, String language) {
  if (value == null || value.isEmpty) {
    return ValidationLocalization.translate('required_username', language);
  }
  if (value.length < 4 || value.length > 16) {
    return ValidationLocalization.translate('invalid_username', language);
  }
  
  // Check for profanity
  final profanityCheck = ProfanityFilter.validateText(value, language);
  if (profanityCheck != null) {
    return profanityCheck;
  }
  
  return null;
}

String? validateBirthday(String? value, String language) {
  if (value == null || value.isEmpty) {
    return ValidationLocalization.translate('required_birthday', language);
  }

  try {
    final parts = value.split('-');
    if (parts.length != 3) return ValidationLocalization.translate('invalid_date', language);
    
    final birthday = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    
    final today = DateTime.now();
    int age = today.year - birthday.year;
    if (today.month < birthday.month || 
        (today.month == birthday.month && today.day < birthday.day)) {
      age--;
    }
    
    if (age < 11) {
      return ValidationLocalization.translate('too_young', language);
    }
    if (age > 16) {
      return ValidationLocalization.translate('too_old', language);
    }
    
    return null;
  } catch (e) {
    return ValidationLocalization.translate('invalid_date', language);
  }
}