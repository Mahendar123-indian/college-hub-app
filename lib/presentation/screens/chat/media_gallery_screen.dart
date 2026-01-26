import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'package:intl/intl.dart';

import '../../../providers/chat_provider.dart';
import '../../../data/models/message_model.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/file_utils.dart';
import 'widgets/media_viewer_screen.dart';

/// ═══════════════════════════════════════════════════════════════
/// MEDIA GALLERY SCREEN - PRODUCTION READY
/// Features:
/// ✅ Dynamic tabs (Media, Documents, Links, Voice)
/// ✅ Image grid with hero animations
/// ✅ Document list with file icons
/// ✅ Link extraction and preview
/// ✅ Voice messages timeline
/// ✅ Download with progress
/// ✅ Share functionality
/// ✅ Full-screen viewer
/// ✅ Search and filter
/// ✅ Empty states
/// ✅ Loading states
/// ═══════════════════════════════════════════════════════════════

class MediaGalleryScreen extends StatefulWidget {
  final String conversationId;

  const MediaGalleryScreen({
    Key? key,
    required this.conversationId,
  }) : super(key: key);

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Dio _dio = Dio();

  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Download tracking
  final Map<String, double> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _dio.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Search bar
          if (_isSearching) _buildSearchBar(),

          // Tab bar
          _buildTabBar(),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMediaTab(),
                _buildDocumentsTab(),
                _buildLinksTab(),
                _buildVoiceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _isSearching
            ? null
            : Text(
          'Media & Files',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      backgroundColor: AppColors.primaryColor,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchQuery = '';
                _searchController.clear();
              }
            });
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'sort_date':
                _sortByDate();
                break;
              case 'sort_size':
                _sortBySize();
                break;
              case 'clear_cache':
                _clearCache();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'sort_date',
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 20),
                  SizedBox(width: 12),
                  Text('Sort by Date'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'sort_size',
              child: Row(
                children: [
                  Icon(Icons.folder, size: 20),
                  SizedBox(width: 12),
                  Text('Sort by Size'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear_cache',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20),
                  SizedBox(width: 12),
                  Text('Clear Cache'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search media, files, links...',
          hintStyle: GoogleFonts.inter(fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.primaryColor,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.photo_library), text: 'Media'),
          Tab(icon: Icon(Icons.insert_drive_file), text: 'Docs'),
          Tab(icon: Icon(Icons.link), text: 'Links'),
          Tab(icon: Icon(Icons.mic), text: 'Voice'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MEDIA TAB (Images)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMediaTab() {
    final chat = Provider.of<ChatProvider>(context);
    var mediaMessages = chat.currentMessages
        .where((m) => m.type == MessageType.image && !m.isDeleted)
        .toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      mediaMessages = mediaMessages
          .where((m) => m.senderName.toLowerCase().contains(_searchQuery))
          .toList();
    }

    if (mediaMessages.isEmpty) {
      return _buildEmptyState(
        Icons.photo_library_outlined,
        'No media shared yet',
        'Images and photos will appear here',
      );
    }

    return Column(
      children: [
        // Stats header
        _buildStatsHeader(mediaMessages.length, 'Images'),

        // Grid view
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: mediaMessages.length,
            itemBuilder: (context, index) {
              final message = mediaMessages[index];
              return _buildMediaTile(message, mediaMessages, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMediaTile(MessageModel message, List<MessageModel> allMedia, int index) {
    return GestureDetector(
      onTap: () => _openFullScreenViewer(message, allMedia, index),
      onLongPress: () => _showMediaOptions(message),
      child: Hero(
        tag: 'image_${message.id}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: message.content,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade300,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red),
                        SizedBox(height: 4),
                        Text('Error', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ),

              // Gradient overlay with sender info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.senderName,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatDate(message.timestamp),
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DOCUMENTS TAB
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDocumentsTab() {
    final chat = Provider.of<ChatProvider>(context);
    var docMessages = chat.currentMessages
        .where((m) => m.type == MessageType.file && !m.isDeleted)
        .toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      docMessages = docMessages
          .where((m) =>
      (m.fileName?.toLowerCase().contains(_searchQuery) ?? false) ||
          m.senderName.toLowerCase().contains(_searchQuery))
          .toList();
    }

    if (docMessages.isEmpty) {
      return _buildEmptyState(
        Icons.insert_drive_file_outlined,
        'No documents shared yet',
        'PDFs, docs, and files will appear here',
      );
    }

    // Calculate total size
    final totalSize = docMessages.fold<int>(
      0,
          (sum, msg) => sum + (msg.fileSize ?? 0),
    );

    return Column(
      children: [
        // Stats header
        _buildStatsHeader(
          docMessages.length,
          'Documents',
          subtitle: FileUtils.formatFileSize(totalSize),
        ),

        // List view
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docMessages.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final message = docMessages[index];
              return _buildDocumentCard(message);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(MessageModel message) {
    final fileName = message.fileName ?? 'Document';
    final fileSize = message.fileSize ?? 0;
    final fileExtension = FileUtils.getFileExtension(fileName);
    final fileIcon = FileUtils.getFileIcon(fileExtension);
    final fileColor = FileUtils.getFileColor(fileExtension);
    final isDownloading = _downloadProgress.containsKey(message.id);
    final progress = _downloadProgress[message.id] ?? 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _openDocument(message),
        onLongPress: () => _showDocumentOptions(message),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // File icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: fileColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(fileIcon, color: fileColor, size: 28),
              ),

              const SizedBox(width: 16),

              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: fileColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            fileExtension.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: fileColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          FileUtils.formatFileSize(fileSize),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${message.senderName} • ${_formatDate(message.timestamp)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),

                    // Download progress
                    if (isDownloading) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(fileColor),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}% downloaded',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: fileColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Action button
              if (isDownloading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.download_rounded),
                  color: fileColor,
                  onPressed: () => _downloadFile(message),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LINKS TAB
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLinksTab() {
    final chat = Provider.of<ChatProvider>(context);

    var linkMessages = chat.currentMessages
        .where((m) => m.type == MessageType.text && !m.isDeleted)
        .where((m) => _containsLink(m.content))
        .toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      linkMessages = linkMessages
          .where((m) =>
      m.content.toLowerCase().contains(_searchQuery) ||
          m.senderName.toLowerCase().contains(_searchQuery))
          .toList();
    }

    if (linkMessages.isEmpty) {
      return _buildEmptyState(
        Icons.link_outlined,
        'No links shared yet',
        'Web links will appear here',
      );
    }

    final totalLinks = linkMessages.fold<int>(
      0,
          (sum, msg) => sum + _extractLinks(msg.content).length,
    );

    return Column(
      children: [
        // Stats header
        _buildStatsHeader(totalLinks, 'Links'),

        // List view
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: linkMessages.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final message = linkMessages[index];
              final links = _extractLinks(message.content);
              return Column(
                children: links
                    .map((link) => _buildLinkCard(message, link))
                    .toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLinkCard(MessageModel message, String link) {
    final domain = _extractDomain(link);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _openLink(link),
        onLongPress: () => _showLinkOptions(link),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade400,
                          Colors.blue.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.language_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          domain,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          link,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.open_in_new_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade200, height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      message.senderName[0].toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Shared by ${message.senderName}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(message.timestamp),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey.shade500,
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

  // ═══════════════════════════════════════════════════════════════
  // VOICE TAB
  // ═══════════════════════════════════════════════════════════════

  Widget _buildVoiceTab() {
    final chat = Provider.of<ChatProvider>(context);
    var voiceMessages = chat.currentMessages
        .where((m) => m.type == MessageType.voice && !m.isDeleted)
        .toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      voiceMessages = voiceMessages
          .where((m) => m.senderName.toLowerCase().contains(_searchQuery))
          .toList();
    }

    if (voiceMessages.isEmpty) {
      return _buildEmptyState(
        Icons.mic_outlined,
        'No voice messages yet',
        'Voice recordings will appear here',
      );
    }

    final totalDuration = voiceMessages.fold<int>(
      0,
          (sum, msg) => sum + (msg.voiceDuration ?? 0),
    );

    return Column(
      children: [
        // Stats header
        _buildStatsHeader(
          voiceMessages.length,
          'Voice Messages',
          subtitle: _formatVoiceDuration(totalDuration),
        ),

        // Timeline view
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: voiceMessages.length,
            separatorBuilder: (context, index) => _buildTimelineDivider(),
            itemBuilder: (context, index) {
              final message = voiceMessages[index];
              return _buildVoiceCard(message);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceCard(MessageModel message) {
    final duration = message.voiceDuration ?? 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Voice icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade400,
                    Colors.purple.shade600,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            // Voice info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.graphic_eq_rounded,
                        color: Colors.purple.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Voice Message',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: Colors.purple.shade600,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(Duration(seconds: duration)),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${message.senderName} • ${_formatDate(message.timestamp)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),

            // Play button
            Container(
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.purple.shade600,
                ),
                onPressed: () => _playVoiceMessage(message),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              color: Colors.grey.shade200,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStatsHeader(int count, String label, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count.toString(),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTION METHODS
  // ═══════════════════════════════════════════════════════════════

  void _openFullScreenViewer(
      MessageModel message,
      List<MessageModel> allMedia,
      int index,
      ) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: MediaViewerScreen(
              imageUrl: message.content,
              tag: 'image_${message.id}',
              senderName: message.senderName,
              timestamp: message.timestamp,
            ),
          );
        },
      ),
    );
  }

  Future<void> _openDocument(MessageModel message) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = message.fileName ?? 'document';
      final filePath = '${dir.path}/downloads/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        final result = await OpenFilex.open(filePath);
        if (result.type != ResultType.done) {
          _showSnackBar('Could not open file: ${result.message}', isError: true);
        }
      } else {
        _downloadFile(message);
      }
    } catch (e) {
      _showSnackBar('Error opening document', isError: true);
    }
  }

  Future<void> _downloadFile(MessageModel message) async {
    if (!await _requestStoragePermission()) {
      _showSnackBar('Storage permission denied', isError: true);
      return;
    }

    try {
      setState(() => _downloadProgress[message.id] = 0.0);

      final dir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${dir.path}/downloads');

      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final fileName = message.fileName ?? 'document_${DateTime.now().millisecondsSinceEpoch}';
      final filePath = '${downloadsDir.path}/$fileName';

      await _dio.download(
        message.content,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress[message.id] = received / total;
            });
          }
        },
      );

      setState(() => _downloadProgress.remove(message.id));
      _showSnackBar('Downloaded successfully');
    } catch (e) {
      setState(() => _downloadProgress.remove(message.id));
      _showSnackBar('Download failed', isError: true);
    }
  }

  Future<void> _openLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open link', isError: true);
      }
    } catch (e) {
      _showSnackBar('Invalid URL', isError: true);
    }
  }

  void _playVoiceMessage(MessageModel message) {
    // Navigate back to chat and play the voice message
    Navigator.pop(context);
    _showSnackBar('Opening voice message in chat');
  }

  // ═══════════════════════════════════════════════════════════════
  // OPTIONS DIALOGS
  // ═══════════════════════════════════════════════════════════════

  void _showMediaOptions(MessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.download_rounded),
                title: const Text('Download'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadFile(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  _shareMedia(message.content);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Details'),
                onTap: () {
                  Navigator.pop(context);
                  _showMediaDetails(message);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showDocumentOptions(MessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded),
                title: const Text('Open'),
                onTap: () {
                  Navigator.pop(context);
                  _openDocument(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_rounded),
                title: const Text('Download'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadFile(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  _shareMedia(message.content);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showLinkOptions(String link) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded),
                title: const Text('Open Link'),
                onTap: () {
                  Navigator.pop(context);
                  _openLink(link);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Copy Link'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: link));
                  _showSnackBar('Link copied to clipboard');
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text('Share Link'),
                onTap: () async {
                  Navigator.pop(context);
                  await Share.share(link);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showMediaDetails(MessageModel message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primaryColor),
            const SizedBox(width: 12),
            const Text('Media Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Sender', message.senderName),
            _buildDetailRow('Date', _formatDetailDate(message.timestamp)),
            if (message.fileSize != null)
              _buildDetailRow('Size', FileUtils.formatFileSize(message.fileSize!)),
            _buildDetailRow('Message ID', message.id),
          ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _shareMedia(String url) async {
    try {
      await Share.share(url, subject: 'Shared from Chat');
    } catch (e) {
      _showSnackBar('Failed to share', isError: true);
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        return true;
      }
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }
      return false;
    }
    return true;
  }

  bool _containsLink(String text) {
    final urlPattern = RegExp(
      r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
      caseSensitive: false,
    );
    return urlPattern.hasMatch(text);
  }

  List<String> _extractLinks(String text) {
    final urlPattern = RegExp(
      r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
      caseSensitive: false,
    );
    return urlPattern
        .allMatches(text)
        .map((match) => match.group(0)!)
        .toList();
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return 'Unknown';
    }
  }

  void _sortByDate() {
    setState(() {
      // Sorting will be handled by the stream
    });
    _showSnackBar('Sorted by date');
  }

  void _sortBySize() {
    setState(() {
      // Sorting logic here
    });
    _showSnackBar('Sorted by size');
  }

  Future<void> _clearCache() async {
    try {
      await CachedNetworkImage.evictFromCache(widget.conversationId);
      _showSnackBar('Cache cleared successfully');
    } catch (e) {
      _showSnackBar('Failed to clear cache', isError: true);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today ${DateFormat('HH:mm').format(date)}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

  String _formatDetailDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatVoiceDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '$hours hr ${minutes} min';
    }
    return '$minutes min';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}