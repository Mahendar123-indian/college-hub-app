class AppConfig {
  // App Information
  static const String appName = 'College Resource Hub';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // Environment
  static const bool isProduction = true;
  static const bool enableLogging = !isProduction;

  // API Configuration
  static const String baseUrl = 'https://api.collegehub.com';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Firebase Configuration
  static const String firebaseProjectId = 'college-resource-hub';
  static const String firebaseStorageBucket = 'college-resource-hub.appspot.com';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Configuration
  static const Duration cacheValidity = Duration(hours: 24);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB

  // File Upload Configuration
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  static const List<String> allowedFileExtensions = [
    'pdf',
    'doc',
    'docx',
    'txt',
    'jpg',
    'jpeg',
    'png',
  ];

  // Features
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePushNotifications = true;

  // Social Media Links
  static const String websiteUrl = 'https://collegehub.com';
  static const String facebookUrl = 'https://facebook.com/collegehub';
  static const String twitterUrl = 'https://twitter.com/collegehub';
  static const String instagramUrl = 'https://instagram.com/collegehub';

  // Support
  static const String supportEmail = 'support@collegehub.com';
  static const String privacyPolicyUrl = 'https://collegehub.com/privacy';
  static const String termsUrl = 'https://collegehub.com/terms';
}