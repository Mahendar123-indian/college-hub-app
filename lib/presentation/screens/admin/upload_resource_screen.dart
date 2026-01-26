import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:path/path.dart' as path;

// Core Imports
import '../../../config/routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/color_constants.dart';
import '../../../data/models/resource_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/resource_provider.dart';
import '../../../providers/college_provider.dart';

// ✅ NOTIFICATION IMPORT
import '../../../core/utils/notification_triggers.dart';

class UploadResourceScreen extends StatefulWidget {
  const UploadResourceScreen({Key? key}) : super(key: key);

  @override
  State<UploadResourceScreen> createState() => _UploadResourceScreenState();
}

class _UploadResourceScreenState extends State<UploadResourceScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  // Form values
  String? _selectedCollege;
  String? _selectedDepartment;
  String? _selectedSemester;
  String? _selectedSubject;
  String? _selectedResourceType;
  String? _selectedYear;
  bool _isFeatured = false;
  bool _isTrending = false;

  // File handling
  File? _selectedFile;
  String? _fileName;
  int? _fileSize;
  String? _fileHash;
  bool _isDuplicateChecking = false;
  bool _isDuplicate = false;

  // Upload state
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Preview data
  Map<String, dynamic>? _fileMetadata;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileSize = await file.length();

        setState(() {
          _selectedFile = file;
          _fileName = fileName;
          _fileSize = fileSize;
        });

        // Calculate file hash for duplicate detection
        await _calculateFileHash();

        // Extract metadata
        await _extractMetadata();

        // Check for duplicates
        await _checkDuplicate();

        _showSnack('File selected successfully! 📄');
      }
    } catch (e) {
      _showSnack('Error picking file: $e', isError: true);
    }
  }

  Future<void> _calculateFileHash() async {
    if (_selectedFile == null) return;

    setState(() {
      _isDuplicateChecking = true;
      _uploadStatus = 'Calculating file hash...';
    });

    try {
      final bytes = await _selectedFile!.readAsBytes();
      final hash = sha256.convert(bytes);
      setState(() {
        _fileHash = hash.toString();
      });
    } catch (e) {
      debugPrint('Error calculating hash: $e');
    } finally {
      setState(() {
        _isDuplicateChecking = false;
        _uploadStatus = '';
      });
    }
  }

  Future<void> _extractMetadata() async {
    if (_selectedFile == null) return;

    setState(() => _uploadStatus = 'Extracting metadata...');

    try {
      final extension = path.extension(_fileName!).toLowerCase();

      // Basic metadata
      final metadata = <String, dynamic>{
        'fileName': _fileName,
        'fileSize': _fileSize,
        'extension': extension,
        'mimeType': _getMimeType(extension),
      };

      // PDF-specific metadata (requires pdf package)
      if (extension == '.pdf') {
        // In production, use pdf package to extract:
        // - Page count
        // - Author
        // - Title
        // - Creation date
        metadata['pages'] = null; // Placeholder
      }

      setState(() {
        _fileMetadata = metadata;
        _uploadStatus = '';
      });

      // Auto-fill title from filename if empty
      if (_titleController.text.isEmpty) {
        _titleController.text = _fileName!.replaceAll(RegExp(r'\.[^.]+$'), '');
      }
    } catch (e) {
      debugPrint('Error extracting metadata: $e');
      setState(() => _uploadStatus = '');
    }
  }

  String _getMimeType(String extension) {
    switch (extension) {
      case '.pdf':
        return 'application/pdf';
      case '.doc':
      case '.docx':
        return 'application/msword';
      case '.ppt':
      case '.pptx':
        return 'application/vnd.ms-powerpoint';
      case '.xls':
      case '.xlsx':
        return 'application/vnd.ms-excel';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _checkDuplicate() async {
    if (_fileHash == null) return;

    setState(() {
      _isDuplicateChecking = true;
      _uploadStatus = 'Checking for duplicates...';
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('resources')
          .where('fileHash', isEqualTo: _fileHash)
          .limit(1)
          .get();

      setState(() {
        _isDuplicate = snapshot.docs.isNotEmpty;
        _isDuplicateChecking = false;
        _uploadStatus = '';
      });

      if (_isDuplicate) {
        _showDialog(
          'Duplicate File Detected',
          'This file already exists in the system. Would you like to upload it anyway?',
          isDuplicate: true,
        );
      }
    } catch (e) {
      debugPrint('Error checking duplicate: $e');
      setState(() {
        _isDuplicateChecking = false;
        _uploadStatus = '';
      });
    }
  }

  Future<void> _uploadResource() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      _showSnack('Please select a file', isError: true);
      return;
    }

    // Security check
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser == null || !auth.currentUser!.isAdmin) {
      _showSnack('Access denied: Admin only', isError: true);
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Preparing upload...';
    });

    try {
      // 1. Upload file to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child(
        'resources/${_selectedResourceType}/${_selectedDepartment}/${_selectedSemester}/$_fileName',
      );

      final uploadTask = storageRef.putFile(_selectedFile!);

      // Track upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          _uploadStatus = 'Uploading... ${(_uploadProgress * 100).toStringAsFixed(1)}%';
        });
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() => _uploadStatus = 'Finalizing...');

      // 2. Create resource document
      final resource = ResourceModel(
        id: '', // Firestore will generate
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        college: _selectedCollege!,
        department: _selectedDepartment!,
        semester: _selectedSemester!,
        subject: _selectedSubject!,
        resourceType: _selectedResourceType!,
        year: _selectedYear,
        fileUrl: downloadUrl,
        fileName: _fileName!,
        fileExtension: path.extension(_fileName!).substring(1),
        fileSize: _fileSize!,
        thumbnailUrl: null,
        uploadedBy: auth.currentUser!.id,
        uploadedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: _tagsController.text.split(',').map((e) => e.trim()).toList(),
        downloadCount: 0,
        viewCount: 0,
        rating: 0.0,
        ratingCount: 0,
        isFeatured: _isFeatured,
        isTrending: _isTrending,
        isActive: true,
        metadata: {
          'fileHash': _fileHash,
          ..._fileMetadata ?? {},
        },
      );

      // 3. Save to Firestore (this will trigger notification in ResourceProvider)
      await Provider.of<ResourceProvider>(context, listen: false)
          .addResource(resource);

      // ✅ NOTIFICATION: Resource upload success is already handled in ResourceProvider.addResource()
      // But we can add an additional notification here if needed

      // 4. Log activity
      await FirebaseFirestore.instance.collection('activity_logs').add({
        'action': 'Resource uploaded: ${resource.title}',
        'userId': auth.currentUser!.id,
        'userName': auth.currentUser!.name,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isUploading = false;
        _uploadStatus = 'Upload complete!';
      });

      _showSnack('Resource uploaded successfully! 🎉');

      // Reset form
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadStatus = '';
      });
      _showSnack('Upload failed: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : AppColors.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showDialog(String title, String content, {bool isDuplicate = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (isDuplicate)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _isDuplicate = false);
              },
              child: const Text('Upload Anyway'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor.withOpacity(0.05),
              Colors.white,
              AppColors.accentColor.withOpacity(0.05),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilePickerCard(),
                        const SizedBox(height: 24),
                        if (_selectedFile != null) ...[
                          _buildFilePreviewCard(),
                          const SizedBox(height: 24),
                        ],
                        _buildBasicInfoSection(),
                        const SizedBox(height: 24),
                        _buildCategorySection(),
                        const SizedBox(height: 24),
                        _buildAdvancedSection(),
                        const SizedBox(height: 24),
                        if (_isUploading) _buildUploadProgress(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Upload Resource',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      'Share educational content',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilePickerCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDuplicate
              ? Colors.orange
              : (_selectedFile != null ? AppColors.successColor : Colors.grey[300]!),
          width: 2,
          style: BorderStyle.solid,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _selectedFile != null ? Icons.check_circle_rounded : Icons.cloud_upload_rounded,
            size: 64,
            color: _isDuplicate
                ? Colors.orange
                : (_selectedFile != null ? AppColors.successColor : Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFile != null ? 'File Selected' : 'Select File',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFile != null
                ? _fileName!
                : 'PDF, DOC, PPT, XLS files supported',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (_isDuplicate) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_rounded, color: Colors.orange, size: 16),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Duplicate file detected',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isDuplicateChecking ? null : _pickFile,
            icon: const Icon(Icons.folder_open_rounded),
            label: Text(_selectedFile != null ? 'Change File' : 'Choose File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'File Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('File Name', _fileName ?? 'N/A'),
          const Divider(height: 24),
          _buildInfoRow('File Size', _formatFileSize(_fileSize ?? 0)),
          const Divider(height: 24),
          _buildInfoRow('File Type', path.extension(_fileName ?? '').toUpperCase()),
          if (_fileHash != null) ...[
            const Divider(height: 24),
            _buildInfoRow('Hash', '${_fileHash!.substring(0, 16)}...'),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_rounded, color: AppColors.primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title *',
              hintText: 'Enter resource title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.title_rounded),
            ),
            validator: (val) =>
            val == null || val.isEmpty ? 'Title is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Enter resource description',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.description_rounded),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tagsController,
            decoration: InputDecoration(
              labelText: 'Tags (comma-separated)',
              hintText: 'e.g., DSA, Algorithms, Sorting',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.tag_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.category_rounded, color: AppColors.primaryColor, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Category & Classification',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Consumer<CollegeProvider>(
            builder: (context, collegeProvider, child) {
              if (collegeProvider.colleges.isEmpty) {
                return const Center(child: Text('No colleges available'));
              }

              return DropdownButtonFormField<String>(
                value: _selectedCollege,
                decoration: InputDecoration(
                  labelText: 'College *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.school_rounded),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                isExpanded: true,
                items: collegeProvider.colleges.map((college) {
                  return DropdownMenuItem(
                    value: college.name,
                    child: Text(
                      college.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCollege = val;
                    _selectedDepartment = null;
                  });
                },
                validator: (val) => val == null ? 'College is required' : null,
              );
            },
          ),
          const SizedBox(height: 16),
          Consumer<CollegeProvider>(
            builder: (context, collegeProvider, child) {
              if (collegeProvider.colleges.isEmpty) {
                return const SizedBox.shrink();
              }

              // Safe way to get selected college or fallback to first
              final selectedCollegeObj = _selectedCollege != null
                  ? collegeProvider.colleges.firstWhere(
                    (c) => c.name == _selectedCollege,
                orElse: () => collegeProvider.colleges.first,
              )
                  : collegeProvider.colleges.first;

              return DropdownButtonFormField<String>(
                value: _selectedDepartment,
                decoration: InputDecoration(
                  labelText: 'Department *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.apartment_rounded),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                isExpanded: true,
                items: selectedCollegeObj.departments.map((dept) {
                  return DropdownMenuItem(
                    value: dept,
                    child: Text(
                      dept,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: _selectedCollege == null
                    ? null
                    : (val) => setState(() => _selectedDepartment = val),
                validator: (val) => val == null ? 'Department is required' : null,
              );
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedResourceType,
            decoration: InputDecoration(
              labelText: 'Resource Type *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.folder_rounded),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            isExpanded: true,
            items: AppConstants.resourceTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  type,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedResourceType = val),
            validator: (val) => val == null ? 'Resource type is required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSemester,
                  decoration: InputDecoration(
                    labelText: 'Semester *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  ),
                  isExpanded: true,
                  items: AppConstants.semesters.map((sem) {
                    return DropdownMenuItem(
                      value: sem,
                      child: Text(
                        sem,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedSemester = val),
                  validator: (val) =>
                  val == null ? 'Semester is required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Year',
                    hintText: '2024',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.date_range_rounded, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 12),
                  onChanged: (val) => _selectedYear = val,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Subject *',
              hintText: 'e.g., Data Structures',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.book_rounded),
            ),
            onChanged: (val) => _selectedSubject = val,
            validator: (val) =>
            val == null || val.isEmpty ? 'Subject is required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star_rounded, color: AppColors.primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Advanced Options',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Mark as Featured'),
            subtitle: const Text('Show on home screen'),
            value: _isFeatured,
            onChanged: (val) => setState(() => _isFeatured = val),
            activeColor: AppColors.primaryColor,
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Mark as Trending'),
            subtitle: const Text('Show in trending section'),
            value: _isTrending,
            onChanged: (val) => setState(() => _isTrending = val),
            activeColor: AppColors.primaryColor,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Text(
            _uploadStatus,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isUploading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadResource,
                icon: _isUploading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(_isUploading ? 'Uploading...' : 'Upload Resource'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}