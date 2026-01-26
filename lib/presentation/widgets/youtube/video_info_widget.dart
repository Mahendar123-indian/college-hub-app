import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/color_constants.dart';
import '../../../data/models/youtube_video_model.dart';

class VideoInfoWidget extends StatelessWidget {
  final YouTubeVideoModel video;
  final bool isFavorite;
  final bool isInWatchLater;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onWatchLaterToggle;
  final VoidCallback onShare;
  final bool showDescription;
  final VoidCallback onToggleDescription;

  const VideoInfoWidget({
    Key? key,
    required this.video,
    required this.isFavorite,
    required this.isInWatchLater,
    required this.onFavoriteToggle,
    required this.onWatchLaterToggle,
    required this.onShare,
    required this.showDescription,
    required this.onToggleDescription,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Title
          Text(
            video.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Stats Row
          Row(
            children: [
              _buildStatChip(
                Icons.remove_red_eye_outlined,
                _formatViews(video.viewCount),
                AppColors.infoColor,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                Icons.thumb_up_outlined,
                _formatLikes(video.likeCount),
                AppColors.successColor,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                Icons.access_time,
                _formatDate(video.publishedAt),
                AppColors.warningColor,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                label: 'Favorite',
                color: isFavorite ? Colors.red : Colors.grey[700]!,
                onTap: onFavoriteToggle,
              ),
              _buildActionButton(
                icon: isInWatchLater
                    ? Icons.watch_later
                    : Icons.watch_later_outlined,
                label: 'Watch Later',
                color: isInWatchLater ? AppColors.primaryColor : Colors.grey[700]!,
                onTap: onWatchLaterToggle,
              ),
              _buildActionButton(
                icon: Icons.share,
                label: 'Share',
                color: Colors.grey[700]!,
                onTap: onShare,
              ),
              _buildActionButton(
                icon: Icons.playlist_add,
                label: 'Playlist',
                color: Colors.grey[700]!,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Playlist feature coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Channel Info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.channelName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Educational Channel',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  // Open channel (can implement later)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening ${video.channelName}...'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                  side: const BorderSide(
                    color: AppColors.primaryColor,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'VISIT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Tags
          if (video.keyTopics.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTag(video.difficulty, _getDifficultyColor(video.difficulty)),
                _buildTag(video.suitableFor, AppColors.infoColor),
                if (video.subject != null)
                  _buildTag(video.subject!, AppColors.primaryColor),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Description Toggle
          GestureDetector(
            onTap: onToggleDescription,
            child: Row(
              children: [
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Icon(
                  showDescription
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),

          // Description Content
          if (showDescription) ...[
            const SizedBox(height: 12),
            Text(
              video.description.isNotEmpty
                  ? video.description
                  : 'No description available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return AppColors.successColor;
      case 'Medium':
        return AppColors.warningColor;
      case 'Advanced':
        return AppColors.errorColor;
      default:
        return AppColors.primaryColor;
    }
  }

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    } else {
      return '$views';
    }
  }

  String _formatLikes(int likes) {
    if (likes >= 1000000) {
      return '${(likes / 1000000).toStringAsFixed(1)}M';
    } else if (likes >= 1000) {
      return '${(likes / 1000).toStringAsFixed(1)}K';
    } else {
      return '$likes';
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
}