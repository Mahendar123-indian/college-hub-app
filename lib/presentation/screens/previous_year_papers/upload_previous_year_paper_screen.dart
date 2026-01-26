import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import '../../../providers/auth_provider.dart';
import '../../../providers/college_provider.dart';
import '../../../providers/previous_year_paper_provider.dart';
import '../../../data/models/previous_year_paper_model.dart';
import '../../../data/models/college_model.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/helpers.dart';

class UploadPreviousYearPaperScreen extends StatefulWidget {
  const UploadPreviousYearPaperScreen({Key? key}) : super(key: key);

  @override
  State<UploadPreviousYearPaperScreen> createState() => _UploadPreviousYearPaperScreenState();
}

class _UploadPreviousYearPaperScreenState extends State<UploadPreviousYearPaperScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subjectController = TextEditingController();
  final _yearController = TextEditingController();
  final _regulationController = TextEditingController();

  CollegeModel? _selectedCollegeObj;
  String? _selectedCollegeName;
  String? _selectedDepartment;
  String? _selectedSemester;
  String? _selectedExamType;

  List<String> _availableDepartments = [];
  bool _isLoadingDepartments = false;

  File? _selectedFile;
  String? _fileName;
  int? _fileSize;

  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final _storageRepository = StorageRepository();

  // Exam types specific to previous year papers
  final List<String> _examTypes = [
    'Mid-Exam 1',
    'Mid-Exam 2',
    'Semester Exam',
    'Annual Exam',
    'Supplementary Exam',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CollegeProvider>(context, listen: false).fetchAllColleges();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    _yearController.dispose();
    _regulationController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartmentsForCollege(String collegeId) async {
    setState(() {
      _isLoadingDepartments = true;
      _availableDepartments = [];
      _selectedDepartment = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('departments')
          .where('collegeId', isEqualTo: collegeId)
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final departments = snapshot.docs
            .map((doc) => doc.data()['code'] as String)
            .toList();

        setState(() {
          _availableDepartments = departments;
          _isLoadingDepartments = false;
        });
      } else {
        setState(() => _isLoadingDepartments = false);
        if (mounted) {
          Helpers.showSnackBar(
            context,
            'No departments found for this college',
            backgroundColor: Colors.orange,
          );
        }
      }
    } catch (e) {
      setState(() => _isLoadingDepartments = false);
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error loading departments: ${e.toString()}',
          backgroundColor: AppColors.errorColor,
        );
      }
    }
  }

  Future<void> _pickFile() async {
    bool permissionGranted = await _requestStoragePermission();

    if (!permissionGranted) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Storage permission is required to select files.',
          backgroundColor: AppColors.errorColor,
        );
      }
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: false,
        withReadStream: true,
        dialogTitle: 'Select Previous Year Paper (PDF only)',
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);

        if (!await file.exists()) {
          if (mounted) {
            Helpers.showSnackBar(
              context,
              'Selected file does not exist or is not accessible.',
              backgroundColor: AppColors.errorColor,
            );
          }
          return;
        }

        final fileSize = await file.length();

        if (fileSize > AppConstants.maxFileSizeBytes) {
          if (mounted) {
            Helpers.showSnackBar(
              context,
              AppConstants.errorFileTooLarge,
              backgroundColor: AppColors.errorColor,
            );
          }
          return;
        }

        if (fileSize == 0) {
          if (mounted) {
            Helpers.showSnackBar(
              context,
              'Selected file is empty. Please choose a valid file.',
              backgroundColor: AppColors.errorColor,
            );
          }
          return;
        }

        setState(() {
          _selectedFile = file;
          _fileName = result.files.single.name;
          _fileSize = fileSize;
        });

        if (mounted) {
          Helpers.showSnackBar(
            context,
            'File selected: $_fileName',
            backgroundColor: AppColors.successColor,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error selecting file: ${e.toString()}',
          backgroundColor: AppColors.errorColor,
        );
      }
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        var status = await Permission.manageExternalStorage.status;
        if (status.isGranted) return true;

        if (status.isDenied) {
          status = await Permission.manageExternalStorage.request();
          if (status.isGranted) return true;
          if (status.isPermanentlyDenied) {
            await _showPermissionDialog();
            return false;
          }
        }

        return status.isGranted;
      } else {
        var status = await Permission.storage.status;
        if (status.isGranted) return true;

        if (status.isDenied) {
          status = await Permission.storage.request();
          if (status.isGranted) return true;
          if (status.isPermanentlyDenied) {
            await _showPermissionDialog();
            return false;
          }
        }

        return status.isGranted || status.isLimited;
      }
    } catch (e) {
      return true;
    }
  }

  Future<void> _showPermissionDialog() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Storage Permission Required'),
        content: const Text(
          'This app needs storage permission to select files. '
              'Please grant the permission in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadPaper() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFile == null) {
      Helpers.showSnackBar(
        context,
        'Please select a PDF file',
        backgroundColor: AppColors.errorColor,
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final paperProvider = Provider.of<PreviousYearPaperProvider>(context, listen: false);
      final user = authProvider.currentUser!;

      final paperId = DateTime.now().millisecondsSinceEpoch.toString();

      // Upload file to Firebase Storage in previousYearPapers folder
      // The uploadFile method combines path and file name internally
      final fileUrl = await _storageRepository.uploadFile(
        file: _selectedFile!,
        path: 'previousYearPapers/$paperId/$_fileName',
        onProgress: (progress) {
          setState(() => _uploadProgress = progress);
        },
      );

      // Create paper model with pending status
      final paper = PreviousYearPaperModel(
        id: paperId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        examYear: _yearController.text.trim(),
        examType: _selectedExamType!,
        college: _selectedCollegeName!,
        department: _selectedDepartment!,
        semester: _selectedSemester!,
        subject: _subjectController.text.trim(),
        regulation: _regulationController.text.trim().isEmpty
            ? null
            : _regulationController.text.trim(),
        fileUrl: fileUrl,
        fileName: _fileName!,
        fileExtension: Helpers.getFileExtension(_fileName!),
        fileSize: _fileSize!,
        uploadedBy: user.id,
        uploaderName: user.name,
        uploaderCollege: user.college ?? _selectedCollegeName!,
        uploaderDepartment: user.department ?? _selectedDepartment!,
        uploadedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'pending', // Requires admin approval
        isActive: true,
      );

      final success = await paperProvider.createPaper(paper);

      if (success && mounted) {
        Helpers.showSnackBar(
          context,
          'Paper uploaded successfully! Waiting for admin approval.',
          backgroundColor: AppColors.successColor,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Upload failed: ${e.toString()}',
          backgroundColor: AppColors.errorColor,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Previous Year Paper'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isUploading ? null : () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your upload will be reviewed by admin before appearing to other users.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // File Picker
              GestureDetector(
                onTap: _isUploading ? null : _pickFile,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isUploading
                          ? AppColors.primaryColor.withOpacity(0.3)
                          : AppColors.primaryColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.primaryColor.withOpacity(0.05),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile != null
                            ? Icons.check_circle_outline
                            : Icons.cloud_upload_outlined,
                        size: 48,
                        color: _isUploading
                            ? AppColors.primaryColor.withOpacity(0.3)
                            : AppColors.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _fileName ?? 'Tap to select PDF file',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_fileSize != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          Helpers.formatFileSize(_fileSize!),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (_selectedFile == null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'PDF files only (Max 50MB)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                enabled: !_isUploading,
                decoration: const InputDecoration(
                  labelText: 'Paper Title *',
                  prefixIcon: Icon(Icons.title),
                  hintText: 'e.g., DBMS Mid Exam 1 - 2023',
                ),
                validator: (value) => Validators.validateRequired(value, fieldName: 'Title'),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                enabled: !_isUploading,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                  hintText: 'Briefly describe the paper...',
                ),
                validator: (value) => Validators.validateRequired(value, fieldName: 'Description'),
              ),
              const SizedBox(height: 16),

              // Exam Year
              TextFormField(
                controller: _yearController,
                enabled: !_isUploading,
                decoration: const InputDecoration(
                  labelText: 'Exam Year *',
                  prefixIcon: Icon(Icons.calendar_today),
                  hintText: 'e.g., 2023, 2024',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter exam year';
                  }
                  final year = int.tryParse(value);
                  if (year == null || year < 2000 || year > DateTime.now().year + 1) {
                    return 'Please enter a valid year';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Exam Type
              DropdownButtonFormField<String>(
                value: _selectedExamType,
                decoration: const InputDecoration(
                  labelText: 'Exam Type *',
                  prefixIcon: Icon(Icons.school),
                ),
                isExpanded: true,
                items: _examTypes
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
                    .toList(),
                onChanged: _isUploading ? null : (value) => setState(() => _selectedExamType = value),
                validator: (value) => Validators.validateDropdown(value, fieldName: 'Exam Type'),
              ),
              const SizedBox(height: 16),

              // College Dropdown
              Consumer<CollegeProvider>(
                builder: (context, provider, child) {
                  return DropdownButtonFormField<CollegeModel>(
                    value: _selectedCollegeObj,
                    decoration: const InputDecoration(
                      labelText: 'College *',
                      prefixIcon: Icon(Icons.school),
                    ),
                    isExpanded: true,
                    items: provider.colleges.isEmpty
                        ? []
                        : provider.colleges.map((college) {
                      return DropdownMenuItem(
                        value: college,
                        child: Text(
                          college.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: _isUploading
                        ? null
                        : (CollegeModel? college) {
                      if (college != null) {
                        setState(() {
                          _selectedCollegeObj = college;
                          _selectedCollegeName = college.name;
                          _selectedDepartment = null;
                        });
                        _loadDepartmentsForCollege(college.id);
                      }
                    },
                    validator: (value) => value == null ? 'Please select a college' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Department Dropdown
              DropdownButtonFormField<String>(
                value: _selectedDepartment,
                decoration: InputDecoration(
                  labelText: 'Department *',
                  prefixIcon: _isLoadingDepartments
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                      : const Icon(Icons.category),
                ),
                isExpanded: true,
                items: _availableDepartments.isEmpty
                    ? []
                    : _availableDepartments.map((dept) {
                  return DropdownMenuItem(
                    value: dept,
                    child: Text(
                      dept,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (_availableDepartments.isEmpty || _isUploading || _isLoadingDepartments)
                    ? null
                    : (value) => setState(() => _selectedDepartment = value),
                validator: (value) => Validators.validateRequired(value, fieldName: 'Department'),
                hint: Text(_selectedCollegeObj == null ? 'Select a college first' : 'Select Department'),
              ),
              const SizedBox(height: 16),

              // Semester
              DropdownButtonFormField<String>(
                value: _selectedSemester,
                decoration: const InputDecoration(
                  labelText: 'Semester *',
                  prefixIcon: Icon(Icons.stairs),
                ),
                isExpanded: true,
                items: AppConstants.semesters
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
                    .toList(),
                onChanged: _isUploading ? null : (value) => setState(() => _selectedSemester = value),
                validator: (value) => Validators.validateDropdown(value, fieldName: 'Semester'),
              ),
              const SizedBox(height: 16),

              // Subject
              TextFormField(
                controller: _subjectController,
                enabled: !_isUploading,
                decoration: const InputDecoration(
                  labelText: 'Subject *',
                  prefixIcon: Icon(Icons.book),
                  hintText: 'e.g., Database Management Systems',
                ),
                validator: (value) => Validators.validateRequired(value, fieldName: 'Subject'),
              ),
              const SizedBox(height: 16),

              // Regulation (Optional)
              TextFormField(
                controller: _regulationController,
                enabled: !_isUploading,
                decoration: const InputDecoration(
                  labelText: 'Regulation (Optional)',
                  prefixIcon: Icon(Icons.rule),
                  hintText: 'e.g., R18, R20, R22',
                ),
              ),
              const SizedBox(height: 24),

              // Upload Progress
              if (_isUploading) ...[
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                ),
                const SizedBox(height: 12),
                Text(
                  'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Upload Button
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadPaper,
                  icon: Icon(_isUploading ? Icons.hourglass_empty : Icons.upload),
                  label: Text(_isUploading ? 'Uploading...' : 'Upload Paper'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}