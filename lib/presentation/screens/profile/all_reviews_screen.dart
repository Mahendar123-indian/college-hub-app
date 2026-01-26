import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/review_model.dart';
import '../../../providers/review_provider.dart';
import '../../../providers/auth_provider.dart';
import 'submit_review_screen.dart';

class AllReviewsScreen extends StatefulWidget {
  const AllReviewsScreen({Key? key}) : super(key: key);

  @override
  State<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends State<AllReviewsScreen> {
  String _sortBy = 'newest'; // newest, oldest, highest, lowest

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
      reviewProvider.listenToReviews();
      reviewProvider.loadStatistics();
    });
  }

  List<ReviewModel> _getSortedReviews(List<ReviewModel> reviews) {
    final sortedList = List<ReviewModel>.from(reviews);

    switch (_sortBy) {
      case 'newest':
        sortedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        sortedList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'highest':
        sortedList.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'lowest':
        sortedList.sort((a, b) => a.rating.compareTo(b.rating));
        break;
    }

    return sortedList;
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sort Reviews',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildSortOption('Newest First', 'newest', Icons.access_time),
            _buildSortOption('Oldest First', 'oldest', Icons.history),
            _buildSortOption('Highest Rating', 'highest', Icons.star),
            _buildSortOption('Lowest Rating', 'lowest', Icons.star_border),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, String value, IconData icon) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.blue : null,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
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
          'All Reviews',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: BackButton(color: isDark ? Colors.white : Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: _showSortOptions,
          ),
        ],
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

          SafeArea(
            child: Consumer<ReviewProvider>(
              builder: (context, reviewProvider, child) {
                if (reviewProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sortedReviews = _getSortedReviews(reviewProvider.reviews);

                return Column(
                  children: [
                    // Statistics Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildStatisticsCard(reviewProvider),
                    ),

                    // Reviews List
                    Expanded(
                      child: sortedReviews.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: sortedReviews.length,
                        itemBuilder: (context, index) {
                          return _buildReviewCard(sortedReviews[index]);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(ReviewProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.star_rounded,
                value: provider.averageRating.toStringAsFixed(1),
                label: 'Average',
                color: Colors.amber,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.withOpacity(0.3),
              ),
              _buildStatItem(
                icon: Icons.rate_review_rounded,
                value: provider.totalReviews.toString(),
                label: 'Reviews',
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwnReview = authProvider.currentUser?.id == review.userId;
    final isAdmin = authProvider.isAdmin;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withOpacity(0.5)
                  : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: review.userPhotoUrl != null
                          ? NetworkImage(review.userPhotoUrl!)
                          : null,
                      child: review.userPhotoUrl == null
                          ? Text(
                        review.userName[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            DateFormat('MMM dd, yyyy').format(review.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isOwnReview)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SubmitReviewScreen(
                                existingReview: review,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Rating
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),

                const SizedBox(height: 12),

                // Review Text
                Text(
                  review.reviewText,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),

                // Admin Reply
                if (review.adminReply != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.admin_panel_settings, size: 16, color: Colors.blue),
                            const SizedBox(width: 6),
                            Text(
                              'Developer Reply',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          review.adminReply!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],

                // Admin Actions
                if (isAdmin && review.adminReply == null) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => _showAdminReplyDialog(review),
                    icon: const Icon(Icons.reply, size: 18),
                    label: const Text('Reply to Review'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAdminReplyDialog(ReviewModel review) {
    final replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reply to Review'),
        content: TextField(
          controller: replyController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Write your reply...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (replyController.text.trim().isNotEmpty) {
                final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
                await reviewProvider.addAdminReply(review.id, replyController.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reply added successfully')),
                  );
                }
              }
            },
            child: const Text('Send Reply'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to review this app!',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}