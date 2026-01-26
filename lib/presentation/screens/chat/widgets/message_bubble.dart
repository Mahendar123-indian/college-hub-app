import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:google_fonts/google_fonts.dart';
import '../../../../data/models/message_model.dart';
import '../../../../core/constants/color_constants.dart';
import 'image_message_widget.dart';
import 'file_message_widget.dart';
import 'voice_message_widget.dart';

/// ═══════════════════════════════════════════════════════════════
/// ENHANCED MESSAGE BUBBLE - PRODUCTION READY
/// Features:
/// ✅ Proper media rendering (images, files, voice)
/// ✅ Swipe to reply with haptic feedback
/// ✅ Double tap to react with heart animation
/// ✅ Long press for message options
/// ✅ Real-time read receipts
/// ✅ Message reactions display
/// ✅ Edit indicator
/// ✅ Forwarded message indicator
/// ✅ Reply preview
/// ✅ Copy functionality
/// ═══════════════════════════════════════════════════════════════

class MessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback onReply;
  final Function(String emoji) onReact;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final VoidCallback onForward;
  final VoidCallback onPin;
  final VoidCallback? onCopy;  // ✅ ADDED

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.onReply,
    required this.onReact,
    required this.onDelete,
    required this.onForward,
    required this.onPin,
    this.onEdit,
    this.onCopy,  // ✅ ADDED
  }) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _heartController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _heartScaleAnimation;
  late Animation<double> _heartOpacityAnimation;

  double _swipeOffset = 0;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _heartScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 70),
    ]).animate(_heartController);

    _heartOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 80),
    ]).animate(_heartController);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    _scaleController.forward().then((_) => _scaleController.reverse());
    _showMessageOptions(context);
  }

  void _handleDoubleTap() {
    if (widget.message.isDeleted) return;
    HapticFeedback.lightImpact();
    widget.onReact('❤️');
    setState(() => _showHeart = true);
    _heartController.forward().then((_) {
      if (mounted) {
        _heartController.reset();
        setState(() => _showHeart = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if ((widget.isMe && details.primaryDelta! < 0) ||
            (!widget.isMe && details.primaryDelta! > 0)) {
          setState(() => _swipeOffset += details.primaryDelta! * 0.4);
        }
      },
      onHorizontalDragEnd: (details) {
        if (_swipeOffset.abs() > 40) {
          HapticFeedback.lightImpact();
          widget.onReply();
        }
        setState(() => _swipeOffset = 0);
      },
      onLongPress: _handleLongPress,
      onDoubleTap: _handleDoubleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Transform.translate(
          offset: Offset(_swipeOffset.clamp(-70.0, 70.0), 0),
          child: Stack(
            alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
            children: [
              if (_swipeOffset.abs() > 10) _buildReplyIndicator(),
              _buildMessageLayout(context),
              if (_showHeart) _buildHeartAnimation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyIndicator() {
    return Positioned(
      left: widget.isMe ? null : 10,
      right: widget.isMe ? 10 : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.reply_rounded,
          color: AppColors.primaryColor,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildHeartAnimation() {
    return Center(
      child: FadeTransition(
        opacity: _heartOpacityAnimation,
        child: ScaleTransition(
          scale: _heartScaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite,
              color: Colors.red,
              size: 60,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
      child: Row(
        mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.isMe) _buildAvatar(),
          if (!widget.isMe) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Forwarded indicator
                if (widget.message.isForwarded) _buildForwardedIndicator(),

                // Reply preview (if replying to another message)
                if (widget.message.replyToId != null) _buildReplyPreview(),

                // Main message bubble
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: _buildBubbleDecoration(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(widget.isMe ? 16 : 4),
                      bottomRight: Radius.circular(widget.isMe ? 4 : 16),
                    ),
                    child: _buildMessageContent(context),
                  ),
                ),

                // Metadata (time, read status)
                _buildMetadata(),

                // Reactions
                if (widget.message.reactions != null && widget.message.reactions!.isNotEmpty)
                  _buildReactionsRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildBubbleDecoration() {
    return BoxDecoration(
      gradient: widget.isMe
          ? const LinearGradient(
        colors: [AppColors.primaryColor, Color(0xFFE53935)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      )
          : null,
      color: widget.isMe ? null : Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(16),
        topRight: const Radius.circular(16),
        bottomLeft: Radius.circular(widget.isMe ? 16 : 4),
        bottomRight: Radius.circular(widget.isMe ? 4 : 16),
      ),
    );
  }

  Widget _buildForwardedIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.forward_rounded,
            size: 14,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            'Forwarded',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.isMe
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 30,
            decoration: BoxDecoration(
              color: widget.isMe ? Colors.white : AppColors.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.message.replyToSenderName ?? 'Someone',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: widget.isMe ? Colors.white : AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.message.replyToContent ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: widget.isMe ? Colors.white70 : Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    if (widget.message.isDeleted) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block_rounded,
              size: 16,
              color: widget.isMe ? Colors.white70 : Colors.grey.shade500,
            ),
            const SizedBox(width: 8),
            Text(
              "This message was deleted",
              style: GoogleFonts.inter(
                fontStyle: FontStyle.italic,
                color: widget.isMe ? Colors.white70 : Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    switch (widget.message.type) {
      case MessageType.image:
        return ImageMessageWidget(
          message: widget.message,
          isMe: widget.isMe,
        );

      case MessageType.file:
        return FileMessageWidget(
          message: widget.message,
          isMe: widget.isMe,
        );

      case MessageType.voice:
        return VoiceMessageWidget(
          message: widget.message,
          isMe: widget.isMe,
        );

      case MessageType.text:
      default:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.message.content,
                style: GoogleFonts.inter(
                  color: widget.isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              if (widget.message.isEdited) ...[
                const SizedBox(height: 4),
                Text(
                  "edited",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: widget.isMe ? Colors.white60 : Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
    }
  }

  Widget _buildMetadata() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pinned indicator
          if (widget.message.isPinned) ...[
            Icon(
              Icons.push_pin,
              size: 10,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
          ],

          // Timestamp
          Text(
            timeago.format(widget.message.timestamp, locale: 'en_short'),
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Read status (for sent messages)
          if (widget.isMe) ...[
            const SizedBox(width: 4),
            Icon(
              widget.message.status == MessageStatus.read
                  ? Icons.done_all_rounded
                  : Icons.done_rounded,
              size: 14,
              color: widget.message.status == MessageStatus.read
                  ? Colors.blue
                  : Colors.grey.shade500,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReactionsRow() {
    final uniqueReactions = <String, int>{};
    widget.message.reactions?.forEach((userId, emoji) {
      uniqueReactions[emoji] = (uniqueReactions[emoji] ?? 0) + 1;
    });

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: uniqueReactions.entries.map((entry) {
          final emoji = entry.key;
          final count = entry.value;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                if (count > 1) ...[
                  const SizedBox(width: 4),
                  Text(
                    count.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 14,
        backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
        backgroundImage: widget.message.senderPhotoUrl != null
            ? CachedNetworkImageProvider(widget.message.senderPhotoUrl!)
            : null,
        child: widget.message.senderPhotoUrl == null
            ? Text(
          widget.message.senderName[0].toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        )
            : null,
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Emoji reactions
              _buildEmojiBar(context),

              Divider(color: Colors.grey.shade200, height: 1),

              // Action options
              _buildActionTile(
                icon: Icons.reply_rounded,
                title: "Reply",
                onTap: () {
                  Navigator.pop(context);
                  widget.onReply();
                },
              ),
              _buildActionTile(
                icon: Icons.forward_rounded,
                title: "Forward",
                onTap: () {
                  Navigator.pop(context);
                  widget.onForward();
                },
              ),
              _buildActionTile(
                icon: Icons.push_pin_outlined,
                title: widget.message.isPinned ? "Unpin" : "Pin",
                onTap: () {
                  Navigator.pop(context);
                  widget.onPin();
                },
              ),
              if (widget.isMe &&
                  !widget.message.isDeleted &&
                  widget.message.type == MessageType.text)
                _buildActionTile(
                  icon: Icons.edit_outlined,
                  title: "Edit",
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.onEdit != null) widget.onEdit!();
                  },
                ),

              // ✅ UPDATED: Now uses the onCopy callback
              if (widget.message.type == MessageType.text && !widget.message.isDeleted)
                _buildActionTile(
                  icon: Icons.copy_rounded,
                  title: "Copy",
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.onCopy != null) {
                      widget.onCopy!();
                    } else {
                      // Fallback if onCopy is not provided
                      Clipboard.setData(ClipboardData(text: widget.message.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 12),
                              Text(
                                "Copied to clipboard",
                                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),

              if (widget.isMe)
                _buildActionTile(
                  icon: Icons.delete_outline_rounded,
                  title: "Delete",
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onDelete();
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiBar(BuildContext context) {
    final emojis = ['❤️', '😂', '😮', '😢', '🙏', '🔥'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: emojis.map((emoji) {
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onReact(emoji);
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primaryColor).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: color ?? AppColors.primaryColor,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: color ?? Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }
}