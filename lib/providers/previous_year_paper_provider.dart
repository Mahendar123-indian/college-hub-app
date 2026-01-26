import 'package:flutter/foundation.dart';
import '../data/models/previous_year_paper_model.dart';
import '../data/repositories/previous_year_paper_repository.dart';

class PreviousYearPaperProvider with ChangeNotifier {
  final PreviousYearPaperRepository _repository = PreviousYearPaperRepository();

  List<PreviousYearPaperModel> _papers = [];
  List<PreviousYearPaperModel> _pendingPapers = [];
  List<PreviousYearPaperModel> _myPapers = [];
  List<PreviousYearPaperModel> _searchResults = [];
  List<PreviousYearPaperModel> _recentPapers = [];
  List<PreviousYearPaperModel> _topPapers = [];

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic> _statistics = {};

  // ═══════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════
  List<PreviousYearPaperModel> get papers => _papers;
  List<PreviousYearPaperModel> get pendingPapers => _pendingPapers;
  List<PreviousYearPaperModel> get myPapers => _myPapers;
  List<PreviousYearPaperModel> get searchResults => _searchResults;
  List<PreviousYearPaperModel> get recentPapers => _recentPapers;
  List<PreviousYearPaperModel> get topPapers => _topPapers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get statistics => _statistics;

  // ═══════════════════════════════════════════════════════════════
  // METHODS
  // ═══════════════════════════════════════════════════════════════

  Future<void> fetchApprovedPapers({int limit = 100}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _papers = await _repository.getApprovedPapers(limit: limit);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to fetch papers: $e';
      notifyListeners();
    }
  }

  Future<void> fetchPapersByFilters({
    String? college,
    String? department,
    String? semester,
    String? subject,
    String? examYear,
    String? examType,
    String? regulation,
    bool onlyApproved = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _papers = await _repository.getPapersByFilters(
        college: college,
        department: department,
        semester: semester,
        subject: subject,
        examYear: examYear,
        examType: examType,
        regulation: regulation,
        onlyApproved: onlyApproved,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to filter papers: $e';
      notifyListeners();
    }
  }

  Future<void> searchPapers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _searchResults = await _repository.searchPapers(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Search failed: $e';
      notifyListeners();
    }
  }

  Future<void> fetchPendingPapers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _pendingPapers = await _repository.getPendingPapers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to fetch pending papers: $e';
      notifyListeners();
    }
  }

  Future<void> fetchMyPapers(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myPapers = await _repository.getPapersByUploader(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to fetch your papers: $e';
      notifyListeners();
    }
  }

  Future<void> fetchRecentPapers() async {
    try {
      _recentPapers = await _repository.getRecentPapers();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch recent papers: $e';
      notifyListeners();
    }
  }

  Future<void> fetchTopPapers() async {
    try {
      _topPapers = await _repository.getMostDownloadedPapers();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch top papers: $e';
      notifyListeners();
    }
  }

  Future<PreviousYearPaperModel?> getPaperById(String paperId) async {
    try {
      return await _repository.getPaperById(paperId);
    } catch (e) {
      _errorMessage = 'Failed to fetch paper: $e';
      notifyListeners();
      return null;
    }
  }

  Stream<PreviousYearPaperModel?> getPaperStream(String paperId) {
    try {
      return _repository.getPaperStream(paperId);
    } catch (e) {
      _errorMessage = 'Failed to listen to paper updates: $e';
      notifyListeners();
      return Stream.value(null);
    }
  }

  Future<bool> createPaper(PreviousYearPaperModel paper) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.createPaper(paper);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to upload paper: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePaper(PreviousYearPaperModel paper) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updatePaper(paper);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update paper: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePaper(String paperId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deletePaper(paperId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete paper: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> approvePaper(String paperId, String adminId) async {
    try {
      await _repository.approvePaper(paperId, adminId);
      _pendingPapers.removeWhere((p) => p.id == paperId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to approve paper: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectPaper(String paperId, String reason) async {
    try {
      await _repository.rejectPaper(paperId, reason);
      _pendingPapers.removeWhere((p) => p.id == paperId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to reject paper: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> incrementDownloadCount(String paperId) async {
    try {
      await _repository.incrementDownloadCount(paperId);
    } catch (e) {
      debugPrint('Failed to increment download count: $e');
    }
  }

  Future<void> incrementViewCount(String paperId) async {
    try {
      await _repository.incrementViewCount(paperId);
    } catch (e) {
      debugPrint('Failed to increment view count: $e');
    }
  }

  Future<void> ratePaper(String paperId, double rating) async {
    try {
      await _repository.updateRating(paperId, rating);
    } catch (e) {
      _errorMessage = 'Failed to rate paper: $e';
      notifyListeners();
    }
  }

  Future<void> fetchStatistics() async {
    try {
      _statistics = await _repository.getStatistics();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch statistics: $e';
      notifyListeners();
    }
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchApprovedPapers(),
      fetchRecentPapers(),
      fetchTopPapers(),
    ]);
  }
}