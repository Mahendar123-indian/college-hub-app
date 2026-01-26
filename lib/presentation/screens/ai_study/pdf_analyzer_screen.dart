import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../../core/constants/color_constants.dart';
import '../../../data/services/document_intelligence_service.dart';
import '../../../data/services/unified_ai_service.dart';

class PdfAnalyzerScreen extends StatefulWidget {
  const PdfAnalyzerScreen({Key? key}) : super(key: key);

  @override
  State<PdfAnalyzerScreen> createState() => _PdfAnalyzerScreenState();
}

class _PdfAnalyzerScreenState extends State<PdfAnalyzerScreen>
    with SingleTickerProviderStateMixin {
  final DocumentIntelligenceService _docService = DocumentIntelligenceService();

  File? _selectedFile;
  String? _extractedText;
  Map<String, dynamic>? _documentMetadata;
  Map<String, dynamic>? _analysisResults;
  bool _isProcessing = false;
  bool _isAnalyzing = false;
  String _selectedAnalysisType = 'summary';

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _extractedText = null;
          _documentMetadata = null;
          _analysisResults = null;
        });

        _animController.forward(from: 0);
        await _processDocument();
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e', Colors.red);
    }
  }

  Future<void> _processDocument() async {
    if (_selectedFile == null) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      // Extract text
      final text = await _docService.extractText(_selectedFile!);

      // Generate metadata
      final metadata = _docService.generateMetadata(_selectedFile!, text);

      setState(() {
        _extractedText = text;
        _documentMetadata = metadata;
        _isProcessing = false;
      });

      _showSnackBar('Document processed successfully!', AppColors.successColor);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showSnackBar('Error processing document: $e', Colors.red);
    }
  }

  Future<void> _analyzeDocument(String analysisTypeStr) async {
    if (_extractedText == null || _selectedFile == null) return;

    setState(() {
      _isAnalyzing = true;
      _selectedAnalysisType = analysisTypeStr;
    });

    try {
      // ✅ Use UnifiedAIService
      final aiService = UnifiedAIService();
      if (!aiService.isInitialized) {
        await aiService.initialize();
      }

      // Map string to AnalysisType enum
      AnalysisType analysisType;
      switch (analysisTypeStr) {
        case 'summary':
          analysisType = AnalysisType.summary;
          break;
        case 'mcq':
          analysisType = AnalysisType.mcq;
          break;
        case 'notes':
          analysisType = AnalysisType.notes;
          break;
        case 'questions':
          analysisType = AnalysisType.questions;
          break;
        default:
          analysisType = AnalysisType.summary;
      }

      final result = await aiService.analyzeDocument(_selectedFile!, analysisType);

      setState(() {
        _analysisResults = {
          'type': analysisTypeStr,
          'content': result.content,
          'timestamp': DateTime.now(),
        };
        _isAnalyzing = false;
      });

      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() => _isAnalyzing = false);
      _showSnackBar('Error analyzing document: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: _selectedFile == null ? _buildEmptyState() : _buildDocumentView(),
      floatingActionButton: _selectedFile == null ? _buildUploadFAB() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withOpacity(0.8),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Document Analyzer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'AI-Powered Document Intelligence',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        if (_selectedFile != null)
          IconButton(
            icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
            onPressed: _pickDocument,
            tooltip: 'Upload New Document',
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor,
                    AppColors.accentColor,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Upload & Analyze Documents',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Get instant summaries, notes, MCQs,\nand important questions from any document',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            _buildFeatureCard(
              Icons.summarize_rounded,
              'Smart Summaries',
              'AI-generated summaries with key points',
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              Icons.quiz_rounded,
              'Generate MCQs',
              'Practice questions from document content',
              Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              Icons.note_alt_rounded,
              'Study Notes',
              'Organized notes perfect for revision',
              Colors.green,
            ),
            const SizedBox(height: 40),
            const Text(
              'Supported Formats',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                _buildFormatChip('PDF', Icons.picture_as_pdf_rounded, Colors.red),
                _buildFormatChip('TXT', Icons.text_snippet_rounded, Colors.grey),
                _buildFormatChip('DOC', Icons.description_rounded, Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
      IconData icon,
      String title,
      String description,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatChip(String label, IconData icon, Color color) {
    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDocumentView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildDocumentInfo(),
          _buildAnalysisOptions(),
          if (_isAnalyzing) _buildAnalyzingIndicator(),
          if (_analysisResults != null) _buildAnalysisResults(),
        ],
      ),
    );
  }

  Widget _buildDocumentInfo() {
    if (_documentMetadata == null) {
      return const SizedBox.shrink();
    }

    final structure = _documentMetadata!['structure'] as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insert_drive_file_rounded,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _documentMetadata!['fileName'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _documentMetadata!['fileSizeFormatted'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatCard(
                'Words',
                structure['wordCount'].toString(),
                Icons.text_fields_rounded,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Pages',
                (structure['lineCount'] / 50).ceil().toString(),
                Icons.article_rounded,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Reading',
                '${structure['readingTimeMinutes']} min',
                Icons.timer_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisOptions() {
    final options = [
      {
        'type': 'summary',
        'icon': Icons.summarize_rounded,
        'label': 'Summary',
        'color': Colors.blue,
      },
      {
        'type': 'mcq',
        'icon': Icons.quiz_rounded,
        'label': 'MCQs',
        'color': Colors.orange,
      },
      {
        'type': 'notes',
        'icon': Icons.note_alt_rounded,
        'label': 'Notes',
        'color': Colors.green,
      },
      {
        'type': 'questions',
        'icon': Icons.help_outline_rounded,
        'label': 'Questions',
        'color': Colors.purple,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Analysis Options',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              return _buildAnalysisOptionCard(
                option['type'] as String,
                option['icon'] as IconData,
                option['label'] as String,
                option['color'] as Color,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisOptionCard(
      String type,
      IconData icon,
      String label,
      Color color,
      ) {
    final isSelected = _selectedAnalysisType == type;

    return GestureDetector(
      onTap: () => _analyzeDocument(type),
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [color, color.withOpacity(0.7)])
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzingIndicator() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analyzing Document...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI is processing your document',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResults() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Analysis Results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _analysisResults!['content']));
                    _showSnackBar('Copied to clipboard!', AppColors.successColor);
                  },
                  tooltip: 'Copy',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _analysisResults!['content'],
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadFAB() {
    return FloatingActionButton.extended(
      onPressed: _pickDocument,
      backgroundColor: AppColors.primaryColor,
      icon: const Icon(Icons.upload_file_rounded),
      label: const Text('Upload Document'),
    );
  }
}