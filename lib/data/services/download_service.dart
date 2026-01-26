import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../core/constants/app_constants.dart';
import '../models/download_model.dart';

// ✅ CRITICAL FIX: Add @pragma annotation to the class
@pragma('vm:entry-point')
class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ReceivePort _port = ReceivePort();

  // Track active downloads
  final Map<String, DownloadModel> _activeDownloads = {};

  // Track if already initialized to prevent duplicate initialization
  bool _isInitialized = false;

  // Initialize download service
  Future<void> initialize() async {
    // Prevent duplicate initialization
    if (_isInitialized) {
      debugPrint('! Download service already initialized, skipping...');
      return;
    }

    try {
      // Register callback for download progress
      try {
        IsolateNameServer.removePortNameMapping('downloader_send_port');
      } catch (e) {
        // Port doesn't exist, that's fine
      }

      IsolateNameServer.registerPortWithName(
        _port.sendPort,
        'downloader_send_port',
      );

      _port.listen((dynamic data) {
        String id = data[0];
        int status = data[1];
        int progress = data[2];

        _handleDownloadCallback(id, status, progress);
      });

      FlutterDownloader.registerCallback(downloadCallback);

      // Restore incomplete downloads on app restart
      await _restoreIncompleteDownloads();

      _isInitialized = true;
      debugPrint('✅ Download service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing download service: $e');
    }
  }

  // ✅ CRITICAL FIX: This callback is already annotated correctly
  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  Future<void> _handleDownloadCallback(String taskId, int status, int progress) async {
    try {
      final download = _activeDownloads[taskId];
      if (download == null) return;

      DownloadStatus newStatus = _mapFlutterDownloadStatus(status);
      double newProgress = progress / 100.0;

      // Update local download
      final updatedDownload = download.copyWith(
        status: newStatus,
        progress: newProgress,
        completedAt: newStatus == DownloadStatus.completed ? DateTime.now() : null,
        errorMessage: newStatus == DownloadStatus.failed ? 'Download failed' : null,
      );

      // Save to Hive
      await _saveToHive(updatedDownload);

      // Save to Firestore if user is logged in
      if (download.userId != null) {
        await _saveToFirestore(updatedDownload);
      }

      // Update active downloads map
      if (newStatus == DownloadStatus.completed ||
          newStatus == DownloadStatus.failed ||
          newStatus == DownloadStatus.cancelled) {
        _activeDownloads.remove(taskId);
      } else {
        _activeDownloads[taskId] = updatedDownload;
      }

      debugPrint('✅ Download updated: ${download.resourceTitle} - ${newStatus.value} - ${(newProgress * 100).toInt()}%');
    } catch (e) {
      debugPrint('❌ Error handling download callback: $e');
    }
  }

  DownloadStatus _mapFlutterDownloadStatus(int status) {
    switch (status) {
      case DownloadTaskStatus.undefined:
        return DownloadStatus.pending;
      case DownloadTaskStatus.enqueued:
        return DownloadStatus.pending;
      case DownloadTaskStatus.running:
        return DownloadStatus.downloading;
      case DownloadTaskStatus.complete:
        return DownloadStatus.completed;
      case DownloadTaskStatus.failed:
        return DownloadStatus.failed;
      case DownloadTaskStatus.canceled:
        return DownloadStatus.cancelled;
      case DownloadTaskStatus.paused:
        return DownloadStatus.paused;
      default:
        return DownloadStatus.pending;
    }
  }

  Future<String?> downloadFile({
    required String url,
    required String fileName,
    required String resourceId,
    required String resourceTitle,
    required int fileSize,
    String? userId,
    String? fileExtension,
  }) async {
    try {
      // Check if already downloading
      if (_isResourceDownloading(resourceId)) {
        debugPrint('⚠️ Resource already downloading: $resourceTitle');
        return null;
      }

      // Request storage permission
      if (!await _requestPermission()) {
        throw Exception('Storage permission denied');
      }

      // Get download directory
      final dir = await _getDownloadDirectory();
      final savePath = '${dir.path}/$fileName';

      // Check if file already exists
      if (await File(savePath).exists()) {
        debugPrint('⚠️ File already exists: $fileName');
        return savePath;
      }

      // Create download model
      final downloadId = 'dl_${DateTime.now().millisecondsSinceEpoch}';
      final download = DownloadModel(
        id: downloadId,
        userId: userId,
        resourceId: resourceId,
        resourceTitle: resourceTitle,
        filePath: savePath,
        fileUrl: url,
        fileSize: fileSize,
        status: DownloadStatus.pending,
        progress: 0.0,
        downloadedAt: DateTime.now(),
        fileExtension: fileExtension ?? _getFileExtension(fileName),
      );

      // Save initial state
      await _saveToHive(download);
      if (userId != null) {
        await _saveToFirestore(download);
      }

      // Start download
      final taskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: dir.path,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: true,
      );

      if (taskId != null) {
        // Update with task ID
        final updatedDownload = download.copyWith(
          id: taskId,
          status: DownloadStatus.downloading,
        );

        _activeDownloads[taskId] = updatedDownload;
        await _saveToHive(updatedDownload);

        if (userId != null) {
          await _saveToFirestore(updatedDownload);
        }

        debugPrint('✅ Download started: $resourceTitle');
        return taskId;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Download error: $e');
      return null;
    }
  }

  bool _isResourceDownloading(String resourceId) {
    return _activeDownloads.values.any(
          (d) => d.resourceId == resourceId && d.isDownloading,
    );
  }

  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Try to get external storage directory
      final dir = await getExternalStorageDirectory();
      if (dir != null) {
        final collegeHubDir = Directory('${dir.path}/CollegeHub/Downloads');
        await collegeHubDir.create(recursive: true);
        return collegeHubDir;
      }
    }

    // Fallback to application documents directory
    final dir = await getApplicationDocumentsDirectory();
    final collegeHubDir = Directory('${dir.path}/CollegeHub/Downloads');
    await collegeHubDir.create(recursive: true);
    return collegeHubDir;
  }

  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last : '';
  }

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      try {
        // Check if permission is already granted
        if (await Permission.storage.isGranted) {
          return true;
        }

        // Get Android version
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;

        // For Android 13+ (API 33+), we don't need storage permission
        if (androidInfo.version.sdkInt >= 33) {
          return true;
        }

        // Request storage permission for older Android versions
        final status = await Permission.storage.request();
        if (status.isGranted) {
          return true;
        }

        // Try requesting manage external storage for Android 11+ (API 30+)
        if (androidInfo.version.sdkInt >= 30) {
          final manageStatus = await Permission.manageExternalStorage.request();
          return manageStatus.isGranted;
        }

        return false;
      } catch (e) {
        debugPrint('❌ Error requesting permission: $e');
        return false;
      }
    }

    return true; // iOS doesn't need storage permission
  }

  Future<void> _saveToHive(DownloadModel download) async {
    try {
      final box = Hive.box(AppConstants.downloadsBox);

      // Find existing download by ID or resource ID
      int? existingIndex;
      for (int i = 0; i < box.length; i++) {
        final data = box.getAt(i) as Map;
        if (data['id'] == download.id || data['resourceId'] == download.resourceId) {
          existingIndex = i;
          break;
        }
      }

      // Update or add
      if (existingIndex != null) {
        await box.putAt(existingIndex, download.toMap());
      } else {
        await box.add(download.toMap());
      }
    } catch (e) {
      debugPrint('❌ Error saving to Hive: $e');
    }
  }

  Future<void> _saveToFirestore(DownloadModel download) async {
    if (download.userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(download.userId)
          .collection('downloads')
          .doc(download.id)
          .set(download.toFirestoreMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ Error saving to Firestore: $e');
    }
  }

  Future<void> _restoreIncompleteDownloads() async {
    try {
      final box = Hive.box(AppConstants.downloadsBox);
      final tasks = await FlutterDownloader.loadTasks();

      if (tasks == null || tasks.isEmpty) {
        debugPrint('✅ No tasks to restore');
        return;
      }

      for (int i = 0; i < box.length; i++) {
        final data = box.getAt(i) as Map;
        final download = DownloadModel.fromMap(Map<String, dynamic>.from(data));

        if (download.isDownloading || download.isPending) {
          // Check if task still exists
          final taskExists = tasks.any((t) => t.taskId == download.id);

          if (taskExists) {
            _activeDownloads[download.id] = download;
          } else {
            // Mark as failed if task doesn't exist
            final updatedDownload = download.copyWith(
              status: DownloadStatus.failed,
              errorMessage: 'Download was interrupted',
            );
            await _saveToHive(updatedDownload);
          }
        }
      }

      debugPrint('✅ Restored ${_activeDownloads.length} incomplete downloads');
    } catch (e) {
      debugPrint('❌ Error restoring downloads: $e');
    }
  }

  Future<void> pauseDownload(String taskId) async {
    try {
      await FlutterDownloader.pause(taskId: taskId);

      final download = _activeDownloads[taskId];
      if (download != null) {
        final updated = download.copyWith(
          status: DownloadStatus.paused,
          pausedAt: DateTime.now(),
        );
        await _saveToHive(updated);
        if (download.userId != null) {
          await _saveToFirestore(updated);
        }
      }
    } catch (e) {
      debugPrint('❌ Error pausing download: $e');
    }
  }

  Future<void> resumeDownload(String taskId) async {
    try {
      final newTaskId = await FlutterDownloader.resume(taskId: taskId);

      if (newTaskId != null) {
        final download = _activeDownloads[taskId];
        if (download != null) {
          final updated = download.copyWith(
            id: newTaskId,
            status: DownloadStatus.downloading,
            pausedAt: null,
          );

          _activeDownloads.remove(taskId);
          _activeDownloads[newTaskId] = updated;

          await _saveToHive(updated);
          if (download.userId != null) {
            await _saveToFirestore(updated);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error resuming download: $e');
    }
  }

  Future<void> cancelDownload(String taskId) async {
    try {
      await FlutterDownloader.cancel(taskId: taskId);

      final download = _activeDownloads[taskId];
      if (download != null) {
        final updated = download.copyWith(
          status: DownloadStatus.cancelled,
        );

        _activeDownloads.remove(taskId);
        await _saveToHive(updated);

        if (download.userId != null) {
          await _saveToFirestore(updated);
        }
      }
    } catch (e) {
      debugPrint('❌ Error cancelling download: $e');
    }
  }

  Future<void> retryDownload(DownloadModel download) async {
    try {
      await downloadFile(
        url: download.fileUrl,
        fileName: download.filePath.split('/').last,
        resourceId: download.resourceId,
        resourceTitle: download.resourceTitle,
        fileSize: download.fileSize,
        userId: download.userId,
        fileExtension: download.fileExtension,
      );
    } catch (e) {
      debugPrint('❌ Error retrying download: $e');
    }
  }

  Future<void> deleteDownload(DownloadModel download, {bool deleteFile = true}) async {
    try {
      // Delete file if requested
      if (deleteFile) {
        final file = File(download.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Remove from Hive
      final box = Hive.box(AppConstants.downloadsBox);
      for (int i = 0; i < box.length; i++) {
        final data = box.getAt(i) as Map;
        if (data['id'] == download.id) {
          await box.deleteAt(i);
          break;
        }
      }

      // Remove from Firestore
      if (download.userId != null) {
        await _firestore
            .collection('users')
            .doc(download.userId)
            .collection('downloads')
            .doc(download.id)
            .delete();
      }

      // Remove from active downloads
      _activeDownloads.remove(download.id);

      debugPrint('✅ Download deleted: ${download.resourceTitle}');
    } catch (e) {
      debugPrint('❌ Error deleting download: $e');
    }
  }

  Future<void> syncDownloadsWithFirestore(String userId) async {
    try {
      final box = Hive.box(AppConstants.downloadsBox);

      // Get downloads from Firestore
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('downloads')
          .get();

      // Sync Firestore downloads to Hive
      for (final doc in snapshot.docs) {
        final download = DownloadModel.fromDocument(doc);

        // Check if exists in Hive
        bool existsInHive = false;
        for (int i = 0; i < box.length; i++) {
          final data = box.getAt(i) as Map;
          if (data['id'] == download.id) {
            existsInHive = true;
            break;
          }
        }

        if (!existsInHive) {
          await box.add(download.toMap());
        }
      }

      // Upload Hive downloads to Firestore that don't have userId
      for (int i = 0; i < box.length; i++) {
        final data = box.getAt(i) as Map;
        final download = DownloadModel.fromMap(Map<String, dynamic>.from(data));

        if (download.userId == null) {
          final updated = download.copyWith(userId: userId);
          await box.putAt(i, updated.toMap());
          await _saveToFirestore(updated);
        }
      }

      debugPrint('✅ Downloads synced with Firestore');
    } catch (e) {
      debugPrint('❌ Error syncing downloads: $e');
    }
  }

  Future<List<DownloadModel>> getAllDownloads() async {
    try {
      final box = Hive.box(AppConstants.downloadsBox);
      final downloads = <DownloadModel>[];

      for (int i = 0; i < box.length; i++) {
        final data = box.getAt(i) as Map;
        downloads.add(DownloadModel.fromMap(Map<String, dynamic>.from(data)));
      }

      return downloads;
    } catch (e) {
      debugPrint('❌ Error getting downloads: $e');
      return [];
    }
  }

  Future<void> clearAllDownloads({bool deleteFiles = false}) async {
    try {
      if (deleteFiles) {
        final downloads = await getAllDownloads();
        for (final download in downloads) {
          final file = File(download.filePath);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }

      final box = Hive.box(AppConstants.downloadsBox);
      await box.clear();
      _activeDownloads.clear();

      debugPrint('✅ All downloads cleared');
    } catch (e) {
      debugPrint('❌ Error clearing downloads: $e');
    }
  }

  void dispose() {
    try {
      IsolateNameServer.removePortNameMapping('downloader_send_port');
      _port.close();
    } catch (e) {
      debugPrint('❌ Error disposing download service: $e');
    }
  }
}