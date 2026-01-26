import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../providers/previous_year_paper_provider.dart';
import '../../../providers/download_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/previous_year_paper_model.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../config/routes.dart';

class PaperDetailScreen extends StatefulWidget {
  final String paperId;

  const PaperDetailScreen({Key? key, required this.paperId}) : super(key: key);

  @override
  State<PaperDetailScreen> createState() => _PaperDetailScreenState();
}

class _PaperDetailScreenState extends State<PaperDetailScreen> {
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PreviousYearPaperProvider>(context, listen: false)
          .incrementViewCount(widget.paperId);
    });
  }

  Future<void> _downloadPaper(PreviousYearPaperModel paper) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);

    if (authProvider.currentUser == null) {
      Helpers.showSnackBar(
        context,
        'Please login to download papers',
        backgroundColor: AppColors.errorColor,
      );
      return;
    }

    // Check if already downloaded
    if (downloadProvider.isResourceDownloaded(paper.id)) {
      Helpers.showSnackBar(
        context,
        'Paper already downloaded',
        backgroundColor: AppColors.successColor,
      );
      return;
    }

    // Check if currently downloading
    if (downloadProvider.isResourceDownloading(paper.id)) {
      Helpers.showSnackBar(
        context,
        'Download already in progress',
        backgroundColor: AppColors.warningColor,
      );
      return;
    }

    setState(() => _isDownloading = true);

    try {
      final taskId = await downloadProvider.startDownload(
        url: paper.fileUrl,
        fileName: paper.fileName,
        resourceId: paper.id,
        resourceTitle: paper.title,
        fileSize: paper.fileSize,
        userId: authProvider.currentUser!.id,
        fileExtension: paper.fileName.split('.').last,
      );

      if (taskId != null) {
        // Increment download count
        await Provider.of<PreviousYearPaperProvider>(context, listen: false)
            .incrementDownloadCount(paper.id);

        if (mounted) {
          Helpers.showSnackBar(
            context,
            'Download started successfully!',
            backgroundColor: AppColors.successColor,
          );
        }
      } else {
        if (mounted) {
          Helpers.showSnackBar(
            context,
            downloadProvider.error ?? 'Failed to start download',
            backgroundColor: AppColors.errorColor,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Download failed: ${e.toString()}',
          backgroundColor: AppColors.errorColor,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _sharePaper(PreviousYearPaperModel paper) async {
    await Share.share(
      'Check out this paper: ${paper.title}\n'
          'Subject: ${paper.subject}\n'
          'Year: ${paper.examYear}\n'
          'Download from College Resource Hub app!',
    );
  }

  Future<void> _ratePaper(PreviousYearPaperModel paper) async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => const _RatingDialog(),
    );

    if (result != null && mounted) {
      await Provider.of<PreviousYearPaperProvider>(context, listen: false)
          .ratePaper(paper.id, result);

      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Thank you for rating!',
          backgroundColor: AppColors.successColor,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<PreviousYearPaperModel?>(
        stream: Provider.of<PreviousYearPaperProvider>(context, listen: false)
            .getPaperStream(widget.paperId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Paper not found'));
          }

          final paper = snapshot.data!;

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              paper.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              paper.subject,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => _sharePaper(paper),
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard(
                            icon: Icons.download,
                            label: 'Downloads',
                            value: paper.downloadCount.toString(),
                            color: Colors.blue,
                          ),
                          _buildStatCard(
                            icon: Icons.visibility,
                            label: 'Views',
                            value: paper.viewCount.toString(),
                            color: Colors.green,
                          ),
                          _buildStatCard(
                            icon: Icons.star,
                            label: 'Rating',
                            value: paper.rating > 0
                                ? paper.rating.toStringAsFixed(1)
                                : 'N/A',
                            color: Colors.amber,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Description
                      _buildSection('Description', paper.description),

                      // Details
                      _buildSection('Details', null, details: [
                        _buildDetailRow('Exam Year', paper.examYear),
                        _buildDetailRow('Exam Type', paper.examType),
                        _buildDetailRow('College', paper.college),
                        _buildDetailRow('Department', paper.department),
                        _buildDetailRow('Semester', paper.semester),
                        if (paper.regulation != null)
                          _buildDetailRow('Regulation', paper.regulation!),
                        _buildDetailRow('File Size', paper.fileSizeFormatted),
                        _buildDetailRow(
                          'Uploaded',
                          Helpers.formatDate(paper.uploadedAt),
                        ),
                      ]),

                      // Uploader Info
                      _buildSection('Uploaded By', null, details: [
                        _buildDetailRow('Name', paper.uploaderName),
                        _buildDetailRow('College', paper.uploaderCollege),
                        _buildDetailRow('Department', paper.uploaderDepartment),
                      ]),

                      const SizedBox(height: 24),

                      // Action Buttons with Download Status
                      Consumer<DownloadProvider>(
                        builder: (context, downloadProvider, _) {
                          final isDownloaded = downloadProvider.isResourceDownloaded(paper.id);
                          final isDownloading = downloadProvider.isResourceDownloading(paper.id);
                          final progress = downloadProvider.getDownloadProgress(paper.id);

                          return Column(
                            children: [
                              if (isDownloading) ...[
                                LinearProgressIndicator(
                                  value: progress ?? 0.0,
                                  backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Downloading... ${((progress ?? 0.0) * 100).toStringAsFixed(0)}%',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton.icon(
                                      onPressed: (_isDownloading || isDownloading || isDownloaded)
                                          ? null
                                          : () => _downloadPaper(paper),
                                      icon: Icon(
                                        isDownloaded
                                            ? Icons.check_circle
                                            : isDownloading
                                            ? Icons.downloading
                                            : Icons.download,
                                      ),
                                      label: Text(
                                        isDownloaded
                                            ? 'Downloaded'
                                            : isDownloading
                                            ? 'Downloading...'
                                            : 'Download',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDownloaded
                                            ? Colors.green
                                            : AppColors.primaryColor,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.pdfViewer,
                                          arguments: {
                                            'title': paper.title,
                                            'url': paper.fileUrl,
                                          },
                                        );
                                      },
                                      icon: const Icon(Icons.visibility),
                                      label: const Text('View'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _ratePaper(paper),
                          icon: const Icon(Icons.star_outline),
                          label: const Text('Rate this Paper'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String? content, {List<Widget>? details}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (content != null)
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        if (details != null) ...details,
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingDialog extends StatefulWidget {
  const _RatingDialog();

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  double? selectedRating;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate this Paper'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'How would you rate the quality of this paper?',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            children: List.generate(5, (index) {
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                onPressed: () {
                  setState(() {
                    selectedRating = (index + 1).toDouble();
                  });
                },
                icon: Icon(
                  selectedRating != null && index < selectedRating!
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
              );
            }),
          ),
          if (selectedRating != null) ...[
            const SizedBox(height: 8),
            Text(
              '${selectedRating!.toInt()} ${selectedRating == 1 ? "Star" : "Stars"}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedRating != null
              ? () => Navigator.pop(context, selectedRating)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
          ),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}