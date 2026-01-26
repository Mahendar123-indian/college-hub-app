import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';
import '../data/models/download_model.dart';
import '../data/services/download_service.dart';

class DownloadProvider extends ChangeNotifier {
  final DownloadService _downloadService = DownloadService();

  List<DownloadModel> _downloads = [];
  bool _isLoading = false;
  String? _error;

  List<DownloadModel> get downloads => _downloads;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalDownloads => _downloads.length;
  int get completedDownloads => _downloads.where((d) => d.isCompleted).length;
  int get activeDownloads => _downloads.where((d) => d.isDownloading).length;
  int get failedDownloads => _downloads.where((d) => d.isFailed).length;

  List<DownloadModel> get completedDownloadsList =>
      _downloads.where((d) => d.isCompleted).toList();

  List<DownloadModel> get activeDownloadsList =>
      _downloads.where((d) => d.isDownloading || d.isPending).toList();

  List<DownloadModel> get failedDownloadsList =>
      _downloads.where((d) => d.isFailed).toList();

  Future<void> initialize() async {
    await _downloadService.initialize();
    await loadDownloads();
    _setupHiveListener();
  }

  void _setupHiveListener() {
    final box = Hive.box(AppConstants.downloadsBox);
    box.listenable().addListener(() {
      loadDownloads();
    });
  }

  Future<void> loadDownloads() async {
    try {
      _downloads = await _downloadService.getAllDownloads();

      // Sort: active first, then completed, then failed
      _downloads.sort((a, b) {
        if (a.isDownloading && !b.isDownloading) return -1;
        if (!a.isDownloading && b.isDownloading) return 1;
        if (a.isCompleted && !b.isCompleted) return -1;
        if (!a.isCompleted && b.isCompleted) return 1;
        return b.downloadedAt.compareTo(a.downloadedAt);
      });

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading downloads: $e');
      notifyListeners();
    }
  }

  Future<String?> startDownload({
    required String url,
    required String fileName,
    required String resourceId,
    required String resourceTitle,
    required int fileSize,
    String? userId,
    String? fileExtension,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if already downloaded
      final existing = _downloads.firstWhere(
            (d) => d.resourceId == resourceId && d.isCompleted,
        orElse: () => DownloadModel(
          id: '',
          resourceId: '',
          resourceTitle: '',
          filePath: '',
          fileUrl: '',
          fileSize: 0,
          downloadedAt: DateTime.now(),
        ),
      );

      if (existing.id.isNotEmpty) {
        _error = 'File already downloaded';
        _isLoading = false;
        notifyListeners();
        return existing.filePath;
      }

      // Check if currently downloading
      final downloading = _downloads.firstWhere(
            (d) => d.resourceId == resourceId && (d.isDownloading || d.isPending),
        orElse: () => DownloadModel(
          id: '',
          resourceId: '',
          resourceTitle: '',
          filePath: '',
          fileUrl: '',
          fileSize: 0,
          downloadedAt: DateTime.now(),
        ),
      );

      if (downloading.id.isNotEmpty) {
        _error = 'Download already in progress';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final taskId = await _downloadService.downloadFile(
        url: url,
        fileName: fileName,
        resourceId: resourceId,
        resourceTitle: resourceTitle,
        fileSize: fileSize,
        userId: userId,
        fileExtension: fileExtension,
      );

      _isLoading = false;
      _error = null;

      await loadDownloads();

      return taskId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      debugPrint('❌ Error starting download: $e');
      notifyListeners();
      return null;
    }
  }

  Future<void> pauseDownload(String taskId) async {
    try {
      await _downloadService.pauseDownload(taskId);
      await loadDownloads();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error pausing download: $e');
      notifyListeners();
    }
  }

  Future<void> resumeDownload(String taskId) async {
    try {
      await _downloadService.resumeDownload(taskId);
      await loadDownloads();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error resuming download: $e');
      notifyListeners();
    }
  }

  Future<void> cancelDownload(String taskId) async {
    try {
      await _downloadService.cancelDownload(taskId);
      await loadDownloads();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error cancelling download: $e');
      notifyListeners();
    }
  }

  Future<void> retryDownload(DownloadModel download) async {
    try {
      await _downloadService.retryDownload(download);
      await loadDownloads();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error retrying download: $e');
      notifyListeners();
    }
  }

  Future<void> deleteDownload(DownloadModel download, {bool deleteFile = true}) async {
    try {
      await _downloadService.deleteDownload(download, deleteFile: deleteFile);
      await loadDownloads();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error deleting download: $e');
      notifyListeners();
    }
  }

  Future<void> clearAllDownloads({bool deleteFiles = false}) async {
    try {
      await _downloadService.clearAllDownloads(deleteFiles: deleteFiles);
      await loadDownloads();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error clearing downloads: $e');
      notifyListeners();
    }
  }

  Future<void> syncWithFirestore(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _downloadService.syncDownloadsWithFirestore(userId);
      await loadDownloads();

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      debugPrint('❌ Error syncing downloads: $e');
      notifyListeners();
    }
  }

  DownloadModel? getDownloadByResourceId(String resourceId) {
    try {
      return _downloads.firstWhere((d) => d.resourceId == resourceId);
    } catch (e) {
      return null;
    }
  }

  bool isResourceDownloaded(String resourceId) {
    return _downloads.any((d) => d.resourceId == resourceId && d.isCompleted);
  }

  bool isResourceDownloading(String resourceId) {
    return _downloads.any(
          (d) => d.resourceId == resourceId && (d.isDownloading || d.isPending),
    );
  }

  String? getDownloadedFilePath(String resourceId) {
    try {
      final download = _downloads.firstWhere(
            (d) => d.resourceId == resourceId && d.isCompleted,
      );
      return download.filePath;
    } catch (e) {
      return null;
    }
  }

  double? getDownloadProgress(String resourceId) {
    try {
      final download = _downloads.firstWhere(
            (d) => d.resourceId == resourceId && d.isDownloading,
      );
      return download.progress;
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _downloadService.dispose();
    super.dispose();
  }
}