// lib/config/routes.dart

import 'package:flutter/material.dart';

// Screens - Core
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/home/home_screen.dart';

// Screens - Resources
import '../presentation/screens/resources/resource_list_screen.dart';
import '../presentation/screens/resources/resource_detail_screen.dart';
import '../presentation/screens/resources/pdf_viewer_screen.dart';

// Screens - Search & Filter
import '../presentation/screens/search/filter_screen.dart';
import '../presentation/screens/search/enhanced_search_screen.dart';
import '../presentation/screens/search/college_selection_screen.dart';

// Screens - User Features
import '../presentation/screens/bookmarks/bookmarks_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/profile/edit_profile_screen.dart';
import '../presentation/screens/profile/settings_screen.dart';
import '../presentation/screens/downloads/downloads_screen.dart';

// Screens - Admin
import '../presentation/screens/admin/admin_dashboard_screen.dart';
import '../presentation/screens/admin/upload_resource_screen.dart';
import '../presentation/screens/admin/manage_resources_screen.dart';
import '../presentation/screens/admin/user_management_screen.dart';
import '../presentation/screens/admin/analytics_screen.dart';
import '../presentation/screens/admin/admin_reviews_screen.dart';

// Screens - Previous Year Papers
import '../presentation/screens/previous_year_papers/previous_year_papers_screen.dart';
import '../presentation/screens/previous_year_papers/upload_previous_year_paper_screen.dart';
import '../presentation/screens/previous_year_papers/paper_detail_screen.dart';
import '../presentation/screens/admin/admin_previous_year_papers_screen.dart';

// Screens - Chat System
import '../presentation/screens/chat/chat_list_screen.dart';
import '../presentation/screens/chat/chat_detail_screen_advanced.dart';
import '../presentation/screens/chat/user_search_screen.dart';
import '../presentation/screens/chat/chat_requests_screen.dart';
import '../presentation/screens/chat/friend_requests_screen.dart';
import '../presentation/screens/chat/user_profile_screen.dart';
import '../presentation/screens/chat/group_info_screen.dart';
import '../presentation/screens/chat/media_gallery_screen.dart';
import '../presentation/screens/chat/message_search_screen.dart';
import '../presentation/screens/chat/forward_message_screen.dart';
import '../presentation/screens/chat/pinned_messages_screen.dart';
import '../presentation/screens/chat/create_group_screen.dart';
import '../presentation/screens/chat/add_group_members_screen.dart';
import '../presentation/screens/chat/video_call_screen.dart';
import '../presentation/screens/chat/voice_call_screen.dart';

// ✅ AI Assistant (UNIFIED SYSTEM)
import '../presentation/screens/ai/ai_assistant_screen.dart';
import '../presentation/screens/ai/ai_settings_screen.dart';

// ✅ NEW: Academic Search
import '../presentation/screens/ai/academic_search_screen.dart';

// ✅ AI Study Tools
import '../presentation/screens/ai_study/pdf_analyzer_screen.dart';
import '../presentation/screens/ai_study/smart_notes_generator.dart';
import '../presentation/screens/ai_study/exam_prep_widget.dart';
import '../presentation/screens/ai_study/numerical_solver_widget.dart';

// ✨ Smart Learning Tools
import '../presentation/screens/smart_learning/smart_learning_hub_screen.dart';
import '../presentation/screens/smart_learning/flashcard_generator_screen.dart';
import '../presentation/screens/smart_learning/mind_map_generator_screen.dart';
import '../presentation/screens/smart_learning/pomodoro_timer_screen.dart';
import '../presentation/screens/smart_learning/study_streak_tracker_screen.dart';
import '../presentation/screens/smart_learning/smart_notes_screen.dart';
import '../presentation/screens/smart_learning/daily_goals_screen.dart';
import '../presentation/screens/smart_learning/study_planner_screen.dart';
import '../presentation/screens/smart_learning/distraction_free_mode_screen.dart';
import '../presentation/screens/smart_learning/progress_analytics_screen.dart';
import '../presentation/screens/smart_learning/revision_booster_screen.dart';

