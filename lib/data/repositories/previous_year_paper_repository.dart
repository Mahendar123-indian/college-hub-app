import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/previous_year_paper_model.dart';

class PreviousYearPaperRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'previousYearPapers';

  // Create paper (user upload)
  Future<void> createPaper(PreviousYearPaperModel paper) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(paper.id)
          .set(paper.toFirestoreMap());

      debugPrint("✅ Previous Year Paper Created: ${paper.title}");
    } catch (e) {
      debugPrint("❌ Error creating paper: $e");
      rethrow;
    }
  }

  // Update paper
  Future<void> updatePaper(PreviousYearPaperModel paper) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(paper.id)
          .update(paper.copyWith(updatedAt: DateTime.now()).toFirestoreMap());

      debugPrint("✅ Paper updated: ${paper.id}");
    } catch (e) {
      debugPrint("❌ Error updating paper: $e");
      rethrow;
    }
  }

  // Delete paper
  Future<void> deletePaper(String paperId) async {
    try {
      await _firestore.collection(_collection).doc(paperId).delete();
      debugPrint("✅ Paper deleted: $paperId");
    } catch (e) {
      debugPrint("❌ Error deleting paper: $e");
      rethrow;
    }
  }

  // Get paper by ID
  Future<PreviousYearPaperModel?> getPaperById(String paperId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(paperId).get();
      if (doc.exists) {
        return PreviousYearPaperModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error getting paper: $e");
      rethrow;
    }
  }

  // Get real-time paper stream
  Stream<PreviousYearPaperModel?> getPaperStream(String paperId) {
    return _firestore
        .collection(_collection)
        .doc(paperId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return PreviousYearPaperModel.fromDocument(snapshot);
      }
      return null;
    });
  }

  // Get all approved papers (for students)
  Future<List<PreviousYearPaperModel>> getApprovedPapers({int limit = 100}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'approved')
          .where('isActive', isEqualTo: true)
          .limit(limit)
          .get();

      final papers = snapshot.docs
          .map((doc) => PreviousYearPaperModel.fromDocument(doc))
          .toList();

      // Sort by upload date (newest first)
      papers.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      return papers;
    } catch (e) {
      debugPrint("❌ Error loading approved papers: $e");
      rethrow;
    }
  }

  // Get papers by filters
  Future<List<PreviousYearPaperModel>> getPapersByFilters({
    String? college,
    String? department,
    String? semester,
    String? subject,
    String? examYear,
    String? examType,
    String? regulation,
    bool onlyApproved = true,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      // Base filters
      if (onlyApproved) {
        query = query.where('status', isEqualTo: 'approved');
      }
      query = query.where('isActive', isEqualTo: true);

      // Dynamic filters
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
      if (examYear != null && examYear.isNotEmpty) {
        query = query.where('examYear', isEqualTo: examYear);
      }
      if (examType != null && examType.isNotEmpty) {
        query = query.where('examType', isEqualTo: examType);
      }
      if (regulation != null && regulation.isNotEmpty) {
        query = query.where('regulation', isEqualTo: regulation);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      final papers = snapshot.docs
          .map((doc) => PreviousYearPaperModel.fromDocument(doc))
          .toList();

      // Sort in memory
      papers.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      return papers;
    } catch (e) {
      debugPrint("❌ Error filtering papers: $e");
      rethrow;
    }
  }

  // Search papers
  Future<List<PreviousYearPaperModel>> searchPapers(String searchQuery, {bool onlyApproved = true}) async {
    try {
      Query query = _firestore.collection(_collection);

      if (onlyApproved) {
        query = query.where('status', isEqualTo: 'approved');
      }
      query = query.where('isActive', isEqualTo: true).limit(100);

      final snapshot = await query.get();

      // Client-side filtering
      final results = snapshot.docs
          .map((doc) => PreviousYearPaperModel.fromDocument(doc))
          .where((paper) {
        final query = searchQuery.toLowerCase();
        return paper.title.toLowerCase().contains(query) ||
            paper.subject.toLowerCase().contains(query) ||
            paper.examYear.contains(query) ||
            paper.college.toLowerCase().contains(query) ||
            paper.department.toLowerCase().contains(query) ||
            paper.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();

      results.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      return results;
    } catch (e) {
      debugPrint("❌ Search error: $e");
      return [];
    }
  }

  // Get papers by uploader
  Future<List<PreviousYearPaperModel>> getPapersByUploader(String uploaderId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('uploadedBy', isEqualTo: uploaderId)
          .get();

      final papers = snapshot.docs
          .map((doc) => PreviousYearPaperModel.fromDocument(doc))
          .toList();

      papers.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      return papers;
    } catch (e) {
      debugPrint("❌ Error getting user papers: $e");
      rethrow;
    }
  }

  // Get pending papers (for admin moderation)
  Future<List<PreviousYearPaperModel>> getPendingPapers({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'pending')
          .where('isActive', isEqualTo: true)
          .limit(limit)
          .get();

      final papers = snapshot.docs
          .map((doc) => PreviousYearPaperModel.fromDocument(doc))
          .toList();

      papers.sort((a, b) => a.uploadedAt.compareTo(b.uploadedAt)); // Oldest first

      return papers;
    } catch (e) {
      debugPrint("❌ Error loading pending papers: $e");
      rethrow;
    }
  }

  // Approve paper (admin action)
  Future<void> approvePaper(String paperId, String adminId) async {
    try {
      await _firestore.collection(_collection).doc(paperId).update({
        'status': 'approved',
        'approvedAt': Timestamp.now(),
        'approvedBy': adminId,
        'updatedAt': Timestamp.now(),
      });
      debugPrint("✅ Paper approved: $paperId");
    } catch (e) {
      debugPrint("❌ Error approving paper: $e");
      rethrow;
    }
  }

  // Reject paper (admin action)
  Future<void> rejectPaper(String paperId, String reason) async {
    try {
      await _firestore.collection(_collection).doc(paperId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'updatedAt': Timestamp.now(),
      });
      debugPrint("✅ Paper rejected: $paperId");
    } catch (e) {
      debugPrint("❌ Error rejecting paper: $e");
      rethrow;
    }
  }

  // Increment download count
  Future<void> incrementDownloadCount(String paperId) async {
    try {
      await _firestore.collection(_collection).doc(paperId).update({
        'downloadCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint("❌ Metric error: $e");
    }
  }

  // Increment view count
  Future<void> incrementViewCount(String paperId) async {
    try {
      await _firestore.collection(_collection).doc(paperId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint("❌ Metric error: $e");
    }
  }

  // Update rating
  Future<void> updateRating(String paperId, double rating) async {
    try {
      final doc = await _firestore.collection(_collection).doc(paperId).get();

      if (doc.exists) {
        final paper = PreviousYearPaperModel.fromDocument(doc);
        final newRatingCount = paper.ratingCount + 1;
        final newRating = ((paper.rating * paper.ratingCount) + rating) / newRatingCount;

        await _firestore.collection(_collection).doc(paperId).update({
          'rating': newRating,
          'ratingCount': newRatingCount,
        });
      }
    } catch (e) {
      debugPrint("❌ Rating error: $e");
      rethrow;
    }
  }

  // Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      int total = snapshot.docs.length;
      int approved = 0;
      int pending = 0;
      int rejected = 0;
      int totalDownloads = 0;
      Map<String, int> papersByYear = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'pending';

        if (status == 'approved') approved++;
        if (status == 'pending') pending++;
        if (status == 'rejected') rejected++;

        totalDownloads += (data['downloadCount'] ?? 0) as int;

        String year = data['examYear'] ?? 'Unknown';
        papersByYear[year] = (papersByYear[year] ?? 0) + 1;
      }

      return {
        'total': total,
        'approved': approved,
        'pending': pending,
        'rejected': rejected,
        'totalDownloads': totalDownloads,
        'papersByYear': papersByYear,
      };
    } catch (e) {
      debugPrint("❌ Statistics error: $e");
      rethrow;
    }
  }

  // Get most downloaded papers
  Future<List<PreviousYearPaperModel>> getMostDownloadedPapers({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'approved')
          .where('isActive', isEqualTo: true)
          .limit(50)
          .get();

      final papers = snapshot.docs
          .map((doc) => PreviousYearPaperModel.fromDocument(doc))
          .toList();

      papers.sort((a, b) => b.downloadCount.compareTo(a.downloadCount));

      return papers.take(limit).toList();
    } catch (e) {
      debugPrint("❌ Error getting top papers: $e");
      rethrow;
    }
  }

  // Get recently added papers
  Future<List<PreviousYearPaperModel>> getRecentPapers({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'approved')
          .where('isActive', isEqualTo: true)
          .limit(limit)
          .get();

      final papers = snapshot.docs
          .map((doc) => PreviousYearPaperModel.fromDocument(doc))
          .toList();

      papers.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      return papers;
    } catch (e) {
      debugPrint("❌ Error getting recent papers: $e");
      rethrow;
    }
  }
}