import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/color_constants.dart';
import '../../../data/models/youtube_video_model.dart';

class ChapterMarkersWidget extends StatefulWidget {
  final List<VideoTimestamp> chapters;
  final Duration currentPosition;
  final Duration totalDuration;
  final Function(VideoTimestamp) onChapterTap;

  const ChapterMarkersWidget({
    Key? key,
    required this.chapters,
    required this.currentPosition,
    required this.totalDuration,
    required this.onChapterTap,
  }) : super(key: key);

  @override
  State<ChapterMarkersWidget> createState() => _ChapterMarkersWidgetState();
}

class _ChapterMarkersWidgetState extends State<ChapterMarkersWidget> {
  int? _currentChapterIndex;

  @override
  void didUpdateWidget(ChapterMarkersWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPosition != widget.currentPosition) {
      _updateCurrentChapter();
    }
  }

  void _updateCurrentChapter() {
    final currentSeconds = widget.currentPosition.inSeconds;

    for (int i = 0; i < widget.chapters.length; i++) {
      final chapter = widget.chapters[i];
      final chapterSeconds = chapter.timeInSeconds;

      // Check if current position is within this chapter
      if (i == widget.chapters.length - 1) {
        // Last chapter
        if (currentSeconds >= chapterSeconds) {
          setState(() => _currentChapterIndex = i);
          break;
        }
      } else {
        final nextChapterSeconds = widget.chapters[i + 1].timeInSeconds;
        if (currentSeconds >= chapterSeconds && currentSeconds < nextChapterSeconds) {
          setState(() => _currentChapterIndex = i);
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chapters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primaryColor,
                        AppColors.accentColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.video_library,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Video Chapters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Progress Bar with Chapter Markers
          _buildChapterProgressBar(),

          const SizedBox(height: 16),

          // Chapter List
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.chapters.length,
              itemBuilder: (context, index) {
                final chapter = widget.chapters[index];
                final isActive = _currentChapterIndex == index;
                return _buildChapterCard(chapter, index, isActive);
              },
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildChapterProgressBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          // Progress Fill
          FractionallySizedBox(
            widthFactor: widget.totalDuration.inSeconds > 0
                ? widget.currentPosition.inSeconds / widget.totalDuration.inSeconds
                : 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primaryColor,
                    AppColors.accentColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Chapter Markers
          ...widget.chapters.asMap().entries.map((entry) {
            final index = entry.key;
            final chapter = entry.value;
            final position = widget.totalDuration.inSeconds > 0
                ? chapter.timeInSeconds / widget.totalDuration.inSeconds
                : 0;

            return Positioned(
              left: position * MediaQuery.of(context).size.width - 32 - 16,
              child: Container(
                width: 2,
                height: 8,
                color: Colors.white,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildChapterCard(
      VideoTimestamp chapter,
      int index,
      bool isActive,
      ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onChapterTap(chapter);
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.primaryColor : Colors.grey[300]!,
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Chapter Number
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withOpacity(0.3)
                        : AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Ch ${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : AppColors.primaryColor,
                    ),
                  ),
                ),
                const Spacer(),

                // Time Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    chapter.time,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Chapter Label
            Text(
              chapter.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.black,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const Spacer(),

            // Play Button
            if (isActive)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Now Playing',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else
              Icon(
                Icons.play_circle_outline,
                color: Colors.grey[400],
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}