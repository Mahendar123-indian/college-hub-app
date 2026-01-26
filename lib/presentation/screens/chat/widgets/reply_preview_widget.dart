import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../data/models/message_model.dart';
import '../../../../core/constants/color_constants.dart';

class ReplyPreviewWidget extends StatefulWidget {
  final MessageModel message;
  final VoidCallback onCancel;
  final bool isEditing;  // ✅ ADDED

  const ReplyPreviewWidget({
    Key? key,
    required this.message,
    required this.onCancel,
    this.isEditing = false,  // ✅ ADDED with default value
  }) : super(key: key);

  @override
  State<ReplyPreviewWidget> createState() => _ReplyPreviewWidgetState();
}

class _ReplyPreviewWidgetState extends State<ReplyPreviewWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleClose() async {
    await _animationController.reverse();
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, -4),
                blurRadius: 15,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient Accent Bar
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // ✅ UPDATED: Show different icon based on isEditing
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.isEditing ? Icons.edit_rounded : Icons.reply_rounded,
                        size: 20,
                        color: AppColors.primaryColor,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Content Section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ✅ UPDATED: Show different title based on isEditing
                          Text(
                            widget.isEditing
                                ? "Edit message"
                                : "Replying to ${widget.message.senderName}",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          _buildContentPreview(isDark),
                        ],
                      ),
                    ),

                    // Thumbnail for Images
                    if (widget.message.type == MessageType.image && !widget.isEditing)
                      _buildMediaThumbnail(),

                    const SizedBox(width: 12),

                    // Close Button
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: _handleClose,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentPreview(bool isDark) {
    String text = '';
    switch (widget.message.type) {
      case MessageType.image: text = "Photo"; break;
      case MessageType.voice: text = "Voice Message (${widget.message.voiceDuration}s)"; break;
      case MessageType.file: text = widget.message.fileName ?? "Document"; break;
      default: text = widget.message.content;
    }

    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: isDark ? Colors.grey[400] : Colors.grey[700],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMediaThumbnail() {
    return Container(
      width: 44,
      height: 44,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: CachedNetworkImage(
          imageUrl: widget.message.content,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: Colors.grey[200]),
        ),
      ),
    );
  }
}