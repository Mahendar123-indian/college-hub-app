import 'package:flutter/foundation.dart';
import '../data/models/review_model.dart';
import '../data/services/review_service.dart';

class ReviewProvider with ChangeNotifier {
  final ReviewService _reviewService = ReviewService();

  List<ReviewModel> _reviews = [];
  Map<String, dynamic> _statistics = {
    'totalReviews': 0,
    'averageRating': 0.0,
    'ratingDistribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
  };

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ReviewModel> get reviews => _reviews;
  Map<String, dynamic> get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalReviews => _statistics['totalReviews'] as int;
  double get averageRating => _statistics['averageRating'] as double;

  // Listen to all reviews
  void listenToReviews() {
    _reviewService.getAllReviewsStream().listen(
          (reviews) {
        _reviews = reviews;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Failed to load reviews: $error';
        notifyListeners();
      },
    );
  }

  // Load review statistics
  Future<void> loadStatistics() async {
    try {
      _statistics = await _reviewService.getReviewStatistics();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load statistics: $e';
      notifyListeners();
    }
  }

  // Submit a new review
  Future<bool> submitReview(ReviewModel review) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if user has already reviewed
      final hasReviewed = await _reviewService.hasUserReviewed(review.userId);

      if (hasReviewed) {
        _errorMessage = 'You have already submitted a review. You can edit your existing review.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _reviewService.createReview(review);
      await loadStatistics(); // Refresh statistics

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to submit review: $e';
      notifyListeners();
      return false;
    }
  }

  // Update existing review
  Future<bool> updateReview(ReviewModel review) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reviewService.updateReview(review);
      await loadStatistics(); // Refresh statistics

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update review: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete review
  Future<bool> deleteReview(String reviewId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reviewService.deleteReview(reviewId);
      await loadStatistics(); // Refresh statistics

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete review: $e';
      notifyListeners();
      return false;
    }
  }

  // Add admin reply
  Future<bool> addAdminReply(String reviewId, String reply) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reviewService.addAdminReply(reviewId, reply);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to add reply: $e';
      notifyListeners();
      return false;
    }
  }

  // Get user's existing review
  Future<ReviewModel?> getUserReview(String userId) async {
    try {
      return await _reviewService.getUserReview(userId);
    } catch (e) {
      _errorMessage = 'Failed to get user review: $e';
      notifyListeners();
      return null;
    }
  }

  // Check if user has reviewed
  Future<bool> hasUserReviewed(String userId) async {
    try {
      return await _reviewService.hasUserReviewed(userId);
    } catch (e) {
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}