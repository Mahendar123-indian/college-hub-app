import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ResourceReviewsWidget extends StatefulWidget {
  final String resourceId;
  final String userId;
  final String userName;

  const ResourceReviewsWidget({
    Key? key,
    required this.resourceId,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<ResourceReviewsWidget> createState() => _ResourceReviewsWidgetState();
}

class _ResourceReviewsWidgetState extends State<ResourceReviewsWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _reviewController = TextEditingController();

  double _selectedRating = 0;
  Map<String, bool> _selectedAspects = {
    'accuracy': false,
    'completeness': false,
    'clarity': false,
    'updated': false,
    'helpful': false,
  };

  bool _isSubmitting = false;
  bool _hasUserReviewed = false;
  Map<String, dynamic>? _userReview;

  @override
  void initState() {
    super.initState();
    _checkUserReview();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _checkUserReview() async {
    try {
      final reviewDoc = await _firestore
          .collection('resources')
          .doc(widget.resourceId)
          .collection('reviews')
          .doc(widget.userId)
          .get();

      if (reviewDoc.exists && mounted) {
        setState(() {
          _hasUserReviewed = true;
          _userReview = reviewDoc.data();
          _selectedRating = (_userReview!['rating'] ?? 0).toDouble();
          _reviewController.text = _userReview!['comment'] ?? '';
          if (_userReview!['aspects'] != null) {
            _selectedAspects = Map<String, bool>.from(_userReview!['aspects']);
          }
        });
      }
    } catch (e) {
      debugPrint('Error checking user review: $e');
    }
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final reviewData = {
        'userId': widget.userId,
        'userName': widget.userName,
        'rating': _selectedRating,
        'comment': _reviewController.text.trim(),
        'aspects': _selectedAspects,
        'timestamp': FieldValue.serverTimestamp(),
        'helpful': 0,
        'reported': false,
      };

      // Save review
      await _firestore
          .collection('resources')
          .doc(widget.resourceId)
          .collection('reviews')
          .doc(widget.userId)
          .set(reviewData, SetOptions(merge: true));

      // Update resource aggregate rating
      await _updateResourceRating();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Review submitted successfully! 🎉'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _updateResourceRating() async {
    // Get all reviews
    final reviewsSnapshot = await _firestore
        .collection('resources')
        .doc(widget.resourceId)
        .collection('reviews')
        .get();

    if (reviewsSnapshot.docs.isEmpty) return;

    double totalRating = 0;
    int count = reviewsSnapshot.docs.length;

    for (var doc in reviewsSnapshot.docs) {
      totalRating += (doc.data()['rating'] ?? 0).toDouble();
    }

    double averageRating = totalRating / count;

    // Update resource document
    await _firestore.collection('resources').doc(widget.resourceId).update({
      'rating': averageRating,
      'ratingCount': count,
    });
  }

  Future<void> _markHelpful(String reviewUserId) async {
    try {
      await _firestore
          .collection('resources')
          .doc(widget.resourceId)
          .collection('reviews')
          .doc(reviewUserId)
          .update({
        'helpful': FieldValue.increment(1),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marked as helpful!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking helpful: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Reviews & Ratings', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          _buildRatingSummary(),
          _buildWriteReviewButton(),
          Expanded(child: _buildReviewsList()),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('resources')
          .doc(widget.resourceId)
          .collection('reviews')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }

        final reviews = snapshot.data!.docs;
        if (reviews.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
              ],
            ),
            child: const Center(
              child: Text('No reviews yet. Be the first to review!'),
            ),
          );
        }

        // Calculate statistics
        double totalRating = 0;
        Map<int, int> ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

        for (var doc in reviews) {
          double rating = (doc.data() as Map)['rating'].toDouble();
          totalRating += rating;
          ratingDistribution[rating.round()] = (ratingDistribution[rating.round()] ?? 0) + 1;
        }

        double averageRating = totalRating / reviews.length;

        return Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.purple.shade50],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return Icon(
                              index < averageRating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                              color: Colors.amber,
                              size: 24,
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${reviews.length} reviews',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: List.generate(5, (index) {
                        int stars = 5 - index;
                        int count = ratingDistribution[stars] ?? 0;
                        double percentage = reviews.isEmpty ? 0 : (count / reviews.length);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text('$stars', style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 30,
                                child: Text('$count', style: const TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWriteReviewButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: _showReviewDialog,
        icon: Icon(_hasUserReviewed ? Icons.edit_rounded : Icons.rate_review_rounded),
        label: Text(_hasUserReviewed ? 'Edit Your Review' : 'Write a Review'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('resources')
          .doc(widget.resourceId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = snapshot.data!.docs;

        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('No reviews yet', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final reviewData = reviews[index].data() as Map<String, dynamic>;
            return _buildReviewCard(reviewData, reviews[index].id);
          },
        );
      },
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, String reviewId) {
    final timestamp = review['timestamp'] as Timestamp?;
    final date = timestamp?.toDate() ?? DateTime.now();
    final isCurrentUser = review['userId'] == widget.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser ? Border.all(color: Colors.blue.shade200, width: 2) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  review['userName'][0].toUpperCase(),
                  style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review['userName'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'You',
                              style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(date),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review['rating'].toInt() ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 18,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Review comment
          if (review['comment']?.isNotEmpty ?? false) ...[
            Text(
              review['comment'],
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 12),
          ],

          // Aspects
          if (review['aspects'] != null) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (review['aspects'] as Map<String, dynamic>).entries
                  .where((e) => e.value == true)
                  .map((e) => _buildAspectChip(_getAspectLabel(e.key)))
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Actions
          Row(
            children: [
              TextButton.icon(
                onPressed: isCurrentUser ? null : () => _markHelpful(reviewId),
                icon: const Icon(Icons.thumb_up_outlined, size: 16),
                label: Text('Helpful (${review['helpful'] ?? 0})'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAspectChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: Colors.green.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _getAspectLabel(String key) {
    switch (key) {
      case 'accuracy':
        return 'Accurate';
      case 'completeness':
        return 'Complete';
      case 'clarity':
        return 'Clear';
      case 'updated':
        return 'Up-to-date';
      case 'helpful':
        return 'Helpful';
      default:
        return key;
    }
  }

  void _showReviewDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _hasUserReviewed ? 'Edit Your Review' : 'Write a Review',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text('Your Rating', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRating = index + 1.0),
                      child: Icon(
                        index < _selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 48,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                const Text('What did you like?', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedAspects.keys.map((key) {
                    return FilterChip(
                      label: Text(_getAspectLabel(key)),
                      selected: _selectedAspects[key]!,
                      onSelected: (selected) {
                        setState(() => _selectedAspects[key] = selected);
                      },
                      selectedColor: Colors.green.shade100,
                      checkmarkColor: Colors.green,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                const Text('Your Review (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _reviewController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Share your experience with this resource...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}