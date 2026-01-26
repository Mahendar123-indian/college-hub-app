import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/download_model.dart';
import '../../../providers/download_provider.dart';
import '../../../providers/auth_provider.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Sync downloads with Firestore on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentUser != null) {
        final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
        downloadProvider.syncWithFirestore(auth.currentUser!.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Downloads'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear All Downloads',
            onPressed: () => _clearAllDownloads(context),
          ),
        ],
      ),
      body: Consumer<DownloadProvider>(
        builder: (context, downloadProvider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildDownloadsList(downloadProvider.downloads),
              _buildDownloadsList(downloadProvider.activeDownloadsList),
              _buildDownloadsList(downloadProvider.completedDownloadsList),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDownloadsList(List<DownloadModel> downloads) {
    if (downloads.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
        await downloadProvider.loadDownloads();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: downloads.length,
        itemBuilder: (context, index) {
          final download = downloads[index];
          return _buildDownloadCard(download);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Background illustration
              Image.asset(
                'assets/images/illustrations/no_downloads.png',
                width: 250,
                height: 250,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              Text(
                'No Downloads Yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Downloaded files will appear here.\nStart exploring resources!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadCard(DownloadModel download) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: download.isCompleted ? () => _openFile(download) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File Icon with Status
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: _getStatusGradient(download),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor(download).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getStatusIcon(download),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Title and Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          download.resourceTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              _getFileTypeIcon(download.fileExtension),
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              download.fileSizeFormatted,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (download.fileExtension != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  download.fileExtension!.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // More Options Menu
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => _buildMenuItems(download),
                    onSelected: (value) => _handleMenuAction(value as String, download),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Status Display
              _buildStatusDisplay(download),
            ],
          ),
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(DownloadModel download) {
    final items = <PopupMenuEntry<String>>[];

    if (download.isCompleted) {
      items.addAll([
        const PopupMenuItem(
          value: 'open',
          child: Row(
            children: [
              Icon(Icons.open_in_new, size: 20),
              SizedBox(width: 12),
              Text('Open File'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 20),
              SizedBox(width: 12),
              Text('Share'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'location',
          child: Row(
            children: [
              Icon(Icons.folder_open, size: 20),
              SizedBox(width: 12),
              Text('Show Location'),
            ],
          ),
        ),
      ]);
    }

    if (download.canPause) {
      items.add(
        const PopupMenuItem(
          value: 'pause',
          child: Row(
            children: [
              Icon(Icons.pause, size: 20),
              SizedBox(width: 12),
              Text('Pause'),
            ],
          ),
        ),
      );
    }

    if (download.canResume) {
      items.add(
        const PopupMenuItem(
          value: 'resume',
          child: Row(
            children: [
              Icon(Icons.play_arrow, size: 20),
              SizedBox(width: 12),
              Text('Resume'),
            ],
          ),
        ),
      );
    }

    if (download.canRetry) {
      items.add(
        const PopupMenuItem(
          value: 'retry',
          child: Row(
            children: [
              Icon(Icons.refresh, size: 20),
              SizedBox(width: 12),
              Text('Retry'),
            ],
          ),
        ),
      );
    }

    if (download.canCancel) {
      items.add(
        const PopupMenuItem(
          value: 'cancel',
          child: Row(
            children: [
              Icon(Icons.cancel, color: Colors.orange, size: 20),
              SizedBox(width: 12),
              Text('Cancel', style: TextStyle(color: Colors.orange)),
            ],
          ),
        ),
      );
    }

    items.add(
      const PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete, color: Colors.red, size: 20),
            SizedBox(width: 12),
            Text('Delete', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );

    return items;
  }

  Widget _buildStatusDisplay(DownloadModel download) {
    if (download.isDownloading) {
      return Column(
        children: [
          LinearProgressIndicator(
            value: download.progress,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  download.statusDisplayText,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                download.progressPercent,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (download.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Completed ${Helpers.formatTimeAgo(download.completedAt ?? download.downloadedAt)}',
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (download.isFailed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, color: Colors.red[700], size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                download.errorMessage ?? 'Download failed - Tap retry',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (download.isPaused) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pause_circle, color: Colors.orange[700], size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                download.statusDisplayText,
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _handleMenuAction(String action, DownloadModel download) async {
    final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);

    switch (action) {
      case 'open':
        await _openFile(download);
        break;

      case 'share':
        await _shareFile(download);
        break;

      case 'location':
        _showFileLocation(download);
        break;

      case 'pause':
        await downloadProvider.pauseDownload(download.id);
        _showSnackBar('Download paused');
        break;

      case 'resume':
        await downloadProvider.resumeDownload(download.id);
        _showSnackBar('Download resumed');
        break;

      case 'retry':
        await downloadProvider.retryDownload(download);
        _showSnackBar('Retrying download...');
        break;

      case 'cancel':
        await downloadProvider.cancelDownload(download.id);
        _showSnackBar('Download cancelled');
        break;

      case 'delete':
        await _deleteDownload(download, downloadProvider);
        break;
    }
  }

  Future<void> _openFile(DownloadModel download) async {
    try {
      final result = await OpenFilex.open(download.filePath);

      if (result.type != ResultType.done && mounted) {
        _showSnackBar(result.message, isError: true);
      }
    } catch (e) {
      _showSnackBar('Failed to open file: $e', isError: true);
    }
  }

  Future<void> _shareFile(DownloadModel download) async {
    try {
      final file = File(download.filePath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(download.filePath)],
          subject: download.resourceTitle,
        );
      } else {
        _showSnackBar('File not found', isError: true);
      }
    } catch (e) {
      _showSnackBar('Failed to share file: $e', isError: true);
    }
  }

  void _showFileLocation(DownloadModel download) {
    final dir = File(download.filePath).parent.path;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.folder_open, color: AppColors.primaryColor),
            SizedBox(width: 8),
            Text('File Location'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File Name:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                download.fileName,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text(
                'Path:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                dir,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDownload(DownloadModel download, DownloadProvider downloadProvider) async {
    final confirm = await Helpers.showConfirmDialog(
      context,
      'Delete Download',
      'Are you sure you want to delete "${download.resourceTitle}"?\n\nThis will remove the file from your device.',
    );

    if (confirm == true) {
      await downloadProvider.deleteDownload(download, deleteFile: true);
      _showSnackBar('Download deleted');
    }
  }

  Future<void> _clearAllDownloads(BuildContext context) async {
    final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);

    if (downloadProvider.downloads.isEmpty) {
      _showSnackBar('No downloads to clear');
      return;
    }

    final confirm = await Helpers.showConfirmDialog(
      context,
      'Clear All Downloads',
      'Are you sure you want to clear all downloads?\n\nThis will delete ${downloadProvider.totalDownloads} file(s) from your device.\n\nThis action cannot be undone.',
    );

    if (confirm == true) {
      await downloadProvider.clearAllDownloads(deleteFiles: true);
      _showSnackBar('All downloads cleared');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  IconData _getStatusIcon(DownloadModel download) {
    if (download.isCompleted) return Icons.check_circle;
    if (download.isFailed) return Icons.error;
    if (download.isDownloading) return Icons.downloading;
    if (download.isPaused) return Icons.pause_circle;
    if (download.isCancelled) return Icons.cancel;
    return Icons.insert_drive_file;
  }

  Color _getStatusColor(DownloadModel download) {
    if (download.isCompleted) return Colors.green;
    if (download.isFailed) return Colors.red;
    if (download.isDownloading) return AppColors.primaryColor;
    if (download.isPaused) return Colors.orange;
    if (download.isCancelled) return Colors.grey;
    return Colors.blue;
  }

  LinearGradient _getStatusGradient(DownloadModel download) {
    final color = _getStatusColor(download);
    return LinearGradient(
      colors: [
        color.withOpacity(0.8),
        color,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  IconData _getFileTypeIcon(String? extension) {
    if (extension == null) return Icons.insert_drive_file;

    final ext = extension.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf;
    if (ext == 'doc' || ext == 'docx') return Icons.description;
    if (ext == 'xls' || ext == 'xlsx') return Icons.table_chart;
    if (ext == 'ppt' || ext == 'pptx') return Icons.slideshow;
    if (ext == 'zip' || ext == 'rar') return Icons.folder_zip;
    if (ext == 'jpg' || ext == 'jpeg' || ext == 'png') return Icons.image;
    return Icons.insert_drive_file;
  }
}