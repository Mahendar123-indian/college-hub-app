import '../constants/app_constants.dart';

class Validators {
  // ✅ ADDED: Name validation to resolve the EditProfileScreen error
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters long';
    }
    // Optional: Prevents numbers in names
    if (RegExp(r'[0-9]').hasMatch(value)) {
      return 'Name should not contain numbers';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!AppConstants.emailRegex.hasMatch(value.trim())) return AppConstants.errorInvalidEmail;
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < AppConstants.minPasswordLength) return AppConstants.errorInvalidPassword;
    return null;
  }

  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return AppConstants.errorPasswordMismatch;
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    // Remove spaces/hyphens for clean validation
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!AppConstants.phoneRegex.hasMatch(cleanPhone)) return 'Enter a valid 10-digit number';
    return null;
  }

  static String? validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? validateDropdown(dynamic value, {String fieldName = 'selection'}) {
    if (value == null) return 'Please make a $fieldName';
    return null;
  }
}