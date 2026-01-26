import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../../../data/models/review_model.dart';
import '../../../providers/review_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';

class SubmitReviewScreen extends StatefulWidget {
  final ReviewModel? existingReview; // For editing

  const SubmitReviewScreen({Key? key, this.existingReview}) : super(key: key);

  @override
  State<SubmitReviewScreen> createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends State<SubmitReviewScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _reviewController = TextEditingController();

  double _rating = 5.0;
  bool _isSubmitting = false;
  late AnimationController _scaleController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();

    // Initialize with existing review data if editing
    if (widget.existingReview != null) {
      _rating = widget.existingReview!.rating;
      _reviewController.text = widget.existingReview!.reviewText;
    }

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<String> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model} (Android ${androidInfo.version.release})';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.name} ${iosInfo.model} (iOS ${iosInfo.systemVersion})';
      }
    } catch (e) {
      print('Failed to get device info: $e');
    }
    return 'Unknown Device';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);

    if (authProvider.currentUser == null) {
      _showSnackbar('Please login to submit a review', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final deviceInfo = await _getDeviceInfo();
      final user = authProvider.currentUser!;

      final review = ReviewModel(
        id: widget.existingReview?.id ?? const Uuid().v4(),
        userId: user.id,
        userName: user.name,
        userEmail: user.email,
        userPhotoUrl: user.photoUrl,
        rating: _rating,
        reviewText: _reviewController.text.trim(),
        createdAt: widget.existingReview?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        appVersion: AppConstants.appVersion,
        deviceInfo: deviceInfo,
        isActive: true,
      );

      bool success;
      if (widget.existingReview != null) {
        success = await reviewProvider.updateReview(review);
      } else {
        success = await reviewProvider.submitReview(review);
      }

      if (success && mounted) {
        _showSuccessDialog();
      } else if (mounted) {
        _showSnackbar(
          reviewProvider.errorMessage ?? 'Failed to submit review',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            ),
            const SizedBox(height: 20),
            Text(
              widget.existingReview != null ? 'Review Updated!' : 'Thank You!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              widget.existingReview != null
                  ? 'Your review has been updated successfully.'
                  : 'Your feedback helps us improve the app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.existingReview != null ? 'Edit Review' : 'Write a Review',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: BackButton(color: isDark ? Colors.white : Colors.black87),
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF0A0E27), const Color(0xFF1A1F3A), const Color(0xFF2D1B4E)]
                    : [const Color(0xFFEEF2FF), const Color(0xFFDDD6FE), const Color(0xFFFCE7F3)],
              ),
            ),
          ),

          // Ambient Glow
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purpleAccent.withOpacity(isDark ? 0.15 : 0.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withOpacity(isDark ? 0.15 : 0.1),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeController,
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _scaleController,
                  curve: Curves.easeOutBack,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Rating Card
                        _buildGlassCard(
                          child: Column(
                            children: [
                              Text(
                                'Rate Your Experience',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              RatingBar.builder(
                                initialRating: _rating,
                                minRating: 1,
                                direction: Axis.horizontal,
                                allowHalfRating: false,
                                itemCount: 5,
                                itemSize: 50,
                                unratedColor: Colors.grey.withOpacity(0.3),
                                itemBuilder: (context, _) => const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                ),
                                onRatingUpdate: (rating) {
                                  setState(() => _rating = rating);
                                },
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _getRatingText(_rating),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _getRatingColor(_rating),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Review Text Card
                        _buildGlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Share Your Thoughts',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _reviewController,
                                maxLines: 6,
                                maxLength: 500,
                                decoration: InputDecoration(
                                  hintText: 'Tell us what you think about the app...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.withOpacity(0.3),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please write a review';
                                  }
                                  if (value.trim().length < 10) {
                                    return 'Review must be at least 10 characters';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              disabledBackgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: Colors.blue.withOpacity(0.5),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                                : Text(
                              widget.existingReview != null ? 'Update Review' : 'Submit Review',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withOpacity(0.6)
                : Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.4),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 5) return 'Excellent! 🌟';
    if (rating >= 4) return 'Great! 😊';
    if (rating >= 3) return 'Good 👍';
    if (rating >= 2) return 'Okay 😐';
    return 'Needs Improvement 😕';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.blue;
    if (rating >= 2) return Colors.orange;
    return Colors.red;
  }
}