// ✅ YouTube Imports
import '../presentation/screens/youtube/youtube_player_screen.dart';
import '../presentation/screens/youtube/youtube_list_screen.dart';
import '../presentation/screens/youtube/youtube_search_screen.dart';
import '../data/models/youtube_video_model.dart';
import '../data/models/user_model.dart';
import '../data/models/message_model.dart';

class AppRoutes {
  // ═══════════════════════════════════════════════════════════════
  // CORE ROUTES
  // ═══════════════════════════════════════════════════════════════

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String resourceList = '/resource-list';
  static const String resourceDetail = '/resource-detail';
  static const String pdfViewer = '/pdf-viewer';
  static const String search = '/search';
  static const String enhancedSearch = '/enhanced-search';
  static const String collegeSelection = '/college-selection';
  static const String filter = '/filter';
  static const String bookmarks = '/bookmarks';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  static const String downloads = '/downloads';

  // ═══════════════════════════════════════════════════════════════
  // ADMIN ROUTES
  // ═══════════════════════════════════════════════════════════════

  static const String adminDashboard = '/admin-dashboard';
  static const String uploadResource = '/upload-resource';
  static const String manageResources = '/manage-resources';
  static const String userManagement = '/user-management';
  static const String analytics = '/analytics';
  static const String adminReviews = '/admin-reviews';

  // ═══════════════════════════════════════════════════════════════
  // PREVIOUS YEAR PAPERS
  // ═══════════════════════════════════════════════════════════════

  static const String previousYearPapers = '/previous-year-papers';
  static const String uploadPreviousYearPaper = '/upload-previous-year-paper';
  static const String paperDetail = '/paper-detail';
  static const String adminPreviousYearPapers = '/admin-previous-year-papers';

  // ═══════════════════════════════════════════════════════════════
  // CHAT ROUTES
  // ═══════════════════════════════════════════════════════════════

  static const String chatList = '/chat-list';
  static const String chatDetail = '/chat-detail';
  static const String userSearch = '/user-search';
  static const String chatRequests = '/chat-requests';
  static const String friendRequests = '/friend-requests';
  static const String userProfile = '/user-profile';
  static const String groupInfo = '/group-info';
  static const String mediaGallery = '/media-gallery';
  static const String messageSearch = '/message-search';
  static const String forwardMessage = '/forward-message';
  static const String pinnedMessages = '/pinned-messages';
  static const String createGroup = '/create-group';
  static const String addGroupMembers = '/add-group-members';

  // ✅ CALL ROUTES
  static const String videoCall = '/video-call';
  static const String voiceCall = '/voice-call';

  // ═══════════════════════════════════════════════════════════════
  // ✅ AI ASSISTANT ROUTES
  // ═══════════════════════════════════════════════════════════════

  static const String aiAssistant = '/ai-assistant';
  static const String aiSettings = '/ai-settings';

  // ✅ NEW: Academic Search Route
  static const String academicSearch = '/academic-search';

  // ═══════════════════════════════════════════════════════════════
  // ✅ AI STUDY TOOLS
  // ═══════════════════════════════════════════════════════════════

  static const String pdfAnalyzer = '/pdf-analyzer';
  static const String smartNotesGenerator = '/smart-notes-generator';
  static const String examPrep = '/exam-prep';
  static const String numericalSolver = '/numerical-solver';

  // ═══════════════════════════════════════════════════════════════
  // ✨ SMART LEARNING TOOLS
  // ═══════════════════════════════════════════════════════════════

