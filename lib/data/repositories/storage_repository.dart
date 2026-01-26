import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/constants/app_constants.dart';

class StorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload file
  Future<String> uploadFile({
    required File file,
    required String path,
    Function(double)? onProgress,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  // Upload resource file
  Future<String> uploadResourceFile({
    required File file,
    required String resourceId,
    required String fileName,
    Function(double)? onProgress,
  }) async {
    final path = '${AppConstants.resourcesStoragePath}/$resourceId/$fileName';
    return await uploadFile(
      file: file,
      path: path,
      onProgress: onProgress,
    );
  }

  // Upload profile image
  Future<String> uploadProfileImage({
    required File file,
    required String userId,
    Function(double)? onProgress,
  }) async {
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '${AppConstants.profileImagesPath}/$userId/$fileName';
    return await uploadFile(
      file: file,
      path: path,
      onProgress: onProgress,
    );
  }

  // Upload thumbnail
  Future<String> uploadThumbnail({
    required File file,
    required String resourceId,
    Function(double)? onProgress,
  }) async {
    final fileName = 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '${AppConstants.thumbnailsPath}/$resourceId/$fileName';
    return await uploadFile(
      file: file,
      path: path,
      onProgress: onProgress,
    );
  }

  // Delete file
  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref().child(path).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Delete resource files
  Future<void> deleteResourceFiles(String resourceId) async {
    try {
      final ref = _storage.ref().child('${AppConstants.resourcesStoragePath}/$resourceId');
      final listResult = await ref.listAll();

      // Delete all files in the folder
      for (var item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get download URL
  Future<String> getDownloadUrl(String path) async {
    try {
      return await _storage.ref().child(path).getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  // Get file metadata
  Future<FullMetadata> getFileMetadata(String path) async {
    try {
      return await _storage.ref().child(path).getMetadata();
    } catch (e) {
      rethrow;
    }
  }

  // Check if file exists
  Future<bool> fileExists(String path) async {
    try {
      await _storage.ref().child(path).getDownloadURL();
      return true;
    } catch (e) {
      return false;
    }
  }

  // List files in folder
  Future<List<Reference>> listFiles(String folderPath) async {
    try {
      final ref = _storage.ref().child(folderPath);
      final listResult = await ref.listAll();
      return listResult.items;
    } catch (e) {
      rethrow;
    }
  }
}