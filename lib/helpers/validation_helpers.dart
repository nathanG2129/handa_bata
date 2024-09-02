// lib/helpers/validation_helpers.dart

String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your email';
  }
  final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  if (!emailRegex.hasMatch(value)) {
    return 'Please enter a valid email address';
  }
  return null;
}

String? passwordValidator(String? value, bool isPasswordLengthValid, bool hasUppercase, bool hasNumber, bool hasSymbol) {
  if (value == null || value.isEmpty) {
    return 'Please enter your password';
  }
  if (!isPasswordLengthValid || !hasUppercase || !hasNumber || !hasSymbol) {
    return 'Password does not meet the requirements';
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

String? validateUsername(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your username';
  }
  if (value.length < 4 || value.length > 16) {
    return 'Username must be between 4 and 16 characters';
  }
  return null;
}