  static const String smartLearningHub = '/smart-learning-hub';
  static const String flashcardGenerator = '/flashcard-generator';
  static const String mindMapGenerator = '/mind-map-generator';
  static const String pomodoroTimer = '/pomodoro-timer';
  static const String studyStreakTracker = '/study-streak-tracker';
  static const String smartNotes = '/smart-notes';
  static const String dailyGoals = '/daily-goals';
  static const String studyPlanner = '/study-planner';
  static const String distractionFreeMode = '/distraction-free-mode';
  static const String progressAnalytics = '/progress-analytics';
  static const String revisionBooster = '/revision-booster';

  // ═══════════════════════════════════════════════════════════════
  // ✅ YOUTUBE ROUTES
  // ═══════════════════════════════════════════════════════════════

  static const String youtubePlayer = '/youtube-player';
  static const String youtubeList = '/youtube-list';
  static const String youtubeSearch = '/youtube-search';

  // ═══════════════════════════════════════════════════════════════
  // STATIC ROUTE MAP
  // ═══════════════════════════════════════════════════════════════

  static final Map<String, WidgetBuilder> _routes = {
    splash: (_) => const SplashScreen(),
    onboarding: (_) => const OnboardingScreen(),
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    forgotPassword: (_) => const ForgotPasswordScreen(),
    home: (_) => const HomeScreen(),
    search: (_) => const EnhancedSearchScreen(),
    enhancedSearch: (_) => const EnhancedSearchScreen(),
    collegeSelection: (_) => const CollegeSelectionScreen(),
    filter: (_) => const FilterScreen(),
    bookmarks: (_) => const BookmarksScreen(),
    profile: (_) => const ProfileScreen(),
    editProfile: (_) => const EditProfileScreen(),
    settings: (_) => const SettingsScreen(),
    downloads: (_) => const DownloadsScreen(),
    adminDashboard: (_) => const AdminDashboardScreen(),
    uploadResource: (_) => const UploadResourceScreen(),
    manageResources: (_) => const ManageResourcesScreen(),
    userManagement: (_) => const UserManagementScreen(),
    analytics: (_) => const AnalyticsScreen(),
    adminReviews: (_) => const AdminReviewsScreen(),
    previousYearPapers: (_) => const PreviousYearPapersScreen(),
    uploadPreviousYearPaper: (_) => const UploadPreviousYearPaperScreen(),
    adminPreviousYearPapers: (_) => const AdminPreviousYearPapersScreen(),
    chatList: (_) => const ChatListScreen(),
    userSearch: (_) => const UserSearchScreen(),
    chatRequests: (_) => const ChatRequestsScreen(),
    friendRequests: (_) => const FriendRequestsScreen(),
    createGroup: (_) => const CreateGroupScreen(),

    // ✅ AI Assistant
    aiAssistant: (_) => const AIAssistantScreen(),
    aiSettings: (_) => const AISettingsScreen(),

    // ✅ NEW: Academic Search
    academicSearch: (_) => const AcademicSearchScreen(),

    // ✅ AI Study Tools
    pdfAnalyzer: (_) => const PdfAnalyzerScreen(),
    examPrep: (_) => const ExamPrepWidget(),
    numericalSolver: (_) => const NumericalSolverWidget(),

    // ✨ Smart Learning
    smartLearningHub: (_) => const SmartLearningHubScreen(),
    pomodoroTimer: (_) => const PomodoroTimerScreen(),
    studyStreakTracker: (_) => const StudyStreakTrackerScreen(),
    dailyGoals: (_) => const DailyGoalsScreen(),
    studyPlanner: (_) => const StudyPlannerScreen(),
    progressAnalytics: (_) => const ProgressAnalyticsScreen(),
  };

  // ═══════════════════════════════════════════════════════════════
  // NAVIGATION HELPERS
  // ═══════════════════════════════════════════════════════════════

  static void navigateToResourceDetail(BuildContext context, String resourceId) {
    Navigator.pushNamed(context, resourceDetail, arguments: {'resourceId': resourceId});
  }

