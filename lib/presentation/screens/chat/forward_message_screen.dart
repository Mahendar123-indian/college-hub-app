import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/chat_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/conversation_model.dart';
import '../../../core/constants/color_constants.dart';

class ForwardMessageScreen extends StatefulWidget {
  final List<MessageModel> messages;

  const ForwardMessageScreen({
    Key? key,
    required this.messages,
  }) : super(key: key);

  @override
  State<ForwardMessageScreen> createState() => _ForwardMessageScreenState();
}

class _ForwardMessageScreenState extends State<ForwardMessageScreen> {
  final Set<String> _selectedConversations = {};
  final TextEditingController _searchController = TextEditingController();
  List<ConversationModel> _filteredConversations = [];
  bool _isForwarding = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() {
    final chat = Provider.of<ChatProvider>(context, listen: false);
    _filteredConversations = chat.conversations.where((c) => c.isActive).toList();
  }

  void _filterConversations(String query) {
    final chat = Provider.of<ChatProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = auth.currentUser?.id ?? '';

    setState(() {
      if (query.isEmpty) {
        _filteredConversations = chat.conversations.where((c) => c.isActive).toList();
      } else {
        _filteredConversations = chat.conversations
            .where((c) =>
        c.isActive &&
            c.getDisplayName(currentUserId)
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _forwardMessages() async {
    if (_selectedConversations.isEmpty) return;

    setState(() => _isForwarding = true);

    final chat = Provider.of<ChatProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.currentUser == null) return;

    try {
      for (final conversationId in _selectedConversations) {
        for (final message in widget.messages) {
          await chat.forwardMessage(
            fromConversationId: message.conversationId,
            toConversationId: conversationId,
            messageId: message.id,
            senderId: auth.currentUser!.id,
            senderName: auth.currentUser!.name,
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Forwarded to ${_selectedConversations.length} ${_selectedConversations.length == 1 ? "chat" : "chats"}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isForwarding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error forwarding: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentUserId = auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Forward to...',
              style: TextStyle(fontSize: 18),
            ),
            if (_selectedConversations.isNotEmpty)
              Text(
                '${_selectedConversations.length} selected',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          if (_selectedConversations.isNotEmpty)
            TextButton(
              onPressed: _isForwarding ? null : _forwardMessages,
              child: _isForwarding
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'Send',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildMessagePreview(),
          Expanded(child: _buildConversationsList(currentUserId)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: _filterConversations,
        decoration: InputDecoration(
          hintText: 'Search chats...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildMessagePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              const Icon(Icons.forward, color: AppColors.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Forwarding ${widget.messages.length} ${widget.messages.length == 1 ? "message" : "messages"}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.messages.take(3).map((message) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        _getMessageIcon(message.type),
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message.type == MessageType.text
                              ? message.content
                              : _getMessageTypeLabel(message.type),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList(String currentUserId) {
    if (_filteredConversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No chats found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredConversations.length,
      itemBuilder: (context, index) {
        final conversation = _filteredConversations[index];
        final isSelected = _selectedConversations.contains(conversation.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? AppColors.primaryColor
                  : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedConversations.remove(conversation.id);
                } else {
                  _selectedConversations.add(conversation.id);
                }
              });
            },
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                  backgroundImage: conversation.getDisplayPhoto(currentUserId) != null
                      ? NetworkImage(conversation.getDisplayPhoto(currentUserId)!)
                      : null,
                  child: conversation.getDisplayPhoto(currentUserId) == null
                      ? Text(
                    conversation.getDisplayName(currentUserId)[0].toUpperCase(),
                    style: const TextStyle(color: AppColors.primaryColor),
                  )
                      : null,
                ),
                if (conversation.type == ConversationType.group)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Icon(
                        Icons.group,
                        size: 12,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              conversation.getDisplayName(currentUserId),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              conversation.type == ConversationType.group
                  ? '${conversation.participantIds.length} members'
                  : conversation.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: isSelected
                ? Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            )
                : null,
          ),
        );
      },
    );
  }

  IconData _getMessageIcon(MessageType type) {
    switch (type) {
      case MessageType.image:
        return Icons.image;
      case MessageType.file:
        return Icons.insert_drive_file;
      case MessageType.voice:
        return Icons.mic;
      default:
        return Icons.message;
    }
  }

  String _getMessageTypeLabel(MessageType type) {
    switch (type) {
      case MessageType.image:
        return 'Photo';
      case MessageType.file:
        return 'Document';
      case MessageType.voice:
        return 'Voice message';
      default:
        return 'Message';
    }
  }
}