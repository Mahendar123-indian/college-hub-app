import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/color_constants.dart';
import '../../../config/routes.dart';

// ✅ NEW: YouTube Imports
import '../../../providers/youtube_provider.dart';
import '../../../data/models/youtube_video_model.dart';
import '../../widgets/youtube/video_thumbnail_widget.dart';

class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String? url;
  final String? filePath;

  const PdfViewerScreen({
    Key? key,
    required this.title,
    this.url,
    this.filePath,
  }) : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen>
    with TickerProviderStateMixin {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  int _totalPages = 0;
  bool _showControls = true;
  bool _isNightMode = false;
  double _brightness = 1.0;
  double _currentZoom = 1.0;
  Timer? _hideControlsTimer;

  // ✅ NEW: YouTube suggestions
  List<YouTubeVideoModel> _suggestedVideos = [];
  bool _showVideoSuggestions = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pageIndicatorController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pageIndicatorAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAutoHideTimer();

    // ✅ NEW: Load video suggestions after delay
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _loadVideoSuggestions();
      }
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pageIndicatorController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _pageIndicatorAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
          parent: _pageIndicatorController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  void _startAutoHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showControls && !_isLoading && !_hasError) {
        setState(() {
          _showControls = false;
          _fadeController.reverse();
          _slideController.reverse();
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _fadeController.forward();
        _slideController.forward();
        _startAutoHideTimer();
      } else {
        _fadeController.reverse();
        _slideController.reverse();
      }
    });
  }

  void _keepControlsVisible() {
    if (!_showControls) {
      setState(() {
        _showControls = true;
        _fadeController.forward();
        _slideController.forward();
      });
    }
    _startAutoHideTimer();
  }

  void _toggleNightMode() {
    HapticFeedback.lightImpact();
    setState(() => _isNightMode = !_isNightMode);
    _keepControlsVisible();
  }

  void _adjustBrightness(double value) {
    setState(() => _brightness = value);
  }

  void _updateZoom(double delta) {
    final newZoom = (_currentZoom + delta).clamp(1.0, 3.0);
    _pdfViewerController.zoomLevel = newZoom;
    setState(() => _currentZoom = newZoom);
    _keepControlsVisible();
  }

  void _jumpToPage() {
    _keepControlsVisible();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final controller = TextEditingController();
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: _isNightMode ? Colors.grey[900] : Colors.white,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryColor,
                            AppColors.accentColor
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.format_list_numbered,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Jump to Page',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _isNightMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: TextStyle(
                      color: _isNightMode ? Colors.white : Colors.black,
                      fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Enter page (1-$_totalPages)',
                    hintStyle: TextStyle(
                        color: _isNightMode
                            ? Colors.grey[400]
                            : Colors.grey[600]),
                    filled: true,
                    fillColor:
                    _isNightMode ? Colors.grey[800] : Colors.grey[100],
                    prefixIcon: Icon(Icons.search,
                        color: _isNightMode ? Colors.grey[400] : Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                              color: _isNightMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                              width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Cancel',
                            style: TextStyle(
                                color:
                                _isNightMode ? Colors.white : Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final page = int.tryParse(controller.text);
                          if (page != null && page > 0 && page <= _totalPages) {
                            _pdfViewerController.jumpToPage(page);
                            Navigator.pop(context);
                            _keepControlsVisible();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Please enter a valid page number (1-$_totalPages)'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Jump',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ NEW: Load Video Suggestions
  Future<void> _loadVideoSuggestions() async {
    try {
      final youtubeProvider = Provider.of<YouTubeProvider>(context, listen: false);

      // Extract subject from title (simple approach)
      final titleWords = widget.title.toLowerCase().split(' ');
      final subject = titleWords.length > 1 ? titleWords[0] : widget.title;

      await youtubeProvider.searchVideos(
        query: widget.title,
        subject: subject,
        maxResults: 3,
      );

      if (mounted) {
        setState(() {
          _suggestedVideos = youtubeProvider.videos.take(3).toList();
          _showVideoSuggestions = _suggestedVideos.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading video suggestions: $e');
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _pageIndicatorController.dispose();
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isNightMode ? Colors.black : Colors.white,
      extendBodyBehindAppBar: true,
      body: WillPopScope(
        onWillPop: () async {
          Navigator.pop(context);
          return false;
        },
        child: Stack(
          children: [
            // PDF Viewer with brightness and night mode overlay
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleControls,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black
                        .withOpacity(_isNightMode ? 0.3 : 1.0 - _brightness),
                    BlendMode.darken,
                  ),
                  child: _buildPdfContent(),
                ),
              ),
            ),

            // Top Control Bar - Always rendered, visibility controlled by animation
            _buildTopBar(),

            // Bottom Control Bar - Always rendered, visibility controlled by animation
            _buildBottomBar(),

            // Page Indicator (Always visible when PDF is loaded)
            if (!_isLoading && !_hasError && _totalPages > 0)
              _buildPageIndicator(),

            // ✅ NEW: Video Suggestions Floating Button
            if (_showVideoSuggestions && !_isLoading && !_hasError)
              _buildVideoSuggestionsButton(),

            // Loading Overlay
            if (_isLoading) _buildLoadingOverlay(),

            // Error Overlay
            if (_hasError) _buildErrorOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfContent() {
    if (_hasError || (widget.url == null && widget.filePath == null)) {
      return const SizedBox.shrink();
    }

    return widget.url != null
        ? SfPdfViewer.network(
      widget.url!,
      key: _pdfViewerKey,
      controller: _pdfViewerController,
      onDocumentLoaded: _onDocumentLoaded,
      onDocumentLoadFailed: _onDocumentLoadFailed,
      onPageChanged: _onPageChanged,
      onZoomLevelChanged: (details) {
        setState(() => _currentZoom = details.newZoomLevel);
      },
    )
        : SfPdfViewer.file(
      File(widget.filePath!),
      key: _pdfViewerKey,
      controller: _pdfViewerController,
      onDocumentLoaded: _onDocumentLoaded,
      onDocumentLoadFailed: _onDocumentLoadFailed,
      onPageChanged: _onPageChanged,
      onZoomLevelChanged: (details) {
        setState(() => _currentZoom = details.newZoomLevel);
      },
    );
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _totalPages = details.document.pages.count;
        _currentZoom = _pdfViewerController.zoomLevel;
      });
      _startAutoHideTimer();
    }
  }

  void _onDocumentLoadFailed(PdfDocumentLoadFailedDetails details) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = details.error;
      });
    }
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    if (mounted) {
      setState(() => _currentPage = details.newPageNumber);
      _pageIndicatorController.forward().then((_) {
        _pageIndicatorController.reverse();
      });
    }
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !_showControls,
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return SlideTransition(
              position: _slideAnimation,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                        8, MediaQuery.of(context).padding.top + 8, 8, 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: _isNightMode
                            ? [
                          Colors.black.withOpacity(0.8),
                          Colors.black.withOpacity(0.0)
                        ]
                            : [
                          Colors.white.withOpacity(0.95),
                          Colors.white.withOpacity(0.0)
                        ],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: _isNightMode
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.arrow_back_ios_new_rounded,
                                  color: _isNightMode
                                      ? Colors.white
                                      : Colors.black),
                              onPressed: () => Navigator.pop(context),
                              tooltip: 'Back',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: _isNightMode
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _isNightMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primaryColor,
                                  AppColors.accentColor
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isNightMode
                                    ? Icons.light_mode
                                    : Icons.dark_mode,
                                color: Colors.white,
                              ),
                              onPressed: _toggleNightMode,
                              tooltip:
                              _isNightMode ? 'Light Mode' : 'Dark Mode',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !_showControls,
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                        16, 20, 16, MediaQuery.of(context).padding.bottom + 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: _isNightMode
                            ? [
                          Colors.black.withOpacity(0.9),
                          Colors.black.withOpacity(0.0)
                        ]
                            : [
                          Colors.white.withOpacity(0.95),
                          Colors.white.withOpacity(0.0)
                        ],
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Brightness Slider
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: _isNightMode
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.brightness_low,
                                    color: _isNightMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    size: 20),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: AppColors.primaryColor,
                                      inactiveTrackColor: _isNightMode
                                          ? Colors.grey[700]
                                          : Colors.grey[300],
                                      thumbColor: AppColors.primaryColor,
                                      overlayColor: AppColors.primaryColor
                                          .withOpacity(0.2),
                                      trackHeight: 4,
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 8),
                                    ),
                                    child: Slider(
                                      value: _brightness,
                                      min: 0.3,
                                      max: 1.0,
                                      onChanged: _adjustBrightness,
                                    ),
                                  ),
                                ),
                                Icon(Icons.brightness_high,
                                    color: _isNightMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    size: 20),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Navigation Controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildControlButton(
                                icon: Icons.first_page,
                                onPressed: _currentPage > 1
                                    ? () {
                                  _pdfViewerController.jumpToPage(1);
                                  _keepControlsVisible();
                                }
                                    : null,
                                tooltip: 'First Page',
                              ),
                              _buildControlButton(
                                icon: Icons.navigate_before,
                                onPressed: _currentPage > 1
                                    ? () {
                                  _pdfViewerController.previousPage();
                                  _keepControlsVisible();
                                }
                                    : null,
                                tooltip: 'Previous',
                              ),
                              _buildControlButton(
                                icon: Icons.format_list_numbered,
                                onPressed: _jumpToPage,
                                tooltip: 'Jump to Page',
                                isSpecial: true,
                              ),
                              _buildControlButton(
                                icon: Icons.navigate_next,
                                onPressed: _currentPage < _totalPages
                                    ? () {
                                  _pdfViewerController.nextPage();
                                  _keepControlsVisible();
                                }
                                    : null,
                                tooltip: 'Next',
                              ),
                              _buildControlButton(
                                icon: Icons.last_page,
                                onPressed: _currentPage < _totalPages
                                    ? () {
                                  _pdfViewerController
                                      .jumpToPage(_totalPages);
                                  _keepControlsVisible();
                                }
                                    : null,
                                tooltip: 'Last Page',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Zoom Controls
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: _isNightMode
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildZoomButton(
                                  icon: Icons.zoom_out,
                                  onPressed: _currentZoom > 1.0
                                      ? () => _updateZoom(-0.25)
                                      : null,
                                ),
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.primaryColor,
                                        AppColors.accentColor
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryColor
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${(_currentZoom * 100).toInt()}%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                _buildZoomButton(
                                  icon: Icons.zoom_in,
                                  onPressed: _currentZoom < 3.0
                                      ? () => _updateZoom(0.25)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
    bool isSpecial = false,
  }) {
    final isDisabled = onPressed == null;

    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isSpecial && !isDisabled
              ? const LinearGradient(
            colors: [AppColors.primaryColor, AppColors.accentColor],
          )
              : null,
          color: isSpecial
              ? null
              : isDisabled
              ? (_isNightMode ? Colors.grey[800] : Colors.grey[300])
              : (_isNightMode ? Colors.grey[800] : Colors.white),
          boxShadow: isDisabled
              ? []
              : [
            BoxShadow(
              color: isSpecial
                  ? AppColors.primaryColor.withOpacity(0.4)
                  : Colors.black.withOpacity(0.1),
              blurRadius: isSpecial ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(icon,
              color: isSpecial
                  ? Colors.white
                  : isDisabled
                  ? Colors.grey[500]
                  : (_isNightMode ? Colors.white : Colors.black87)),
          onPressed: onPressed,
          iconSize: isSpecial ? 26 : 24,
        ),
      ),
    );
  }

  Widget _buildZoomButton(
      {required IconData icon, required VoidCallback? onPressed}) {
    final isDisabled = onPressed == null;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDisabled
            ? (_isNightMode ? Colors.grey[800] : Colors.grey[300])
            : (_isNightMode ? Colors.grey[700] : Colors.white),
        boxShadow: isDisabled
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon,
            color: isDisabled
                ? Colors.grey[500]
                : (_isNightMode ? Colors.white : Colors.black87)),
        onPressed: onPressed,
        iconSize: 22,
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      right: 20,
      child: AnimatedBuilder(
        animation: _pageIndicatorAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pageIndicatorAnimation.value,
            child: GestureDetector(
              onTap: () {
                _jumpToPage();
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryColor, AppColors.accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_currentPage',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      height: 2,
                      width: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    Text(
                      '$_totalPages',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ NEW: Video Suggestions Button
  Widget _buildVideoSuggestionsButton() {
    return Positioned(
      bottom: 100,
      right: 20,
      child: GestureDetector(
        onTap: () {
          _showVideoSuggestionsSheet();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryColor, AppColors.accentColor],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_circle_outline, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                '${_suggestedVideos.length} Videos',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NEW: Show Video Suggestions Sheet
  void _showVideoSuggestionsSheet() {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryColor, AppColors.accentColor],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.video_library, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Related Video Lectures',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _suggestedVideos.length,
                  itemBuilder: (context, index) {
                    final video = _suggestedVideos[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: VideoThumbnailWidget(
                        video: video,
                        onTap: () {
                          Navigator.pop(context);
                          AppRoutes.navigateToYouTubePlayer(
                            context,
                            video: video,
                            relatedVideos: _suggestedVideos,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: _isNightMode ? Colors.black : Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor.withOpacity(0.2),
                        AppColors.accentColor.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  ),
                ),
                const Icon(Icons.picture_as_pdf,
                    color: AppColors.primaryColor, size: 32),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Loading PDF...',
              style: TextStyle(
                color: _isNightMode ? Colors.grey[300] : Colors.grey[800],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please wait while we prepare your document',
              style: TextStyle(
                color: _isNightMode ? Colors.grey[500] : Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: _isNightMode ? Colors.black : Colors.white,
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(Icons.error_outline,
                    size: 64, color: Colors.red.shade400),
              ),
              const SizedBox(height: 32),
              Text(
                'Failed to Load PDF',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _isNightMode ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isNightMode
                      ? Colors.grey[900]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isNightMode
                        ? Colors.grey[800]!
                        : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  _errorMessage.isNotEmpty
                      ? _errorMessage
                      : 'An unknown error occurred while loading the PDF document.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isNightMode ? Colors.grey[400] : Colors.grey[700],
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 20),
                    label: const Text('Go Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _hasError = false;
                        _errorMessage = '';
                      });
                      // Retry loading
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          setState(() {});
                        }
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Retry'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      side: const BorderSide(
                          color: AppColors.primaryColor, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}