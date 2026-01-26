import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/message_model.dart';
import '../../../../core/constants/color_constants.dart';

class FileMessageWidget extends StatefulWidget {
  final MessageModel message;
  final bool isMe;

  const FileMessageWidget({
    Key? key,
    required this.message,
    required this.isMe,
  }) : super(key: key);

  @override
  State<FileMessageWidget> createState() => _FileMessageWidgetState();
}

class _FileMessageWidgetState extends State<FileMessageWidget> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // File Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isMe
                  ? Colors.white.withOpacity(0.2)
                  : AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getFileIcon(),
              color: widget.isMe ? Colors.white : AppColors.primaryColor,
              size: 28,
            ),
          ),

          const SizedBox(width: 12),

          // File Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.message.fileName ?? 'Document',
                  style: GoogleFonts.inter(
                    color: widget.isMe ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatFileSize(widget.message.fileSize ?? 0),
                      style: GoogleFonts.inter(
                        color: widget.isMe
                            ? Colors.white70
                            : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(
                        color: widget.isMe
                            ? Colors.white70
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getFileExtension(),
                      style: GoogleFonts.inter(
                        color: widget.isMe
                            ? Colors.white70
                            : Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Download Progress
                if (_isDownloading) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _downloadProgress,
                      backgroundColor: widget.isMe
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isMe ? Colors.white : AppColors.primaryColor,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Download Button
          IconButton(
            icon: Icon(
              _isDownloading ? Icons.close_rounded : Icons.download_rounded,
              color: widget.isMe ? Colors.white : AppColors.primaryColor,
              size: 22,
            ),
            onPressed: _isDownloading ? _cancelDownload : _downloadFile,
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon() {
    final extension = _getFileExtension().toLowerCase();

    if (extension == 'pdf') return Icons.picture_as_pdf;
    if (['doc', 'docx'].contains(extension)) return Icons.description;
    if (['xls', 'xlsx'].contains(extension)) return Icons.table_chart;
    if (['ppt', 'pptx'].contains(extension)) return Icons.slideshow;
    if (['zip', 'rar'].contains(extension)) return Icons.folder_zip;
    if (extension == 'txt') return Icons.text_snippet;

    return Icons.insert_drive_file;
  }

  String _getFileExtension() {
    final fileName = widget.message.fileName ?? '';
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : 'FILE';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _downloadFile() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    HapticFeedback.lightImpact();

    // Simulate download progress
    for (var i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!_isDownloading) return;

      if (mounted) {
        setState(() => _downloadProgress = i / 10);
      }
    }

    if (mounted) {
      setState(() => _isDownloading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'File downloaded successfully!',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _cancelDownload() {
    setState(() {
      _isDownloading = false;
      _downloadProgress = 0.0;
    });
    HapticFeedback.lightImpact();
  }
}