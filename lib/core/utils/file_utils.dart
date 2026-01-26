import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
/// FILE UTILITIES - PRODUCTION READY
/// Features:
/// ✅ File extension detection
/// ✅ File size formatting
/// ✅ File type icon mapping
/// ✅ File type color mapping
/// ✅ MIME type detection
/// ✅ File validation
/// ═══════════════════════════════════════════════════════════════

class FileUtils {
  // ═══════════════════════════════════════════════════════════════
  // FILE EXTENSION DETECTION
  // ═══════════════════════════════════════════════════════════════

  /// Extract file extension from filename
  static String getFileExtension(String fileName) {
    try {
      final parts = fileName.split('.');
      if (parts.length > 1) {
        return parts.last.toLowerCase();
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  /// Check if file is an image
  static bool isImage(String fileName) {
    final extension = getFileExtension(fileName);
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'].contains(extension);
  }

  /// Check if file is a document
  static bool isDocument(String fileName) {
    final extension = getFileExtension(fileName);
    return ['pdf', 'doc', 'docx', 'txt', 'rtf', 'odt'].contains(extension);
  }

  /// Check if file is a spreadsheet
  static bool isSpreadsheet(String fileName) {
    final extension = getFileExtension(fileName);
    return ['xls', 'xlsx', 'csv', 'ods'].contains(extension);
  }

  /// Check if file is a presentation
  static bool isPresentation(String fileName) {
    final extension = getFileExtension(fileName);
    return ['ppt', 'pptx', 'odp', 'key'].contains(extension);
  }

  /// Check if file is an archive
  static bool isArchive(String fileName) {
    final extension = getFileExtension(fileName);
    return ['zip', 'rar', '7z', 'tar', 'gz', 'bz2'].contains(extension);
  }

  /// Check if file is audio
  static bool isAudio(String fileName) {
    final extension = getFileExtension(fileName);
    return ['mp3', 'wav', 'ogg', 'flac', 'aac', 'm4a', 'wma'].contains(extension);
  }

  /// Check if file is video
  static bool isVideo(String fileName) {
    final extension = getFileExtension(fileName);
    return ['mp4', 'avi', 'mkv', 'mov', 'wmv', 'flv', 'webm'].contains(extension);
  }

  // ═══════════════════════════════════════════════════════════════
  // FILE SIZE FORMATTING
  // ═══════════════════════════════════════════════════════════════

  /// Format file size in human-readable format
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(i == 0 ? 0 : 1)} ${suffixes[i]}';
  }

  /// Parse formatted file size to bytes
  static int parseFileSize(String formattedSize) {
    try {
      final regex = RegExp(r'(\d+\.?\d*)\s*([A-Z]+)');
      final match = regex.firstMatch(formattedSize.toUpperCase());

      if (match == null) return 0;

      final value = double.parse(match.group(1)!);
      final unit = match.group(2)!;

      const multipliers = {
        'B': 1,
        'KB': 1024,
        'MB': 1024 * 1024,
        'GB': 1024 * 1024 * 1024,
        'TB': 1024 * 1024 * 1024 * 1024,
      };

      return (value * (multipliers[unit] ?? 1)).toInt();
    } catch (e) {
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FILE ICON MAPPING
  // ═══════════════════════════════════════════════════════════════

  /// Get appropriate icon for file type
  static IconData getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
    // Documents
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'txt':
        return Icons.text_snippet_rounded;

    // Spreadsheets
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart_rounded;

    // Presentations
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;

    // Archives
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.folder_zip_rounded;

    // Images
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return Icons.image_rounded;

    // Audio
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'flac':
      case 'aac':
        return Icons.audio_file_rounded;

    // Video
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
        return Icons.video_file_rounded;

    // Code
      case 'dart':
      case 'java':
      case 'py':
      case 'js':
      case 'html':
      case 'css':
      case 'json':
      case 'xml':
        return Icons.code_rounded;

    // Default
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FILE COLOR MAPPING
  // ═══════════════════════════════════════════════════════════════

  /// Get appropriate color for file type
  static Color getFileColor(String extension) {
    switch (extension.toLowerCase()) {
    // Documents - Blue
      case 'pdf':
        return const Color(0xFFE53935); // Red for PDF
      case 'doc':
      case 'docx':
        return const Color(0xFF2196F3); // Blue for Word
      case 'txt':
        return const Color(0xFF607D8B); // Blue Grey

    // Spreadsheets - Green
      case 'xls':
      case 'xlsx':
      case 'csv':
        return const Color(0xFF4CAF50); // Green for Excel

    // Presentations - Orange
      case 'ppt':
      case 'pptx':
        return const Color(0xFFFF9800); // Orange for PowerPoint

    // Archives - Purple
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return const Color(0xFF9C27B0); // Purple

    // Images - Pink
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return const Color(0xFFE91E63); // Pink

    // Audio - Deep Purple
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'flac':
      case 'aac':
        return const Color(0xFF673AB7); // Deep Purple

    // Video - Red
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
        return const Color(0xFFF44336); // Red

    // Code - Teal
      case 'dart':
      case 'java':
      case 'py':
      case 'js':
      case 'html':
      case 'css':
      case 'json':
      case 'xml':
        return const Color(0xFF009688); // Teal

    // Default - Grey
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MIME TYPE DETECTION
  // ═══════════════════════════════════════════════════════════════

  /// Get MIME type from file extension
  static String getMimeType(String extension) {
    switch (extension.toLowerCase()) {
    // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'svg':
        return 'image/svg+xml';

    // Documents
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';

    // Spreadsheets
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'csv':
        return 'text/csv';

    // Presentations
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';

    // Archives
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      case '7z':
        return 'application/x-7z-compressed';

    // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';

    // Video
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';

    // Default
      default:
        return 'application/octet-stream';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FILE VALIDATION
  // ═══════════════════════════════════════════════════════════════

  /// Validate file size
  static bool isFileSizeValid(int bytes, int maxSizeInMB) {
    final maxBytes = maxSizeInMB * 1024 * 1024;
    return bytes <= maxBytes;
  }

  /// Validate file extension
  static bool isExtensionAllowed(
      String fileName,
      List<String> allowedExtensions,
      ) {
    final extension = getFileExtension(fileName);
    return allowedExtensions
        .map((e) => e.toLowerCase())
        .contains(extension.toLowerCase());
  }

  /// Get file name without extension
  static String getFileNameWithoutExtension(String fileName) {
    try {
      final parts = fileName.split('.');
      if (parts.length > 1) {
        parts.removeLast();
        return parts.join('.');
      }
      return fileName;
    } catch (e) {
      return fileName;
    }
  }

  /// Sanitize file name (remove special characters)
  static String sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^\w\s\-\.]'), '_');
  }

  /// Generate unique file name
  static String generateUniqueFileName(String originalFileName) {
    final extension = getFileExtension(originalFileName);
    final nameWithoutExt = getFileNameWithoutExtension(originalFileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${sanitizeFileName(nameWithoutExt)}_$timestamp${extension.isNotEmpty ? '.$extension' : ''}';
  }
}