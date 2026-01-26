import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/resource_model.dart';

class ResourceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'resources';

  // Multi-layer cache
  final Map<String, ResourceModel> _memoryCache = {};
  late Box _diskCache;
  bool _isInitialized = false;

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════

  /// Initialize cache system
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _diskCache = await Hive.openBox('resourceCache');
      _isInitialized = true;
      debugPrint('✅ ResourceRepository initialized with cache');
    } catch (e) {
      debugPrint('❌ ResourceRepository init error: $e');
      rethrow;
    }
  }

  /// Ensure initialization before operations
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE & UPLOAD LOGIC
  // ═══════════════════════════════════════════════════════════════

  /// Create new resource
  Future<void> createResource(ResourceModel resource) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final resourceWithId = ResourceModel(
        id: docRef.id,
        title: resource.title,
        description: resource.description,
        college: resource.college,
        department: resource.department,
        semester: resource.semester,
        subject: resource.subject,
        resourceType: resource.resourceType,
        year: resource.year,
        fileUrl: resource.fileUrl,
        fileName: resource.fileName,
        fileExtension: resource.fileExtension,
        fileSize: resource.fileSize,
        thumbnailUrl: resource.thumbnailUrl,
        uploadedBy: resource.uploadedBy,
        uploadedAt: resource.uploadedAt,
        updatedAt: resource.updatedAt,
        tags: resource.tags,
        downloadCount: resource.downloadCount,
        viewCount: resource.viewCount,
        rating: resource.rating,
        ratingCount: resource.ratingCount,
        isFeatured: resource.isFeatured,
        isTrending: resource.isTrending,
        isActive: resource.isActive,
        metadata: resource.metadata,
      );

      await docRef.set(resourceWithId.toFirestoreMap());

      // Cache the new resource
      _cacheResource(resourceWithId);

      debugPrint('✅ Created resource: ${resourceWithId.id}');
    } catch (e) {
      debugPrint('❌ createResource error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FETCH & FILTER LOGIC
  // ═══════════════════════════════════════════════════════════════

  /// Fetch all active resources
  Future<List<ResourceModel>> getAllActiveResources({int limit = 100}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('uploadedAt', descending: true)
          .limit(limit)
          .get();

      final resources = snapshot.docs
          .map((doc) => ResourceModel.fromDocument(doc))
          .toList();

      // Cache all resources
      for (var resource in resources) {
        _cacheResource(resource);
      }

      debugPrint('✅ Fetched ${resources.length} active resources');
      return resources;
    } catch (e) {
      debugPrint('❌ getAllActiveResources error: $e');
      rethrow;
    }
  }

  /// Advanced filtering with multiple conditions
  Future<List<ResourceModel>> getResourcesByFilters({
    String? college,
    String? department,
    String? semester,
    String? subject,
    String? resourceType,
    String? year,
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true);

      // Apply filters
      if (college != null && college.isNotEmpty) {
        query = query.where('college', isEqualTo: college);
      }
      if (department != null && department.isNotEmpty) {
        query = query.where('department', isEqualTo: department);
      }
      if (semester != null && semester.isNotEmpty) {
        query = query.where('semester', isEqualTo: semester);
      }
      if (subject != null && subject.isNotEmpty) {
        query = query.where('subject', isEqualTo: subject);
      }
      if (resourceType != null && resourceType.isNotEmpty) {
        query = query.where('resourceType', isEqualTo: resourceType);
      }
      if (year != null && year.isNotEmpty) {
        query = query.where('year', isEqualTo: year);
      }

      // Sorting
      query = query.orderBy('uploadedAt', descending: true);

      // Pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      final resources = snapshot.docs
          .map((doc) => ResourceModel.fromDocument(doc))
          .toList();

      // Cache all resources
      for (var resource in resources) {
        _cacheResource(resource);
      }

      debugPrint('✅ Filtered ${resources.length} resources');
      return resources;
    } catch (e) {
      debugPrint('❌ getResourcesByFilters error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SEARCH FUNCTIONALITY
  // ═══════════════════════════════════════════════════════════════

  /// Full-text search across multiple fields
  Future<List<ResourceModel>> searchResources(String query) async {
    try {
      final lowerQuery = query.toLowerCase().trim();

      // Fetch active resources
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      // Client-side filtering for better search
      final results = snapshot.docs.where((doc) {
        final data = doc.data();
        final title = (data['title'] as String? ?? '').toLowerCase();
        final subject = (data['subject'] as String? ?? '').toLowerCase();
        final description = (data['description'] as String? ?? '').toLowerCase();
        final department = (data['department'] as String? ?? '').toLowerCase();
        final college = (data['college'] as String? ?? '').toLowerCase();

        return title.contains(lowerQuery) ||
            subject.contains(lowerQuery) ||
            description.contains(lowerQuery) ||
            department.contains(lowerQuery) ||
            college.contains(lowerQuery);
      }).map((doc) => ResourceModel.fromDocument(doc)).toList();

      // Cache results
      for (var resource in results) {
        _cacheResource(resource);
      }

      debugPrint('✅ Search found ${results.length} results for: $query');
      return results;
    } catch (e) {
      debugPrint('❌ searchResources error: $e');
      rethrow;
    }
  }

  /// Get search suggestions for autocomplete
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      final lowerQuery = query.toLowerCase().trim();

      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .limit(20)
          .get();

      final suggestions = <String>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final title = data['title'] as String?;
        final subject = data['subject'] as String?;

        if (title != null && title.toLowerCase().contains(lowerQuery)) {
          suggestions.add(title);
        }
        if (subject != null && subject.toLowerCase().contains(lowerQuery)) {
          suggestions.add(subject);
        }

        if (suggestions.length >= 5) break;
      }

      debugPrint('✅ Got ${suggestions.length} suggestions for: $query');
      return suggestions.toList();
    } catch (e) {
      debugPrint('❌ getSearchSuggestions error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // REAL-TIME STREAMS
  // ═══════════════════════════════════════════════════════════════

  /// Single resource stream (real-time updates)
  Stream<ResourceModel?> getResourceStream(String resourceId) {
    return _firestore
        .collection(_collection)
        .doc(resourceId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;

      final resource = ResourceModel.fromDocument(doc);
      _cacheResource(resource);
      return resource;
    });
  }

  /// Featured resources stream
  Stream<List<ResourceModel>> getFeaturedResources() {
    return _firestore
        .collection(_collection)
        .where('isFeatured', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .orderBy('uploadedAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      final resources = snapshot.docs
          .map((doc) => ResourceModel.fromDocument(doc))
          .toList();

      for (var resource in resources) {
        _cacheResource(resource);
      }

      return resources;
    });
  }

  /// Trending resources stream
  Stream<List<ResourceModel>> getTrendingResources() {
    return _firestore
        .collection(_collection)
        .where('isTrending', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .orderBy('downloadCount', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      final resources = snapshot.docs
          .map((doc) => ResourceModel.fromDocument(doc))
          .toList();

      for (var resource in resources) {
        _cacheResource(resource);
      }

      return resources;
    });
  }

  /// Recently added resources
  Future<List<ResourceModel>> getRecentlyAddedResources({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('uploadedAt', descending: true)
          .limit(limit)
          .get();

      final resources = snapshot.docs
          .map((doc) => ResourceModel.fromDocument(doc))
          .toList();

      for (var resource in resources) {
        _cacheResource(resource);
      }

      debugPrint('✅ Fetched ${resources.length} recent resources');
      return resources;
    } catch (e) {
      debugPrint('❌ getRecentlyAddedResources error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SINGLE RESOURCE OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Get resource by ID with multi-layer cache
  Future<ResourceModel?> getResourceById(String resourceId) async {
    await _ensureInitialized();

    // Check memory cache first (fastest)
    if (_memoryCache.containsKey(resourceId)) {
      debugPrint('✅ Resource from memory cache: $resourceId');
      return _memoryCache[resourceId];
    }

    // Check disk cache (fast)
    if (_diskCache.containsKey(resourceId)) {
      try {
        final data = _diskCache.get(resourceId);
        // FIX: Convert Map<dynamic, dynamic> to Map<String, dynamic>
        final resource = ResourceModel.fromMap(Map<String, dynamic>.from(data));
        _memoryCache[resourceId] = resource;
        debugPrint('✅ Resource from disk cache: $resourceId');
        return resource;
      } catch (e) {
        debugPrint('⚠️ Disk cache read error: $e');
      }
    }

    // Fetch from Firestore (slower)
    try {
      final doc = await _firestore.collection(_collection).doc(resourceId).get();

      if (!doc.exists) {
        debugPrint('⚠️ Resource not found: $resourceId');
        return null;
      }

      final resource = ResourceModel.fromDocument(doc);
      _cacheResource(resource);
      debugPrint('✅ Resource from Firestore: $resourceId');
      return resource;
    } catch (e) {
      debugPrint('❌ getResourceById error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // STATISTICS & INTERACTIONS
  // ═══════════════════════════════════════════════════════════════

  /// Increment view count
  Future<void> incrementViewCount(String resourceId) async {
    try {
      await _firestore.collection(_collection).doc(resourceId).update({
        'viewCount': FieldValue.increment(1),
      });

      // Update memory cache
      if (_memoryCache.containsKey(resourceId)) {
        final resource = _memoryCache[resourceId]!;
        _memoryCache[resourceId] = ResourceModel(
          id: resource.id,
          title: resource.title,
          description: resource.description,
          college: resource.college,
          department: resource.department,
          semester: resource.semester,
          subject: resource.subject,
          resourceType: resource.resourceType,
          year: resource.year,
          fileUrl: resource.fileUrl,
          fileName: resource.fileName,
          fileExtension: resource.fileExtension,
          fileSize: resource.fileSize,
          thumbnailUrl: resource.thumbnailUrl,
          uploadedBy: resource.uploadedBy,
          uploadedAt: resource.uploadedAt,
          updatedAt: resource.updatedAt,
          tags: resource.tags,
          downloadCount: resource.downloadCount,
          viewCount: resource.viewCount + 1,
          rating: resource.rating,
          ratingCount: resource.ratingCount,
          isFeatured: resource.isFeatured,
          isTrending: resource.isTrending,
          isActive: resource.isActive,
          metadata: resource.metadata,
        );
      }

      debugPrint('✅ Incremented view count: $resourceId');
    } catch (e) {
      debugPrint('❌ incrementViewCount error: $e');
      rethrow;
    }
  }

  /// Increment download count
  Future<void> incrementDownloadCount(String resourceId) async {
    try {
      await _firestore.collection(_collection).doc(resourceId).update({
        'downloadCount': FieldValue.increment(1),
      });

      // Update memory cache
      if (_memoryCache.containsKey(resourceId)) {
        final resource = _memoryCache[resourceId]!;
        _memoryCache[resourceId] = ResourceModel(
          id: resource.id,
          title: resource.title,
          description: resource.description,
          college: resource.college,
          department: resource.department,
          semester: resource.semester,
          subject: resource.subject,
          resourceType: resource.resourceType,
          year: resource.year,
          fileUrl: resource.fileUrl,
          fileName: resource.fileName,
          fileExtension: resource.fileExtension,
          fileSize: resource.fileSize,
          thumbnailUrl: resource.thumbnailUrl,
          uploadedBy: resource.uploadedBy,
          uploadedAt: resource.uploadedAt,
          updatedAt: resource.updatedAt,
          tags: resource.tags,
          downloadCount: resource.downloadCount + 1,
          viewCount: resource.viewCount,
          rating: resource.rating,
          ratingCount: resource.ratingCount,
          isFeatured: resource.isFeatured,
          isTrending: resource.isTrending,
          isActive: resource.isActive,
          metadata: resource.metadata,
        );
      }

      debugPrint('✅ Incremented download count: $resourceId');
    } catch (e) {
      debugPrint('❌ incrementDownloadCount error: $e');
      rethrow;
    }
  }

  /// Update resource rating
  Future<void> updateResourceRating(String resourceId, double rating) async {
    try {
      final doc = await _firestore.collection(_collection).doc(resourceId).get();

      if (!doc.exists) {
        throw Exception('Resource not found');
      }

      final data = doc.data()!;
      final currentRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
      final currentCount = (data['ratingCount'] as num?)?.toInt() ?? 0;

      // Calculate new average rating
      final newCount = currentCount + 1;
      final newRating = ((currentRating * currentCount) + rating) / newCount;

      await _firestore.collection(_collection).doc(resourceId).update({
        'rating': newRating,
        'ratingCount': newCount,
      });

      // Clear cache to force refresh
      _memoryCache.remove(resourceId);
      await _diskCache.delete(resourceId);

      debugPrint('✅ Updated rating for $resourceId: $newRating ($newCount reviews)');
    } catch (e) {
      debugPrint('❌ updateResourceRating error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // UPDATE & DELETE OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Update resource
  Future<void> updateResource(ResourceModel resource) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(resource.id)
          .update(resource.toFirestoreMap()
        ..addAll({'updatedAt': FieldValue.serverTimestamp()}));

      // Update cache
      _cacheResource(resource);

      debugPrint('✅ Updated resource: ${resource.id}');
    } catch (e) {
      debugPrint('❌ updateResource error: $e');
      rethrow;
    }
  }

  /// Delete resource
  Future<void> deleteResource(String resourceId) async {
    try {
      await _firestore.collection(_collection).doc(resourceId).delete();

      // Remove from cache
      _memoryCache.remove(resourceId);
      await _diskCache.delete(resourceId);

      debugPrint('✅ Deleted resource: $resourceId');
    } catch (e) {
      debugPrint('❌ deleteResource error: $e');
      rethrow;
    }
  }

  /// Batch update resources
  Future<void> batchUpdate(List<String> ids, Map<String, dynamic> updates) async {
    try {
      final batch = _firestore.batch();

      for (var id in ids) {
        final docRef = _firestore.collection(_collection).doc(id);
        batch.update(docRef, {...updates, 'updatedAt': FieldValue.serverTimestamp()});
      }

      await batch.commit();

      // Clear cache for updated resources
      for (var id in ids) {
        _memoryCache.remove(id);
        await _diskCache.delete(id);
      }

      debugPrint('✅ Batch updated ${ids.length} resources');
    } catch (e) {
      debugPrint('❌ batchUpdate error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ANALYTICS & STATISTICS
  // ═══════════════════════════════════════════════════════════════

  /// Get comprehensive resource statistics
  Future<Map<String, dynamic>> getResourceStatistics() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();

      int totalDownloads = 0;
      int totalViews = 0;
      Map<String, int> resourcesByType = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalDownloads += (data['downloadCount'] as num?)?.toInt() ?? 0;
        totalViews += (data['viewCount'] as num?)?.toInt() ?? 0;

        final type = data['resourceType'] as String? ?? 'Unknown';
        resourcesByType[type] = (resourcesByType[type] ?? 0) + 1;
      }

      final stats = {
        'totalResources': snapshot.docs.length,
        'totalDownloads': totalDownloads,
        'totalViews': totalViews,
        'resourcesByType': resourcesByType,
      };

      debugPrint('✅ Generated resource statistics');
      return stats;
    } catch (e) {
      debugPrint('❌ getResourceStatistics error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CACHE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  /// Cache a resource in memory and disk
  void _cacheResource(ResourceModel resource) {
    try {
      _memoryCache[resource.id] = resource;
      _diskCache.put(resource.id, resource.toMap());
    } catch (e) {
      debugPrint('⚠️ Cache write error: $e');
    }
  }

  /// Clear all caches
  Future<void> clearCache() async {
    await _ensureInitialized();

    _memoryCache.clear();
    await _diskCache.clear();

    debugPrint('✅ All caches cleared');
  }

  /// Refresh specific resource cache
  Future<void> refreshResourceCache(String resourceId) async {
    try {
      _memoryCache.remove(resourceId);
      await _diskCache.delete(resourceId);

      // Fetch fresh data
      await getResourceById(resourceId);

      debugPrint('✅ Refreshed cache for: $resourceId');
    } catch (e) {
      debugPrint('❌ refreshResourceCache error: $e');
    }
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'memoryCache': _memoryCache.length,
      'diskCache': _diskCache.length,
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Check if resource exists
  Future<bool> resourceExists(String resourceId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(resourceId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('❌ resourceExists error: $e');
      return false;
    }
  }

  /// Get resource count
  Future<int> getResourceCount() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ getResourceCount error: $e');
      return 0;
    }
  }
}