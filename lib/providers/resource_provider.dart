import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/resource_model.dart';
import '../data/repositories/resource_repository.dart';
import '../core/utils/notification_triggers.dart';

class ResourceProvider with ChangeNotifier {
  final ResourceRepository _repository = ResourceRepository();

  List<ResourceModel> _resources = [];
  List<ResourceModel> _featuredResources = [];
  List<ResourceModel> _trendingResources = [];
  List<ResourceModel> _recentResources = [];
  List<ResourceModel> _searchResults = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Stream subscriptions for cancellation
  StreamSubscription? _featuredSubscription;
  StreamSubscription? _trendingSubscription;

  // Getters
  List<ResourceModel> get resources => _resources;
  List<ResourceModel> get featuredResources => _featuredResources;
  List<ResourceModel> get trendingResources => _trendingResources;
  List<ResourceModel> get recentResources => _recentResources;
  List<ResourceModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════

  Future<void> init() async {
    try {
      await _repository.init();
      debugPrint('✅ ResourceProvider initialized');
    } catch (e) {
      debugPrint('❌ ResourceProvider init error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FETCH RESOURCES WITH FILTERS
  // ═══════════════════════════════════════════════════════════════

  Future<void> fetchResourcesByFilters({
    String? college,
    String? department,
    String? semester,
    String? subject,
    String? resourceType,
    String? year,
    int? limit,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _resources = await _repository.getResourcesByFilters(
        college: college,
        department: department,
        semester: semester,
        subject: subject,
        resourceType: resourceType,
        year: year,
        limit: limit,
      );

      debugPrint('✅ Fetched ${_resources.length} resources');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to fetch resources: $e';
      debugPrint('❌ fetchResourcesByFilters error: $e');
      notifyListeners();
    }
  }

  Future<void> fetchAllResources() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _resources = await _repository.getAllActiveResources(limit: 500);

      debugPrint('✅ Fetched all ${_resources.length} resources');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to fetch all resources: $e';
      debugPrint('❌ fetchAllResources error: $e');
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SEARCH FUNCTIONALITY
  // ═══════════════════════════════════════════════════════════════

  Future<void> searchResources(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _searchResults = await _repository.searchResources(query.trim());

      debugPrint('✅ Search found ${_searchResults.length} results for: $query');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Search failed: $e';
      debugPrint('❌ searchResources error: $e');
      notifyListeners();
    }
  }

  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final suggestions = await _repository.getSearchSuggestions(query.trim());
      debugPrint('✅ Got ${suggestions.length} suggestions for: $query');
      return suggestions;
    } catch (e) {
      debugPrint('❌ getSearchSuggestions error: $e');
      return [];
    }
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // FEATURED, TRENDING & RECENT RESOURCES
  // ═══════════════════════════════════════════════════════════════

  Future<void> fetchFeaturedResources() async {
    try {
      await _featuredSubscription?.cancel();

      _featuredSubscription = _repository.getFeaturedResources().listen(
            (resources) {
          _featuredResources = resources;
          debugPrint('✅ Updated featured resources: ${resources.length}');
          notifyListeners();
        },
        onError: (e) {
          _errorMessage = 'Failed to fetch featured resources: $e';
          debugPrint('❌ fetchFeaturedResources error: $e');
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to fetch featured resources: $e';
      debugPrint('❌ fetchFeaturedResources error: $e');
      notifyListeners();
    }
  }

  Future<void> fetchTrendingResources() async {
    try {
      await _trendingSubscription?.cancel();

      _trendingSubscription = _repository.getTrendingResources().listen(
            (resources) {
          _trendingResources = resources;
          debugPrint('✅ Updated trending resources: ${resources.length}');
          notifyListeners();
        },
        onError: (e) {
          _errorMessage = 'Failed to fetch trending resources: $e';
          debugPrint('❌ fetchTrendingResources error: $e');
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to fetch trending resources: $e';
      debugPrint('❌ fetchTrendingResources error: $e');
      notifyListeners();
    }
  }

  Future<void> fetchRecentResources() async {
    try {
      _recentResources = await _repository.getRecentlyAddedResources();
      debugPrint('✅ Fetched recent resources: ${_recentResources.length}');
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch recent resources: $e';
      debugPrint('❌ fetchRecentResources error: $e');
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // STREAM CANCELLATION METHOD
  // ═══════════════════════════════════════════════════════════════

  Future<void> cancelStreams() async {
    try {
      await _featuredSubscription?.cancel();
      await _trendingSubscription?.cancel();
      _featuredSubscription = null;
      _trendingSubscription = null;
      debugPrint('✅ ResourceProvider streams cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling streams: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SINGLE RESOURCE OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  Future<ResourceModel?> getResourceById(String resourceId) async {
    try {
      final resource = await _repository.getResourceById(resourceId);
      if (resource == null) {
        debugPrint('⚠️ Resource not found: $resourceId');
      } else {
        debugPrint('✅ Fetched resource: ${resource.title}');
      }
      return resource;
    } catch (e) {
      _errorMessage = 'Failed to fetch resource: $e';
      debugPrint('❌ getResourceById error: $e');
      notifyListeners();
      return null;
    }
  }

  Stream<ResourceModel?> getResourceStream(String resourceId) {
    try {
      return _repository.getResourceStream(resourceId);
    } catch (e) {
      _errorMessage = 'Failed to listen to resource updates: $e';
      debugPrint('❌ getResourceStream error: $e');
      notifyListeners();
      return Stream.value(null);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ DOWNLOAD WITH NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Download resource with progress notifications
  Future<void> downloadResource(String resourceId, String fileName) async {
    int? notificationId;

    try {
      // Get resource details first
      final resource = await getResourceById(resourceId);
      if (resource == null) {
        throw Exception('Resource not found');
      }

      // ✅ SHOW DOWNLOAD STARTED NOTIFICATION
      notificationId = await NotificationTriggers.downloadStarted(fileName);

      // Simulate download progress (REPLACE with actual download logic)
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 200));

        // ✅ UPDATE DOWNLOAD PROGRESS
        await NotificationTriggers.downloadProgress(
          notificationId,
          fileName,
          i,
        );
      }

      // Increment download count in Firestore
      await _repository.incrementDownloadCount(resourceId);

      // ✅ SHOW DOWNLOAD COMPLETE NOTIFICATION
      await NotificationTriggers.downloadComplete(
        fileName,
        '/storage/emulated/0/Download/$fileName',
      );

      debugPrint('✅ Downloaded: $fileName');
    } catch (e) {
      // ✅ SHOW DOWNLOAD FAILED NOTIFICATION
      await NotificationTriggers.downloadFailed(
        fileName,
        e.toString(),
      );

      debugPrint('❌ Download error: $e');
      _errorMessage = 'Download failed: $e';
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // RESOURCE STATISTICS & INTERACTIONS
  // ═══════════════════════════════════════════════════════════════

  Future<void> incrementDownloadCount(String resourceId) async {
    try {
      await _repository.incrementDownloadCount(resourceId);
      debugPrint('✅ Incremented download count for: $resourceId');
    } catch (e) {
      debugPrint('❌ incrementDownloadCount error: $e');
    }
  }

  Future<void> incrementViewCount(String resourceId) async {
    try {
      await _repository.incrementViewCount(resourceId);
      debugPrint('✅ Incremented view count for: $resourceId');
    } catch (e) {
      debugPrint('❌ incrementViewCount error: $e');
    }
  }

  Future<void> rateResource(String resourceId, double rating) async {
    try {
      await _repository.updateResourceRating(resourceId, rating);
      debugPrint('✅ Rated resource $resourceId: $rating stars');

      // Refresh the resource to show updated rating
      await getResourceById(resourceId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to rate resource: $e';
      debugPrint('❌ rateResource error: $e');
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ BOOKMARK WITH NOTIFICATION
  // ═══════════════════════════════════════════════════════════════

  Future<void> bookmarkResource(String resourceId, String resourceTitle) async {
    try {
      // Add your bookmark logic here
      // await _repository.addBookmark(resourceId);

      // ✅ SHOW BOOKMARK SAVED NOTIFICATION
      await NotificationTriggers.resourceSaved(resourceTitle);

      debugPrint('✅ Bookmarked: $resourceTitle');
    } catch (e) {
      debugPrint('❌ Bookmark error: $e');
      _errorMessage = 'Failed to bookmark resource: $e';
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ ADMIN OPERATIONS WITH NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Add new resource with notification
  Future<void> addResource(ResourceModel resource) async {
    try {
      await _repository.createResource(resource);
      debugPrint('✅ Created resource: ${resource.title}');

      // ✅ SHOW UPLOAD SUCCESS NOTIFICATION
      await NotificationTriggers.resourceUploadSuccess(resource.title);

      // Refresh resources list
      await fetchAllResources();
    } catch (e) {
      _errorMessage = 'Failed to add resource: $e';
      debugPrint('❌ addResource error: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateResource(ResourceModel resource) async {
    try {
      await _repository.updateResource(resource);
      debugPrint('✅ Updated resource: ${resource.title}');

      // Update in local list if exists
      final index = _resources.indexWhere((r) => r.id == resource.id);
      if (index != -1) {
        _resources[index] = resource;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update resource: $e';
      debugPrint('❌ updateResource error: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteResource(String resourceId) async {
    try {
      await _repository.deleteResource(resourceId);
      debugPrint('✅ Deleted resource: $resourceId');

      // Remove from local list
      _resources.removeWhere((r) => r.id == resourceId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete resource: $e';
      debugPrint('❌ deleteResource error: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> batchUpdateResources(
      List<String> resourceIds,
      Map<String, dynamic> updates,
      ) async {
    try {
      await _repository.batchUpdate(resourceIds, updates);
      debugPrint('✅ Batch updated ${resourceIds.length} resources');

      // Refresh resources list
      await fetchAllResources();
    } catch (e) {
      _errorMessage = 'Failed to batch update resources: $e';
      debugPrint('❌ batchUpdateResources error: $e');
      notifyListeners();
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ANALYTICS & STATISTICS
  // ═══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getResourceStatistics() async {
    try {
      final stats = await _repository.getResourceStatistics();
      debugPrint('✅ Fetched resource statistics');
      return stats;
    } catch (e) {
      debugPrint('❌ getResourceStatistics error: $e');
      return {
        'totalResources': 0,
        'totalDownloads': 0,
        'totalViews': 0,
        'resourcesByType': {},
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CACHE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  Future<void> clearCache() async {
    try {
      await _repository.clearCache();
      debugPrint('✅ Cache cleared');
    } catch (e) {
      debugPrint('❌ clearCache error: $e');
    }
  }

  Future<void> refreshResource(String resourceId) async {
    try {
      await _repository.refreshResourceCache(resourceId);
      debugPrint('✅ Refreshed cache for resource: $resourceId');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ refreshResource error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔥 NEW: APP RESUME HANDLER - CRITICAL FIX FOR WHITE SCREEN
  // ═══════════════════════════════════════════════════════════════

  /// Refresh resources when app resumes from background
  Future<void> refreshResources() async {
    try {
      debugPrint('🔄 Refreshing resources on app resume...');

      // Only refresh if we have resources loaded previously
      if (_resources.isNotEmpty || _featuredResources.isNotEmpty || _trendingResources.isNotEmpty) {
        // Re-establish streams for real-time data
        if (_featuredSubscription == null && _featuredResources.isNotEmpty) {
          await fetchFeaturedResources();
        }

        if (_trendingSubscription == null && _trendingResources.isNotEmpty) {
          await fetchTrendingResources();
        }

        debugPrint('✅ Resources refreshed successfully');
      }
    } catch (e) {
      debugPrint('⚠️ Resource refresh error: $e');
      // Don't throw error, just log it
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ERROR HANDLING
  // ═══════════════════════════════════════════════════════════════

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════

  bool hasResource(String resourceId) {
    return _resources.any((r) => r.id == resourceId);
  }

  int get resourceCount => _resources.length;

  bool get hasData => _resources.isNotEmpty;

  bool get hasError => _errorMessage != null;

  void reset() {
    _resources = [];
    _featuredResources = [];
    _trendingResources = [];
    _recentResources = [];
    _searchResults = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void debugPrintState() {
    debugPrint('═══ ResourceProvider State ═══');
    debugPrint('Resources: ${_resources.length}');
    debugPrint('Featured: ${_featuredResources.length}');
    debugPrint('Trending: ${_trendingResources.length}');
    debugPrint('Recent: ${_recentResources.length}');
    debugPrint('Search Results: ${_searchResults.length}');
    debugPrint('Loading: $_isLoading');
    debugPrint('Error: $_errorMessage');
    debugPrint('═══════════════════════════════');
  }

  // ═══════════════════════════════════════════════════════════════
  // DISPOSE - Clean up streams
  // ═══════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _featuredSubscription?.cancel();
    _trendingSubscription?.cancel();
    super.dispose();
  }
}