import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Helper method to convert Map<String, dynamic> to Map<String, Object>
  Map<String, Object>? _convertToObjectMap(Map<String, dynamic>? input) {
    if (input == null) return null;
    return input.map((key, value) => MapEntry(key, value as Object));
  }

  // Log custom event with dynamic parameters
  Future<void> logEvent(String name, Map<String, dynamic>? parameters) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: _convertToObjectMap(parameters),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log event: $e');
      }
    }
  }

  // Log custom event with Object parameters (type-safe)
  Future<void> logEventTypeSafe(
      String name,
      Map<String, Object>? parameters,
      ) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log event: $e');
      }
    }
  }

  // Log login event
  Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log login: $e');
      }
    }
  }

  // Log sign up event
  Future<void> logSignUp(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log signup: $e');
      }
    }
  }

  // Log screen view
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log screen view: $e');
      }
    }
  }

  // Log resource view
  Future<void> logResourceView(String resourceId, String resourceType) async {
    try {
      await _analytics.logEvent(
        name: 'view_resource',
        parameters: {
          'resource_id': resourceId,
          'resource_type': resourceType,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log resource view: $e');
      }
    }
  }

  // Log resource download
  Future<void> logResourceDownload(
      String resourceId, {
        String? resourceType,
        String? resourceName,
      }) async {
    try {
      final parameters = <String, Object>{
        'resource_id': resourceId,
      };

      if (resourceType != null) {
        parameters['resource_type'] = resourceType;
      }
      if (resourceName != null) {
        parameters['resource_name'] = resourceName;
      }

      await _analytics.logEvent(
        name: 'download_resource',
        parameters: parameters,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log resource download: $e');
      }
    }
  }

  // Log resource share
  Future<void> logResourceShare(
      String resourceId,
      String shareMethod,
      ) async {
    try {
      await _analytics.logShare(
        contentType: 'resource',
        itemId: resourceId,
        method: shareMethod,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log resource share: $e');
      }
    }
  }

  // Log search
  Future<void> logSearch(String query, {String? category}) async {
    try {
      await _analytics.logSearch(searchTerm: query);

      // Log additional search details
      if (category != null) {
        await _analytics.logEvent(
          name: 'search_with_category',
          parameters: {
            'search_term': query,
            'category': category,
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log search: $e');
      }
    }
  }

  // Log bookmark action
  Future<void> logBookmark(String resourceId, bool isBookmarked) async {
    try {
      await _analytics.logEvent(
        name: isBookmarked ? 'bookmark_add' : 'bookmark_remove',
        parameters: {'resource_id': resourceId},
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log bookmark: $e');
      }
    }
  }

  // Log profile update
  Future<void> logProfileUpdate(String field) async {
    try {
      await _analytics.logEvent(
        name: 'profile_update',
        parameters: {'updated_field': field},
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log profile update: $e');
      }
    }
  }

  // Log app open
  Future<void> logAppOpen() async {
    try {
      await _analytics.logAppOpen();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log app open: $e');
      }
    }
  }

  // Set user ID
  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set user ID: $e');
      }
    }
  }

  // Set user property
  Future<void> setUserProperty(String name, String value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set user property: $e');
      }
    }
  }

  // Set multiple user properties
  Future<void> setUserProperties(Map<String, String> properties) async {
    try {
      for (var entry in properties.entries) {
        await _analytics.setUserProperty(
          name: entry.key,
          value: entry.value,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set user properties: $e');
      }
    }
  }

  // Clear user ID (for logout)
  Future<void> clearUserId() async {
    try {
      await _analytics.setUserId(id: null);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to clear user ID: $e');
      }
    }
  }

  // Log tutorial begin
  Future<void> logTutorialBegin() async {
    try {
      await _analytics.logTutorialBegin();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log tutorial begin: $e');
      }
    }
  }

  // Log tutorial complete
  Future<void> logTutorialComplete() async {
    try {
      await _analytics.logTutorialComplete();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log tutorial complete: $e');
      }
    }
  }

  // Log page view (for web)
  Future<void> logPageView(String pageName) async {
    try {
      await _analytics.logEvent(
        name: 'page_view',
        parameters: {'page_name': pageName},
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log page view: $e');
      }
    }
  }

  // Log error
  Future<void> logError(String errorMessage, String errorLocation) async {
    try {
      await _analytics.logEvent(
        name: 'app_error',
        parameters: {
          'error_message': errorMessage,
          'error_location': errorLocation,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log error: $e');
      }
    }
  }

  // Reset analytics data
  Future<void> resetAnalyticsData() async {
    try {
      await _analytics.resetAnalyticsData();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to reset analytics data: $e');
      }
    }
  }

  // Get app instance ID
  Future<String?> getAppInstanceId() async {
    try {
      return await _analytics.appInstanceId;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get app instance ID: $e');
      }
      return null;
    }
  }

  // Set analytics collection enabled
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(enabled);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set analytics collection: $e');
      }
    }
  }
}