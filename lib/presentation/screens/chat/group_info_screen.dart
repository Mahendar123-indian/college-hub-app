import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../providers/chat_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/user_model.dart';
import '../../../core/constants/color_constants.dart';
import 'add_group_members_screen.dart';
import 'media_gallery_screen.dart';

class GroupInfoScreen extends StatefulWidget {
  final String conversationId;

  const GroupInfoScreen({
    Key? key,
    required this.conversationId,
  }) : super(key: key);

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescController = TextEditingController();
  bool _isEditingName = false;
  bool _isEditingDesc = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescController.dispose();
    super.dispose();
  }

  Future<void> _updateGroupPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && mounted) {
      final chat = Provider.of<ChatProvider>(context, listen: false);
      await chat.updateGroupPhoto(widget.conversationId, File(image.path));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group photo updated')),
        );
      }
    }
  }

  Future<void> _updateGroupName() async {
    final name = _groupNameController.text.trim();
    if (name.isEmpty) return;

    final chat = Provider.of<ChatProvider>(context, listen: false);
    await chat.updateGroupName(widget.conversationId, name);

    setState(() => _isEditingName = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name updated')),
      );
    }
  }

  Future<void> _updateGroupDescription() async {
    final desc = _groupDescController.text.trim();

    final chat = Provider.of<ChatProvider>(context, listen: false);
    await chat.updateGroupDescription(widget.conversationId, desc);

    setState(() => _isEditingDesc = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final currentUserId = auth.currentUser?.id ?? '';

    return StreamBuilder<ConversationModel?>(
      stream: chat.getConversationStream(widget.conversationId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final conversation = snapshot.data!;
        final isAdmin = conversation.admins?.contains(currentUserId) ?? false;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: CustomScrollView(
            slivers: [
              _buildAppBar(conversation, isAdmin),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildGroupInfo(conversation, isAdmin),
                    const SizedBox(height: 16),
                    _buildMediaSection(),
                    const SizedBox(height: 16),
                    _buildMembersSection(conversation, isAdmin, currentUserId),
                    const SizedBox(height: 16),
                    _buildSettingsSection(conversation, isAdmin, currentUserId),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(ConversationModel conversation, bool isAdmin) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
            ),
            Center(
              child: Hero(
                tag: 'group_avatar_${widget.conversationId}',
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white24,
                      backgroundImage: conversation.groupPhoto != null
                          ? NetworkImage(conversation.groupPhoto!)
                          : null,
                      child: conversation.groupPhoto == null
                          ? const Icon(Icons.group, size: 50, color: Colors.white)
                          : null,
                    ),
                    if (isAdmin)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _updateGroupPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupInfo(ConversationModel conversation, bool isAdmin) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          Row(
            children: [
              Expanded(
                child: _isEditingName
                    ? TextField(
                  controller: _groupNameController,
                  autofocus: true,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Group name',
                    border: OutlineInputBorder(),
                  ),
                )
                    : Text(
                  conversation.groupName ?? 'Group Chat',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isAdmin)
                IconButton(
                  icon: Icon(_isEditingName ? Icons.check : Icons.edit),
                  onPressed: () {
                    if (_isEditingName) {
                      _updateGroupName();
                    } else {
                      setState(() {
                        _isEditingName = true;
                        _groupNameController.text =
                            conversation.groupName ?? '';
                      });
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Group Description',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _isEditingDesc
                    ? TextField(
                  controller: _groupDescController,
                  autofocus: true,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Add group description',
                    border: OutlineInputBorder(),
                  ),
                )
                    : Text(
                  conversation.groupDescription ??
                      'No description added',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (isAdmin)
                IconButton(
                  icon: Icon(_isEditingDesc ? Icons.check : Icons.edit),
                  onPressed: () {
                    if (_isEditingDesc) {
                      _updateGroupDescription();
                    } else {
                      setState(() {
                        _isEditingDesc = true;
                        _groupDescController.text =
                            conversation.groupDescription ?? '';
                      });
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Created ${_formatDate(conversation.createdAt)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.photo_library, color: Colors.blue),
        ),
        title: const Text('Media, Links and Docs'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MediaGalleryScreen(
                conversationId: widget.conversationId,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMembersSection(
      ConversationModel conversation,
      bool isAdmin,
      String currentUserId,
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${conversation.participantIds.length} Members',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isAdmin)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddGroupMembersScreen(
                            conversationId: widget.conversationId,
                            existingMembers: conversation.participantIds,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Add'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: conversation.participantIds.length,
            itemBuilder: (context, index) {
              final memberId = conversation.participantIds[index];
              final memberDetails = conversation.participantDetails[memberId];
              final isGroupAdmin = conversation.admins?.contains(memberId) ?? false;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                  backgroundImage: memberDetails?['photoUrl'] != null
                      ? NetworkImage(memberDetails!['photoUrl'])
                      : null,
                  child: memberDetails?['photoUrl'] == null
                      ? Text(memberDetails?['name']?[0] ?? 'U')
                      : null,
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        memberDetails?['name'] ?? 'User',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (memberId == currentUserId)
                      const Text(
                        ' (You)',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
                subtitle: Text(
                  isGroupAdmin ? 'Admin' : 'Member',
                  style: TextStyle(
                    color: isGroupAdmin ? Colors.green : Colors.grey,
                    fontSize: 12,
                  ),
                ),
                trailing: isAdmin && memberId != currentUserId
                    ? PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'make_admin':
                        _makeAdmin(memberId);
                        break;
                      case 'remove_admin':
                        _removeAdmin(memberId);
                        break;
                      case 'remove':
                        _removeMember(memberId);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (!isGroupAdmin)
                      const PopupMenuItem(
                        value: 'make_admin',
                        child: Text('Make Admin'),
                      ),
                    if (isGroupAdmin)
                      const PopupMenuItem(
                        value: 'remove_admin',
                        child: Text('Remove Admin'),
                      ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text(
                        'Remove from group',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
      ConversationModel conversation,
      bool isAdmin,
      String currentUserId,
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          if (isAdmin)
            SwitchListTile(
              title: const Text('Only admins can send messages'),
              value: conversation.onlyAdminsCanSend ?? false,
              onChanged: (value) {
                Provider.of<ChatProvider>(context, listen: false)
                    .updateGroupSettings(
                  widget.conversationId,
                  onlyAdminsCanSend: value,
                );
              },
              secondary: const Icon(Icons.lock_outline),
            ),
          if (isAdmin) const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.exit_to_app, color: Colors.red),
            ),
            title: const Text(
              'Exit Group',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _showExitDialog(isAdmin),
          ),
          if (isAdmin) ...[
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.red),
              ),
              title: const Text(
                'Delete Group',
                style: TextStyle(color: Colors.red),
              ),
              onTap: _showDeleteDialog,
            ),
          ],
        ],
      ),
    );
  }

  void _makeAdmin(String memberId) {
    Provider.of<ChatProvider>(context, listen: false).makeGroupAdmin(
      widget.conversationId,
      memberId,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Member promoted to admin')),
    );
  }

  void _removeAdmin(String memberId) {
    Provider.of<ChatProvider>(context, listen: false).removeGroupAdmin(
      widget.conversationId,
      memberId,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Admin role removed')),
    );
  }

  void _removeMember(String memberId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member?'),
        content: const Text('This member will be removed from the group.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<ChatProvider>(context, listen: false)
                  .removeGroupMember(widget.conversationId, memberId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Member removed')),
              );
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(bool isAdmin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Group?'),
        content: Text(
          isAdmin
              ? 'You are an admin. Make sure to assign another admin before leaving.'
              : 'Are you sure you want to exit this group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              Provider.of<ChatProvider>(context, listen: false).leaveGroup(
                widget.conversationId,
                auth.currentUser!.id,
              );
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close group info
              Navigator.pop(context); // Close chat
            },
            child: const Text('Exit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group?'),
        content: const Text(
          'This will permanently delete the group and all messages. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<ChatProvider>(context, listen: false)
                  .deleteGroup(widget.conversationId);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close group info
              Navigator.pop(context); // Close chat
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}