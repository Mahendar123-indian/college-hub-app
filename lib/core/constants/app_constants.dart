// lib/core/constants/app_constants.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // ═══════════════════════════════════════════════════════════════
  // APP INFORMATION
  // ═══════════════════════════════════════════════════════════════

  static const String appName = 'College Resource Hub';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Your Gateway to Academic Excellence';

  // ═══════════════════════════════════════════════════════════════
  // FIREBASE COLLECTIONS
  // ═══════════════════════════════════════════════════════════════

  static const String usersCollection = 'users';
  static const String resourcesCollection = 'resources';
  static const String collegesCollection = 'colleges';
  static const String departmentsCollection = 'departments';
  static const String downloadsCollection = 'downloads';
  static const String bookmarksCollection = 'bookmarks';
  static const String analyticsCollection = 'analytics';
  static const String notificationsCollection = 'notifications';
  static const String reviewsCollection = 'reviews';
  static const String previousYearPapersCollection = 'previousYearPapers';
  static const String conversationsCollection = 'conversations';
  static const String messagesCollection = 'messages';

  // ═══════════════════════════════════════════════════════════════
  // STORAGE PATHS
  // ═══════════════════════════════════════════════════════════════

  static const String resourcesStoragePath = 'resources';
  static const String profileImagesPath = 'profile_images';
  static const String thumbnailsPath = 'thumbnails';
  static const String previousYearPapersStoragePath = 'previousYearPapers';
  static const String chatMediaPath = 'chats';
  static const String youtubeThumbsPath = 'youtube/thumbnails';

  // ═══════════════════════════════════════════════════════════════
  // USER ROLES
  // ═══════════════════════════════════════════════════════════════

  static const String roleAdmin = 'admin';
  static const String roleStudent = 'student';
  static const String roleModerator = 'moderator';

  // ═══════════════════════════════════════════════════════════════
  // RESOURCE TYPES
  // ═══════════════════════════════════════════════════════════════

  static const List<String> resourceTypes = [
    'Mid-Exam Papers',
    'Semester Exam Papers',
    'Previous Year Papers',
    'Class Notes',
    'Syllabus',
    'Reference Books',
    'Assignments',
    'Lab Manuals',
    'Question Banks',
    'Study Guides',
  ];

  // ═══════════════════════════════════════════════════════════════
  // EXAM TYPES
  // ═══════════════════════════════════════════════════════════════

  static const List<String> examTypes = [
    'Mid-Exam 1',
    'Mid-Exam 2',
    'Semester Exam',
    'Annual Exam',
    'Supplementary Exam',
  ];

  // ═══════════════════════════════════════════════════════════════
  // PAPER STATUS
  // ═══════════════════════════════════════════════════════════════

  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';

  // ═══════════════════════════════════════════════════════════════
  // RESOURCE TYPE ICONS
  // ═══════════════════════════════════════════════════════════════

  static const Map<String, String> resourceTypeIcons = {
    'Mid-Exam Papers': '📝',
    'Semester Exam Papers': '📄',
    'Previous Year Papers': '📚',
    'Class Notes': '📓',
    'Syllabus': '📋',
    'Reference Books': '📖',
    'Assignments': '✍️',
    'Lab Manuals': '🔬',
    'Question Banks': '❓',
    'Study Guides': '📌',
  };

  // ═══════════════════════════════════════════════════════════════
  // SEMESTERS
  // ═══════════════════════════════════════════════════════════════

  static const List<String> semesters = [
    '1st Semester',
    '2nd Semester',
    '3rd Semester',
    '4th Semester',
    '5th Semester',
    '6th Semester',
    '7th Semester',
    '8th Semester',
  ];

  // ═══════════════════════════════════════════════════════════════
  // FILE SIZE LIMITS
  // ═══════════════════════════════════════════════════════════════

  static const int maxFileSizeMB = 50;
  static const int maxFileSizeBytes = maxFileSizeMB * 1024 * 1024;
  static const int maxImageSizeMB = 10;
  static const int maxVideoSizeMB = 100;
  static const int maxUploadSizeMB = 150;

  // ═══════════════════════════════════════════════════════════════
  // PAGINATION
  // ═══════════════════════════════════════════════════════════════

  static const int itemsPerPage = 20;
  static const int maxItemsToLoad = 100;
  static const int videosPerPage = 15;

  // ═══════════════════════════════════════════════════════════════
  // CACHE DURATION
  // ═══════════════════════════════════════════════════════════════

  static const Duration cacheDuration = Duration(hours: 24);
  static const Duration shortCacheDuration = Duration(hours: 1);
  static const Duration youtubeSearchCacheExpiration = Duration(hours: 1);
  static const Duration searchCacheExpiration = Duration(hours: 1);

  // ═══════════════════════════════════════════════════════════════
  // TIMEOUTS
  // ═══════════════════════════════════════════════════════════════

  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);
  static const Duration downloadTimeout = Duration(minutes: 10);

  // ═══════════════════════════════════════════════════════════════
  // VALIDATION
  // ═══════════════════════════════════════════════════════════════

  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;

  // ═══════════════════════════════════════════════════════════════
  // SHARED PREFERENCES KEYS
  // ═══════════════════════════════════════════════════════════════

  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserData = 'user_data';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyAutoDownload = 'auto_download';
  static const String keyDownloadLocation = 'download_location';
  static const String keyFirstLaunch = 'first_launch';

  // ═══════════════════════════════════════════════════════════════
  // HIVE BOXES - CORE
  // ═══════════════════════════════════════════════════════════════

  static const String appDataBox = 'app_data';
  static const String downloadsBox = 'downloads';
  static const String bookmarksBox = 'bookmarks';
  static const String cacheBox = 'cache';
  static const String userBox = 'user_box';
  static const String authBox = 'auth_box';
  static const String settingsBox = 'settings_box';
  static const String preferencesBox = 'preferences_box';

  // ═══════════════════════════════════════════════════════════════
  // HIVE BOXES - ACADEMIC SEARCH
  // ═══════════════════════════════════════════════════════════════

  static const String academicSearchHistoryBox = 'academic_search_history_box';
  static const String pinnedSearchesBox = 'pinned_searches_box';
  static const String searchAnalyticsBox = 'search_analytics_box';

  // ═══════════════════════════════════════════════════════════════
  // HIVE BOXES - YOUTUBE
  // ═══════════════════════════════════════════════════════════════

  static const String youtubeCacheBox = 'youtube_cache';
  static const String youtubeWatchHistoryBox = 'youtube_watch_history';
  static const String youtubeFavoritesBox = 'youtube_favorites';
  static const String youtubeWatchLaterBox = 'youtube_watch_later';
  static const String youtubePlaylistsBox = 'youtube_playlists_box';
  static const String youtubeHistoryBox = 'youtube_history_box';

  // ═══════════════════════════════════════════════════════════════
  // HIVE BOXES - AI & STUDY
  // ═══════════════════════════════════════════════════════════════

  static const String aiChatHistoryBox = 'ai_chat_history_box';
  static const String studySessionsBox = 'study_sessions_box';
  static const String flashcardsBox = 'flashcards_box';
  static const String notesBox = 'notes_box';

  // ═══════════════════════════════════════════════════════════════
  // HIVE BOXES - ANALYTICS
  // ═══════════════════════════════════════════════════════════════

  static const String analyticsBox = 'analytics_box';
  static const String studyStreakBox = 'study_streak_box';
  static const String subjectPerformanceBox = 'subject_performance_box';
  static const String usageStatsBox = 'usage_stats_box';

  // ═══════════════════════════════════════════════════════════════
  // HIVE BOXES - CHAT & MESSAGES
  // ═══════════════════════════════════════════════════════════════

  static const String conversationsBox = 'conversations_box';
  static const String messagesBox = 'messages_box';
  static const String draftMessagesBox = 'draft_messages_box';

  // ═══════════════════════════════════════════════════════════════
  // HIVE BOXES - CACHE
  // ═══════════════════════════════════════════════════════════════

  static const String imageCacheBox = 'image_cache_box';
  static const String thumbnailCacheBox = 'thumbnail_cache_box';

  // ═══════════════════════════════════════════════════════════════
  // ERROR MESSAGES
  // ═══════════════════════════════════════════════════════════════

  static const String errorNoInternet = 'No internet connection. Please check your network.';
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorTimeout = 'Request timeout. Please try again.';
  static const String errorFileNotFound = 'File not found.';
  static const String errorFileTooLarge = 'File size exceeds the limit of $maxFileSizeMB MB.';
  static const String errorInvalidEmail = 'Please enter a valid email address.';
  static const String errorInvalidPassword = 'Password must be at least $minPasswordLength characters.';
  static const String errorPasswordMismatch = 'Passwords do not match.';
  static const String errorEmptyField = 'This field cannot be empty.';
  static const String errorDownloadFailed = 'Download failed. Please try again.';
  static const String errorUploadFailed = 'Upload failed. Please try again.';
  static const String errorPermissionDenied = 'Permission denied. Please grant necessary permissions.';
  static const String errorSearchFailed = 'Search failed. Please try again.';

  // ═══════════════════════════════════════════════════════════════
  // SUCCESS MESSAGES
  // ═══════════════════════════════════════════════════════════════

  static const String successLogin = 'Login successful!';
  static const String successRegister = 'Registration successful!';
  static const String successUpload = 'Resource uploaded successfully!';
  static const String successDownload = 'Download completed successfully!';
  static const String successUpdate = 'Updated successfully!';
  static const String successDelete = 'Deleted successfully!';
  static const String successBookmark = 'Added to bookmarks!';
  static const String successRemoveBookmark = 'Removed from bookmarks!';
  static const String successPaperUpload = 'Paper uploaded! Awaiting admin approval.';
  static const String successPaperApprove = 'Paper approved successfully!';
  static const String successPaperReject = 'Paper rejected.';
  static const String successSearchCompleted = 'Search completed successfully!';
  static const String successSearchSaved = 'Search saved to history!';
  static const String successSearchPinned = 'Search pinned to favorites!';

  // ═══════════════════════════════════════════════════════════════
  // INFO MESSAGES
  // ═══════════════════════════════════════════════════════════════

  static const String infoNoData = 'No data available.';
  static const String infoNoResources = 'No resources found.';
  static const String infoNoBookmarks = 'No bookmarks yet. Start bookmarking your favorite resources!';
  static const String infoNoDownloads = 'No downloads yet.';
  static const String infoSearching = 'Searching...';
  static const String infoLoading = 'Loading...';
  static const String infoUploading = 'Uploading...';
  static const String infoDownloading = 'Downloading...';
  static const String infoNoPapers = 'No previous year papers found.';
  static const String infoNoPendingPapers = 'No pending papers to review!';
  static const String infoNoSearchHistory = 'No search history yet';
  static const String infoAIAnalyzing = 'AI is analyzing your question...';
  static const String infoSearchingPDFs = 'Searching PDFs and YouTube videos';

  // ═══════════════════════════════════════════════════════════════
  // CONFIRMATION MESSAGES
  // ═══════════════════════════════════════════════════════════════

  static const String confirmLogout = 'Are you sure you want to logout?';
  static const String confirmDelete = 'Are you sure you want to delete this?';
  static const String confirmClearCache = 'Are you sure you want to clear cache?';
  static const String confirmClearDownloads = 'Are you sure you want to clear all downloads?';
  static const String confirmApprovePaper = 'Are you sure you want to approve this paper?';
  static const String confirmRejectPaper = 'Are you sure you want to reject this paper?';
  static const String confirmDeletePaper = 'Are you sure you want to delete this paper permanently?';
  static const String confirmClearSearchHistory = 'Are you sure you want to clear search history?';
  static const String confirmDeleteSearch = 'Are you sure you want to delete this search?';

  // ═══════════════════════════════════════════════════════════════
  // BUTTON LABELS
  // ═══════════════════════════════════════════════════════════════

  static const String btnLogin = 'Login';
  static const String btnRegister = 'Register';
  static const String btnLogout = 'Logout';
  static const String btnSubmit = 'Submit';
  static const String btnCancel = 'Cancel';
  static const String btnSave = 'Save';
  static const String btnDelete = 'Delete';
  static const String btnEdit = 'Edit';
  static const String btnUpload = 'Upload';
  static const String btnDownload = 'Download';
  static const String btnShare = 'Share';
  static const String btnSearch = 'Search';
  static const String btnFilter = 'Filter';
  static const String btnContinue = 'Continue';
  static const String btnSkip = 'Skip';
  static const String btnGetStarted = 'Get Started';
  static const String btnYes = 'Yes';
  static const String btnNo = 'No';
  static const String btnOk = 'OK';
  static const String btnRetry = 'Retry';
  static const String btnApprove = 'Approve';
  static const String btnReject = 'Reject';
  static const String btnPreview = 'Preview';
  static const String btnRate = 'Rate';

  // ═══════════════════════════════════════════════════════════════
  // NAVIGATION LABELS
  // ═══════════════════════════════════════════════════════════════

  static const String navHome = 'Home';
  static const String navSearch = 'Search';
  static const String navBookmarks = 'Bookmarks';
  static const String navProfile = 'Profile';
  static const String navAdmin = 'Admin';
  static const String navChat = 'Chat';
  static const String navYouTube = 'YouTube';

  // ═══════════════════════════════════════════════════════════════
  // DATE FORMATS
  // ═══════════════════════════════════════════════════════════════

  static const String dateFormatDisplay = 'MMM dd, yyyy';
  static const String dateFormatFull = 'MMMM dd, yyyy';
  static const String dateTimeFormat = 'MMM dd, yyyy hh:mm a';
  static const String timeFormat = 'hh:mm a';

  // ═══════════════════════════════════════════════════════════════
  // REGULAR EXPRESSIONS
  // ═══════════════════════════════════════════════════════════════

  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp phoneRegex = RegExp(
    r'^[0-9]{10}$',
  );

  // ═══════════════════════════════════════════════════════════════
  // ANIMATION DURATIONS
  // ═══════════════════════════════════════════════════════════════

  static const Duration animationDurationShort = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationLong = Duration(milliseconds: 500);

  // ═══════════════════════════════════════════════════════════════
  // DEBOUNCE DURATION
  // ═══════════════════════════════════════════════════════════════

  static const Duration debounceDuration = Duration(milliseconds: 500);

  // ═══════════════════════════════════════════════════════════════
  // AUTO-LOGOUT DURATION
  // ═══════════════════════════════════════════════════════════════

  static const Duration autoLogoutDuration = Duration(hours: 24);

  // ═══════════════════════════════════════════════════════════════
  // NOTIFICATION CHANNELS
  // ═══════════════════════════════════════════════════════════════

  static const String notificationChannelId = 'college_resource_hub';
  static const String notificationChannelName = 'College Resource Hub';
  static const String notificationChannelDescription = 'Notifications for new resources and updates';

  // ═══════════════════════════════════════════════════════════════
  // DEEP LINKS
  // ═══════════════════════════════════════════════════════════════

  static const String deepLinkScheme = 'collegehub';
  static const String deepLinkHost = 'app';

  // ═══════════════════════════════════════════════════════════════
  // EXTERNAL LINKS
  // ═══════════════════════════════════════════════════════════════

  static const String privacyPolicyUrl = 'https://yourwebsite.com/privacy';
  static const String termsOfServiceUrl = 'https://yourwebsite.com/terms';
  static const String supportEmail = 'support@collegehub.com';
  static const String websiteUrl = 'https://collegehub.com';

  // ═══════════════════════════════════════════════════════════════
  // SOCIAL MEDIA
  // ═══════════════════════════════════════════════════════════════

  static const String facebookUrl = 'https://facebook.com/collegehub';
  static const String twitterUrl = 'https://twitter.com/collegehub';
  static const String instagramUrl = 'https://instagram.com/collegehub';

  // ═══════════════════════════════════════════════════════════════
  // DOWNLOAD STATUS
  // ═══════════════════════════════════════════════════════════════

  static const String downloadStatusPending = 'pending';
  static const String downloadStatusDownloading = 'downloading';
  static const String downloadStatusCompleted = 'completed';
  static const String downloadStatusFailed = 'failed';
  static const String downloadStatusCancelled = 'cancelled';

  // ═══════════════════════════════════════════════════════════════
  // YOUTUBE CONFIGURATION
  // ═══════════════════════════════════════════════════════════════

  static String get youtubeApiKey {
    final key = dotenv.env['YOUTUBE_API_KEY'];
    if (key == null || key.isEmpty) {
      debugPrint('⚠️ WARNING: YOUTUBE_API_KEY not found in .env file!');
      return '';
    }
    return key;
  }

  static const int youtubeMaxResults = 10;
  static const String youtubeApiBaseUrl = 'https://www.googleapis.com/youtube/v3';
  static const int maxWatchHistory = 100;
  static const int maxFavorites = 50;
  static const int maxWatchLater = 30;

  // ═══════════════════════════════════════════════════════════════
  // ACADEMIC SEARCH CONFIGURATION
  // ═══════════════════════════════════════════════════════════════

  static const int maxSearchHistory = 50;
  static const int maxPinnedSearches = 10;
  static const int maxRecentSearches = 10;
  static const int maxPDFPages = 100;

  // Academic Subjects
  static const List<String> academicSubjects = [
    'Computer Science',
    'Data Structures',
    'Algorithms',
    'Operating Systems',
    'DBMS',
    'Computer Networks',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Electronics',
    'Engineering',
    'Biology',
    'Machine Learning',
    'AI',
    'Software Engineering',
  ];

  // Academic Levels
  static const List<String> academicLevels = [
    'Diploma',
    'B.Tech',
    'Degree',
    'M.Tech',
    'PhD',
  ];

  // Academic Exam Types
  static const List<String> academicExamTypes = [
    'Mid',
    'Semester',
    'Competitive',
    'Assignment',
  ];

  // ═══════════════════════════════════════════════════════════════
  // ANALYTICS CONFIGURATION
  // ═══════════════════════════════════════════════════════════════

  static const int minStreakDays = 1;
  static const int maxStreakDays = 365;
  static const int studyGoalMinutes = 120;
  static const int defaultDailyGoalMinutes = 60;

  // ═══════════════════════════════════════════════════════════════
  // FEATURE FLAGS
  // ═══════════════════════════════════════════════════════════════

  static const bool enableAcademicSearch = true;
  static const bool enableYouTubeIntegration = true;
  static const bool enableAnalytics = true;
  static const bool enableOfflineMode = true;
  static const bool enableDarkMode = true;
  static const bool enablePushNotifications = true;

  // ═══════════════════════════════════════════════════════════════
  // UI CONSTANTS
  // ═══════════════════════════════════════════════════════════════

  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;
  static const double iconSize = 24.0;
  static const double avatarRadius = 30.0;
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 20.0;

  // ═══════════════════════════════════════════════════════════════
  // COLORS (HEX)
  // ═══════════════════════════════════════════════════════════════

  static const String primaryColorHex = '#4A90E2';
  static const String secondaryColorHex = '#6366F1';
  static const String accentColorHex = '#8B5CF6';
  static const String errorColorHex = '#FF6B6B';
  static const String successColorHex = '#4CAF50';
  static const String warningColorHex = '#FF9800';
  static const String youtubeRedHex = '#FF0000';
  static const String purpleHex = '#9C27B0';
  static const String orangeHex = '#FFA726';

  // ═══════════════════════════════════════════════════════════════
  // PREFERENCES KEYS
  // ═══════════════════════════════════════════════════════════════

  static const String prefThemeMode = 'theme_mode';
  static const String prefLanguage = 'language';
  static const String prefNotifications = 'notifications_enabled';
  static const String prefAutoDownload = 'auto_download';
  static const String prefDataSaver = 'data_saver_mode';
  static const String prefOfflineMode = 'offline_mode';
  static const String prefAutoPlayVideos = 'auto_play_videos';
  static const String prefVideoQuality = 'video_quality';

  // ═══════════════════════════════════════════════════════════════
  // GEMINI AI CONFIGURATION
  // ═══════════════════════════════════════════════════════════════

  static String get geminiApiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      debugPrint('⚠️ WARNING: GEMINI_API_KEY not found in .env file!');
      return '';
    }
    return key;
  }

  static const String geminiModel = 'gemini-1.5-flash-latest';
  static const int geminiMaxTokens = 8192;
  static const double geminiTemperature = 0.7;

  // ═══════════════════════════════════════════════════════════════
  // PDF PROCESSING
  // ═══════════════════════════════════════════════════════════════

  static const int pdfChunkSize = 1000;
  static const int maxPDFChunks = 50;
  static const int pdfOverlapSize = 100;

  // ═══════════════════════════════════════════════════════════════
  // SEARCH RESULT LIMITS
  // ═══════════════════════════════════════════════════════════════

  static const int maxVideoResults = 15;
  static const int maxPDFResults = 10;
  static const int maxPracticeQuestions = 5;
  static const int maxRelatedTopics = 5;

  // ═══════════════════════════════════════════════════════════════
  // LOGGING
  // ═══════════════════════════════════════════════════════════════

  static const bool enableDebugLogs = kDebugMode;
  static const bool enableAnalyticsLogs = true;
  static const bool enableErrorReporting = true;
}