  static void navigateToPdfViewer(BuildContext context, {
    required String title,
    String? url,
    String? filePath,
  }) {
    Navigator.pushNamed(
      context,
      pdfViewer,
      arguments: {'title': title, 'url': url, 'filePath': filePath},
    );
  }

  static void navigateToChatDetail(BuildContext context, {
    required String id,
    required String name,
    String? photo,
    bool isGroup = false,
    String? otherUserId,
  }) {
    Navigator.pushNamed(
      context,
      chatDetail,
      arguments: {
        'conversationId': id,
        'conversationName': name,
        'conversationPhoto': photo,
        'isGroup': isGroup,
        'otherUserId': otherUserId,
      },
    );
  }

  static void navigateToUserProfile(BuildContext context, {
    required UserModel user,
  }) {
    Navigator.pushNamed(
      context,
      userProfile,
      arguments: {'user': user},
    );
  }

  static void navigateToGroupInfo(BuildContext context, String conversationId) {
    Navigator.pushNamed(context, groupInfo, arguments: {'conversationId': conversationId});
  }

  static void navigateToMediaGallery(BuildContext context, String conversationId) {
    Navigator.pushNamed(context, mediaGallery, arguments: {'conversationId': conversationId});
  }

  static void navigateToMessageSearch(BuildContext context, String conversationId) {
    Navigator.pushNamed(context, messageSearch, arguments: {'conversationId': conversationId});
  }

  static void navigateToPinnedMessages(BuildContext context, String conversationId) {
    Navigator.pushNamed(context, pinnedMessages, arguments: {'conversationId': conversationId});
  }

  static void navigateToAddGroupMembers(
      BuildContext context,
      String conversationId,
      List<String> existingMembers,
      ) {
    Navigator.pushNamed(
      context,
      addGroupMembers,
      arguments: {'conversationId': conversationId, 'existingMembers': existingMembers},
    );
  }

