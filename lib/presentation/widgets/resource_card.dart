import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/resource_model.dart';
import '../../core/constants/color_constants.dart';
import '../../providers/youtube_provider.dart';

class ResourceCard extends StatefulWidget {
  final ResourceModel resource;
  final VoidCallback onTap;

  const ResourceCard({
    Key? key,
    required this.resource,
    required this.onTap,
  }) : super(key: key);

  @override
  State<ResourceCard> createState() => _ResourceCardState();
}

class _ResourceCardState extends State<ResourceCard> {
  int _videoCount = 0;
  bool _isLoadingVideos = false;
  bool _hasLoadedVideos = false;

  @override
  void initState() {
    super.initState();
    // ✅ CRITICAL FIX: Schedule video loading for AFTER the first frame is rendered
    // This completely avoids any setState during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadVideoCount();
      }
    });
  }

  Future<void> _loadVideoCount() async {
    if (!mounted || _hasLoadedVideos) return;

    // ✅ SAFE: We're outside the build phase now
    setState(() {
      _isLoadingVideos = true;
      _hasLoadedVideos = true; // Prevent duplicate loads
    });

    try {
      final youtubeProvider = Provider.of<YouTubeProvider>(context, listen: false);

      // ✅ FIX: Get videos directly from Firestore WITHOUT using provider state
      // This avoids ANY potential setState during build issues
      final videos = await youtubeProvider.getVideosForResourceDirect(widget.resource.id);

      if (mounted) {
        setState(() {
          _videoCount = videos.length;
          _isLoadingVideos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingVideos = false;
        });
      }
      debugPrint('⚠️ Failed to load video count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isNarrow = width < 200;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getResourceColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.resource.resourceType,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _getResourceColor(),
                              fontWeight: FontWeight.w600,
                              fontSize: isNarrow ? 10 : 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (widget.resource.isTrending && !isNarrow) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warningColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.trending_up, size: 10, color: Colors.white),
                              const SizedBox(width: 2),
                              Text(
                                'Hot',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // ✅ Video Count Badge with Loading State
                      if (_isLoadingVideos && !isNarrow) ...[
                        const SizedBox(width: 6),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ] else if (_videoCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.play_circle_outline, size: 10, color: Colors.white),
                              const SizedBox(width: 2),
                              Text(
                                '$_videoCount',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  SizedBox(height: isNarrow ? 6 : 10),

                  // Title
                  Text(
                    widget.resource.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isNarrow ? 13 : 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: isNarrow ? 4 : 6),

                  // Subject Line
                  Row(
                    children: [
                      Icon(Icons.school_outlined, size: isNarrow ? 12 : 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.resource.subject,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: isNarrow ? 10 : 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isNarrow ? 3 : 4),

                  // Stats Line - Vertical layout for narrow screens
                  if (isNarrow)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.insert_drive_file_outlined, size: 11, color: Colors.grey[600]),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                widget.resource.fileSizeFormatted,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.download_outlined, size: 11, color: Colors.grey[600]),
                            const SizedBox(width: 3),
                            Text(
                              '${widget.resource.downloadCount}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Icon(Icons.insert_drive_file_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.resource.fileSizeFormatted,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.download_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.resource.downloadCount}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                  SizedBox(height: isNarrow ? 4 : 6),

                  Divider(height: 1, thickness: isNarrow ? 0.5 : 1),

                  SizedBox(height: isNarrow ? 4 : 6),

                  // Footer - Show only rating for very narrow, full info otherwise
                  if (isNarrow)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 11, color: AppColors.warningColor),
                        const SizedBox(width: 3),
                        Text(
                          widget.resource.rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            DateFormat('MMM dd, yyyy').format(widget.resource.uploadedAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.star, size: 13, color: AppColors.warningColor),
                        const SizedBox(width: 3),
                        Text(
                          widget.resource.rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Color _getResourceColor() {
    switch (widget.resource.resourceType) {
      case 'Mid-Exam Papers': return AppColors.categoryMidExam;
      case 'Semester Exam Papers': return AppColors.categorySemesterExam;
      case 'Previous Year Papers': return AppColors.categoryPreviousYear;
      case 'Class Notes': return AppColors.categoryNotes;
      case 'Syllabus': return AppColors.categorySyllabus;
      case 'Reference Books': return AppColors.categoryReference;
      default: return AppColors.primaryColor;
    }
  }
}