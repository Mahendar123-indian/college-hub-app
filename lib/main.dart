import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'config/routes.dart';
import 'data/services/notification_service_ENHANCED.dart';
import 'data/services/download_service.dart';
import 'data/services/trending_manager.dart';

// All Providers
import 'providers/auth_provider.dart';
import 'providers/resource_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/filter_provider.dart';
import 'providers/college_provider.dart';
import 'providers/review_provider.dart';
import 'providers/previous_year_paper_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/friend_request_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/ai_assistant_provider.dart';
import 'providers/smart_learning_provider.dart';
import 'providers/download_provider.dart';
import 'providers/youtube_provider.dart';
// ✅ NEW: Academic Search Provider
import 'providers/academic_search_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  debugPrint('📩 Background: ${message.messageId}');
}

void main() async {
  // 🔥 CRITICAL: Wrap entire app in error handler
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await _runCriticalBootSequence();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => CollegeProvider()),
          ChangeNotifierProvider(create: (_) => ResourceProvider()),
          ChangeNotifierProvider(create: (_) => FilterProvider()),
          ChangeNotifierProvider(create: (_) => ReviewProvider()),
          ChangeNotifierProvider(create: (_) => PreviousYearPaperProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => FriendRequestProvider()),
          ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
          ChangeNotifierProvider(create: (_) => AIAssistantProvider()),
          ChangeNotifierProvider(create: (_) => SmartLearningProvider()),
          ChangeNotifierProvider(create: (_) => DownloadProvider()..initialize()),
          ChangeNotifierProvider(create: (_) => YouTubeProvider()..init()),
          // ✅ NEW: Academic Search Provider
          ChangeNotifierProvider(create: (_) => AcademicSearchProvider()),
        ],
        child: const RootRestorationScope(
          restorationId: 'college_hub',
          child: CollegeResourceHubApp(),
        ),
      ),
    );
  }, (error, stack) {
    debugPrint('❌ CRITICAL ERROR: $error');
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

Future<void> _runCriticalBootSequence() async {
  try {
    debugPrint('🚀 Starting Critical Boot Sequence...');

    // STEP 1: Load environment variables FIRST (Critical for AI)
    try {
      await dotenv.load(fileName: ".env");
      debugPrint('✅ Environment variables loaded');
    } catch (e) {
      debugPrint('⚠️ .env file not found (non-critical): $e');
    }

    // STEP 2: Initialize Firebase, Hive, and FlutterDownloader (Parallel)
    await Future.wait([
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      Hive.initFlutter(),
      FlutterDownloader.initialize(
        debug: kDebugMode,
        ignoreSsl: false,
      ),
    ]);

    // STEP 3: Open only CRITICAL boxes first (Fast startup!)
    await Future.wait([
      Hive.openBox('app_data'),
      Hive.openBox('userReviews'),
      Hive.openBox('resourceCache'),
      Hive.openBox('downloads'),
      Hive.openBox('youtube_cache'),
      Hive.openBox('youtube_watch_history'),
      Hive.openBox('youtube_favorites'),
      Hive.openBox('youtube_watch_later'),
      // ✅ NEW: Academic Search Critical Boxes
      Hive.openBox<Map>('academicSearchHistory'),
      Hive.openBox<Map>('pinnedSearches'),
      Hive.openBox('searchAnalytics'),
    ]);

    // STEP 4: Initialize Download Service
    try {
      await DownloadService().initialize();
      debugPrint('✅ Download service initialized');
    } catch (e) {
      debugPrint('⚠️ Download service error (non-critical): $e');
    }

    // STEP 5: Initialize Trending Manager
    try {
      final trendingManager = TrendingManager();

      // Run initial trending calculation
      await trendingManager.calculateTrendingScores();
      debugPrint('✅ Initial trending scores calculated');

      // Schedule periodic updates (every 30 minutes)
      Timer.periodic(const Duration(minutes: 30), (timer) async {
        try {
          await trendingManager.calculateTrendingScores();
          debugPrint('🔄 Trending scores updated automatically');
        } catch (e) {
          debugPrint('⚠️ Trending update error: $e');
        }
      });

      debugPrint('✅ Trending manager initialized with auto-updates');
    } catch (e) {
      debugPrint('⚠️ Trending manager error (non-critical): $e');
    }

    // STEP 6: Open other boxes in background (Non-blocking)
    _openNonCriticalBoxes();

    // STEP 7: Setup Firebase Messaging
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // STEP 8: Initialize Notifications
    final currentUser = FirebaseAuth.instance.currentUser;
    try {
      await NotificationService().initialize(navigatorKey, userId: currentUser?.uid);
      debugPrint('✅ Notification service initialized');
    } catch (e) {
      debugPrint('⚠️ Notification error (non-critical): $e');
    }

    // STEP 9: Setup Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    debugPrint('✅ Critical Boot Sequence Complete');
  } catch (e) {
    debugPrint('❌ Critical Boot Error: $e');
  }
}

// OPTIMIZATION: Open non-critical boxes in background
void _openNonCriticalBoxes() async {
  try {
    await Future.wait([
      Hive.openBox('bookmarks'),
      Hive.openBox('searchHistory'),
      // AI Assistant boxes
      Hive.openBox('aiChatMessages'),
      Hive.openBox('aiSessions'),
      Hive.openBox('studyModes'),
      // Smart Learning Tools boxes
      Hive.openBox('flashcards'),
      Hive.openBox('mindMaps'),
      Hive.openBox('studySessions'),
      Hive.openBox('pomodoroSessions'),
      Hive.openBox('dailyGoals'),
      Hive.openBox('studyPlans'),
      Hive.openBox('smartNotes'),
    ]);
    debugPrint('✅ All boxes opened');
  } catch (e) {
    debugPrint('⚠️ Non-critical boxes error: $e');
  }
}

class CollegeResourceHubApp extends StatefulWidget {
  const CollegeResourceHubApp({super.key});

  @override
  State<CollegeResourceHubApp> createState() => _CollegeResourceHubAppState();
}

class _CollegeResourceHubAppState extends State<CollegeResourceHubApp> with WidgetsBindingObserver {
  bool _connected = false;

  // 🔥 NEW: Lifecycle state tracking
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('✅ App lifecycle observer added');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('🔴 App lifecycle observer removed');
    super.dispose();
  }

  // 🔥 CRITICAL: Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('🔄 App Lifecycle State: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        debugPrint('⏸️ App paused');
        break;
      case AppLifecycleState.inactive:
        debugPrint('😴 App inactive');
        break;
      case AppLifecycleState.detached:
        debugPrint('🔌 App detached');
        break;
      case AppLifecycleState.hidden:
        debugPrint('👻 App hidden');
        break;
    }
  }

  // 🔥 CRITICAL: Refresh all providers when app resumes
  void _onAppResumed() {
    debugPrint('✅ App RESUMED - Refreshing providers...');

    try {
      final context = navigatorKey.currentContext;
      if (context != null && mounted) {
        // Refresh Auth Provider
        Provider.of<AuthProvider>(context, listen: false).refreshAuth();

        // Refresh Resource Provider
        Provider.of<ResourceProvider>(context, listen: false).refreshResources();

        // Reconnect Chat Provider (if you have this method)
        try {
          Provider.of<ChatProvider>(context, listen: false).reconnect();
        } catch (e) {
          debugPrint('⚠️ ChatProvider reconnect: $e');
        }

        debugPrint('✅ All providers refreshed on resume');

        // Force rebuild
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error refreshing on resume: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_connected) {
      _connectProviders();
      _connected = true;
    }
  }

  void _connectProviders() {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final resource = Provider.of<ResourceProvider>(context, listen: false);
      final chat = Provider.of<ChatProvider>(context, listen: false);
      final analytics = Provider.of<AnalyticsProvider>(context, listen: false);
      final aiAssistant = Provider.of<AIAssistantProvider>(context, listen: false);
      final smartLearning = Provider.of<SmartLearningProvider>(context, listen: false);
      final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
      final youtubeProvider = Provider.of<YouTubeProvider>(context, listen: false);
      // ✅ NEW: Academic Search Provider
      final academicSearchProvider = Provider.of<AcademicSearchProvider>(context, listen: false);

      // Set provider references for auth
      auth.setProviderReferences(
        resourceProvider: resource,
        chatProvider: chat,
        analyticsProvider: analytics,
      );

      // Initialize AI Assistant
      if (auth.currentUser != null) {
        aiAssistant.initialize();
        debugPrint('✅ AI Assistant initialized for user: ${auth.currentUser!.id}');
      }

      // Initialize Smart Learning
      if (auth.currentUser != null) {
        smartLearning.initialize(auth.currentUser!.id);
        debugPrint('✅ Smart Learning initialized for user: ${auth.currentUser!.id}');
      }

      // Sync downloads with Firestore when user is logged in
      if (auth.currentUser != null) {
        downloadProvider.syncWithFirestore(auth.currentUser!.id);
        debugPrint('✅ Downloads synced for user: ${auth.currentUser!.id}');
      }

      // ✅ NEW: Initialize Academic Search Provider
      academicSearchProvider.initialize();
      debugPrint('✅ Academic Search Provider initialized');

      debugPrint('✅ YouTube Provider ready');
      debugPrint('✅ All providers connected successfully');
    } catch (e) {
      debugPrint('⚠️ Provider connection error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) {
        return MaterialApp(
          title: 'College Hub',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.generateRoute,
          restorationScopeId: 'college_hub',
          theme: ThemeData.light(useMaterial3: true).copyWith(
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
            scaffoldBackgroundColor: const Color(0xFF020417),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          themeMode: theme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        );
      },
    );
  }
}