  static void navigateToPaperDetail(BuildContext context, String paperId) {
    Navigator.pushNamed(context, paperDetail, arguments: {'paperId': paperId});
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ CALL NAVIGATION HELPERS
  // ═══════════════════════════════════════════════════════════════

  static void navigateToVideoCall(BuildContext context, {
    required String calleeId,
    required String calleeName,
    String? calleePhoto,
    bool isIncoming = false,
  }) {
    Navigator.pushNamed(
      context,
      videoCall,
      arguments: {
        'calleeId': calleeId,
        'calleeName': calleeName,
        'calleePhoto': calleePhoto,
        'isIncoming': isIncoming,
      },
    );
  }

  static void navigateToVoiceCall(BuildContext context, {
    required String calleeId,
    required String calleeName,
    String? calleePhoto,
    bool isIncoming = false,
  }) {
    Navigator.pushNamed(
      context,
      voiceCall,
      arguments: {
        'calleeId': calleeId,
        'calleeName': calleeName,
        'calleePhoto': calleePhoto,
        'isIncoming': isIncoming,
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ AI ASSISTANT NAVIGATION
  // ═══════════════════════════════════════════════════════════════

  static void navigateToAIAssistant(BuildContext context) {
    Navigator.pushNamed(context, aiAssistant);
  }

  /// ✅ NEW: Navigate to AI Settings
  static void navigateToAISettings(BuildContext context) {
    Navigator.pushNamed(context, aiSettings);
  }

  static void navigateToAcademicSearch(BuildContext context) {
    Navigator.pushNamed(context, academicSearch);
  }

  static void navigateToPdfAnalyzer(BuildContext context) {
    Navigator.pushNamed(context, pdfAnalyzer);
  }

  static void navigateToSmartNotesGenerator(BuildContext context, {
    required String topic,
    required String subject,
  }) {
    Navigator.pushNamed(
      context,
      smartNotesGenerator,
      arguments: {'topic': topic, 'subject': subject},
    );
  }

  static void navigateToExamPrep(BuildContext context) {
    Navigator.pushNamed(context, examPrep);
  }

  static void navigateToNumericalSolver(BuildContext context) {
    Navigator.pushNamed(context, numericalSolver);
  }

  // ═══════════════════════════════════════════════════════════════
  // ✨ SMART LEARNING NAVIGATION
  // ═══════════════════════════════════════════════════════════════

  static void navigateToSmartLearningHub(BuildContext context) {
    Navigator.pushNamed(context, smartLearningHub);
  }

  static void navigateToFlashcardGenerator(BuildContext context, {
    String? resourceId,
    String? topic,
  }) {
    Navigator.pushNamed(
      context,
      flashcardGenerator,
      arguments: {'resourceId': resourceId, 'topic': topic},
    );
  }

  static void navigateToMindMapGenerator(BuildContext context, {
    String? topic,
    String? subject,
  }) {
    Navigator.pushNamed(
      context,
      mindMapGenerator,
      arguments: {'topic': topic, 'subject': subject},
    );
  }

  static void navigateToPomodoroTimer(BuildContext context) {
    Navigator.pushNamed(context, pomodoroTimer);
  }

  static void navigateToStudyStreakTracker(BuildContext context) {
    Navigator.pushNamed(context, studyStreakTracker);
  }

  static void navigateToSmartNotes(BuildContext context, {String? resourceId}) {
    Navigator.pushNamed(context, smartNotes, arguments: {'resourceId': resourceId});
  }

  static void navigateToDailyGoals(BuildContext context) {
    Navigator.pushNamed(context, dailyGoals);
  }

  static void navigateToStudyPlanner(BuildContext context) {
    Navigator.pushNamed(context, studyPlanner);
  }

  static void navigateToDistractionFreeMode(BuildContext context, {String? resourceId}) {
    Navigator.pushNamed(
      context,
      distractionFreeMode,
      arguments: {'resourceId': resourceId},
    );
  }

  static void navigateToProgressAnalytics(BuildContext context) {
    Navigator.pushNamed(context, progressAnalytics);
  }

  static void navigateToRevisionBooster(BuildContext context, {String? subject}) {
    Navigator.pushNamed(
      context,
      revisionBooster,
      arguments: {'subject': subject},
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ YOUTUBE NAVIGATION HELPERS
  // ═══════════════════════════════════════════════════════════════

  static void navigateToYouTubePlayer(
      BuildContext context, {
        required YouTubeVideoModel video,
        List<YouTubeVideoModel> relatedVideos = const [],
      }) {
    Navigator.pushNamed(
      context,
      youtubePlayer,
      arguments: {
        'video': video,
        'relatedVideos': relatedVideos,
      },
    );
  }

  static void navigateToYouTubeList(
      BuildContext context, {
        required String resourceId,
        required String resourceTitle,
        required String subject,
        String? topic,
        String? unit,
      }) {
    Navigator.pushNamed(
      context,
      youtubeList,
      arguments: {
        'resourceId': resourceId,
        'resourceTitle': resourceTitle,
        'subject': subject,
        'topic': topic,
        'unit': unit,
      },
    );
  }

  static void navigateToYouTubeSearch(
      BuildContext context, {
        required String subject,
        String? topic,
      }) {
    Navigator.pushNamed(
      context,
      youtubeSearch,
      arguments: {
        'subject': subject,
        'topic': topic,
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DYNAMIC ROUTE GENERATOR
  // ═══════════════════════════════════════════════════════════════

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final routeName = settings.name;

    switch (routeName) {
      case resourceList:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ResourceListScreen(
            category: args?['category'],
            filters: args?['filters'],
          ),
          settings: settings,
        );

      case resourceDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ResourceDetailScreen(resourceId: args['resourceId']),
          settings: settings,
        );

      case pdfViewer:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
            title: args['title'],
            url: args['url'],
            filePath: args['filePath'],
          ),
          settings: settings,
        );

      case chatDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            conversationId: args?['conversationId'] ?? '',
            conversationName: args?['conversationName'] ?? 'Chat',
            conversationPhoto: args?['conversationPhoto'],
            isGroup: args?['isGroup'] ?? false,
            otherUserId: args?['otherUserId'],
          ),
          settings: settings,
        );

      case videoCall:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            calleeId: args['calleeId'],
            calleeName: args['calleeName'],
            calleePhoto: args['calleePhoto'],
            isIncoming: args['isIncoming'] ?? false,
          ),
          settings: settings,
        );

      case voiceCall:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => VoiceCallScreen(
            calleeId: args['calleeId'],
            calleeName: args['calleeName'],
            calleePhoto: args['calleePhoto'],
            isIncoming: args['isIncoming'] ?? false,
          ),
          settings: settings,
        );

      case userProfile:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => UserProfileScreen(user: args['user'] as UserModel),
          settings: settings,
        );

