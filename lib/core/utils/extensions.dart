import 'package:flutter/material.dart';

// String Extensions
extension StringExtension on String {
  // Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  // Capitalize each word
  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  // Check if string is email
  bool get isEmail {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(this);
  }

  // Check if string is phone number
  bool get isPhoneNumber {
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    return phoneRegex.hasMatch(this);
  }

  // Remove whitespace
  String removeWhitespace() {
    return replaceAll(RegExp(r'\s+'), '');
  }

  // Truncate string
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  // Check if string is null or empty
  bool get isNullOrEmpty => isEmpty;

  // Check if string is not null and not empty
  bool get isNotNullOrEmpty => isNotEmpty;
}

// DateTime Extensions
extension DateTimeExtension on DateTime {
  // Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  // Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  // Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }

  // Get start of day
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  // Get end of day
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59);
  }

  // Add days
  DateTime addDays(int days) {
    return add(Duration(days: days));
  }

  // Subtract days
  DateTime subtractDays(int days) {
    return subtract(Duration(days: days));
  }
}

// BuildContext Extensions
extension BuildContextExtension on BuildContext {
  // Get screen size
  Size get screenSize => MediaQuery.of(this).size;

  // Get screen width
  double get screenWidth => screenSize.width;

  // Get screen height
  double get screenHeight => screenSize.height;

  // Check if device is mobile
  bool get isMobile => screenWidth < 600;

  // Check if device is tablet
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;

  // Check if device is desktop
  bool get isDesktop => screenWidth >= 900;

  // Get theme
  ThemeData get theme => Theme.of(this);

  // Get text theme
  TextTheme get textTheme => theme.textTheme;

  // Get color scheme
  ColorScheme get colorScheme => theme.colorScheme;

  // Show snackbar
  void showSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  // Hide keyboard
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
}

// List Extensions
extension ListExtension<T> on List<T> {
  // Check if list is null or empty
  bool get isNullOrEmpty => isEmpty;

  // Check if list is not null and not empty
  bool get isNotNullOrEmpty => isNotEmpty;

  // Get first element or null
  T? get firstOrNull => isEmpty ? null : first;

  // Get last element or null
  T? get lastOrNull => isEmpty ? null : last;
}

// Int Extensions
extension IntExtension on int {
  // Format with commas
  String get withCommas {
    return toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  // Convert to duration
  Duration get seconds => Duration(seconds: this);
  Duration get minutes => Duration(minutes: this);
  Duration get hours => Duration(hours: this);
  Duration get days => Duration(days: this);
}

// Double Extensions
extension DoubleExtension on double {
  // Format as percentage
  String toPercentage({int decimals = 1}) {
    return '${(this * 100).toStringAsFixed(decimals)}%';
  }

  // Round to decimals
  double roundToDecimals(int decimals) {
    final mod = 10.0.pow(decimals);
    return ((this * mod).round().toDouble() / mod);
  }
}

// Helper extension for pow
extension NumExtension on num {
  num pow(num exponent) {
    num result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= this;
    }
    return result;
  }
}

// Color Extensions
extension ColorExtension on Color {
  // Lighten color
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  // Darken color
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}