      case groupInfo:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => GroupInfoScreen(conversationId: args['conversationId']),
          settings: settings,
        );

      case mediaGallery:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => MediaGalleryScreen(conversationId: args['conversationId']),
          settings: settings,
        );

      case messageSearch:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => MessageSearchScreen(conversationId: args['conversationId']),
          settings: settings,
        );

      case forwardMessage:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ForwardMessageScreen(
            messages: (args['messages'] as List).cast<MessageModel>(),
          ),
          settings: settings,
        );

      case pinnedMessages:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PinnedMessagesScreen(conversationId: args['conversationId']),
          settings: settings,
        );

      case addGroupMembers:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => AddGroupMembersScreen(
            conversationId: args['conversationId'],
            existingMembers: (args['existingMembers'] as List).cast<String>(),
          ),
          settings: settings,
        );

      case paperDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PaperDetailScreen(paperId: args['paperId']),
          settings: settings,
        );

      case smartNotesGenerator:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => SmartNotesGenerator(
            topic: args['topic'],
            subject: args['subject'],
          ),
          settings: settings,
        );

      case flashcardGenerator:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => FlashcardGeneratorScreen(
            resourceId: args?['resourceId'],
            topic: args?['topic'],
          ),
          settings: settings,
        );

      case mindMapGenerator:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => MindMapGeneratorScreen(
            topic: args?['topic'],
            subject: args?['subject'],
          ),
          settings: settings,
        );

      case smartNotes:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => SmartNotesScreen(resourceId: args?['resourceId']),
          settings: settings,
        );

      case distractionFreeMode:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => DistractionFreeModeScreen(resourceId: args?['resourceId']),
          settings: settings,
        );

      case revisionBooster:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => RevisionBoosterScreen(subject: args?['subject']),
          settings: settings,
        );

      case youtubePlayer:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => YouTubePlayerScreenAdvanced(
            video: args['video'] as YouTubeVideoModel,
            relatedVideos: (args['relatedVideos'] as List?)?.cast<YouTubeVideoModel>() ?? [],
          ),
          settings: settings,
        );

      case youtubeList:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => YouTubeListScreen(
            resourceId: args['resourceId'],
            resourceTitle: args['resourceTitle'],
            subject: args['subject'],
            topic: args['topic'],
            unit: args['unit'],
          ),
          settings: settings,
        );

      case youtubeSearch:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => YouTubeSearchScreenAdvanced(
            subject: args['subject'],
            topic: args['topic'],
          ),
          settings: settings,
        );
    }

    // Check static routes
    if (routeName != null && _routes.containsKey(routeName)) {
      return MaterialPageRoute(
        builder: _routes[routeName]!,
        settings: settings,
      );
    }

    // Route not found - show error
    return _errorRoute(routeName);
  }

  // ═══════════════════════════════════════════════════════════════
  // ERROR ROUTE
  // ═══════════════════════════════════════════════════════════════

  static Route<dynamic> _errorRoute(String? routeName) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Route not found: $routeName',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, splash),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}