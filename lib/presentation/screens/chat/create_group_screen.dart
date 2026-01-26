import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../providers/chat_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../core/constants/color_constants.dart';
import 'chat_detail_screen_advanced.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedMembers = {};
  List<UserModel> _searchResults = [];
  File? _groupPhoto;
  bool _isCreating = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  void _loadUsers() async {
    final chat = Provider.of<ChatProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.currentUser != null) {
      setState(() => _isSearching = true);
      await chat.searchUsers('', auth.currentUser!.id);
      setState(() {
        _searchResults = chat.searchResults;
        _isSearching = false;
      });
    }
  }

  void _searchUsers(String query) async {
    final chat = Provider.of<ChatProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.currentUser != null) {
      setState(() => _isSearching = true);
      await chat.searchUsers(query, auth.currentUser!.id);
      setState(() {
        _searchResults = chat.searchResults;
        _isSearching = false;
      });
    }
  }

  Future<void> _pickGroupPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _groupPhoto = File(image.path));
    }
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();

    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    if (_selectedMembers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least 2 members')),
      );
      return;
    }

    setState(() => _isCreating = true);

    final chat = Provider.of<ChatProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.currentUser == null) return;

    try {
      final memberIds = [..._selectedMembers, auth.currentUser!.id];
      final memberDetails = <String, Map<String, dynamic>>{};

      // Add current user details
      memberDetails[auth.currentUser!.id] = {
        'name': auth.currentUser!.name,
        'photoUrl': auth.currentUser!.photoUrl,
      };

      // Add selected members details
      for (final user in _searchResults.where((u) => _selectedMembers.contains(u.id))) {
        memberDetails[user.id] = {
          'name': user.name,
          'photoUrl': user.photoUrl,
        };
      }

      final groupId = await chat.createGroup(
        groupName: groupName,
        groupDescription: _groupDescController.text.trim(),
        memberIds: memberIds,
        memberDetails: memberDetails,
        adminId: auth.currentUser!.id,
        groupPhoto: _groupPhoto,
      );

      if (mounted && groupId != null) {
        // Navigate to the new group chat
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              conversationId: groupId,
              conversationName: groupName,
              conversationPhoto: null,
              isGroup: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating group: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        title: const Text('New Group'),
        actions: [
          if (_isCreating)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _createGroup,
              child: const Text(
                'Create',
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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildGroupInfoSection(),
                  if (_selectedMembers.isNotEmpty)
                    _buildSelectedMembersSection(),
                  _buildSearchBar(),
                  _buildMembersList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          // Group photo
          GestureDetector(
            onTap: _pickGroupPhoto,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                  backgroundImage: _groupPhoto != null ? FileImage(_groupPhoto!) : null,
                  child: _groupPhoto == null
                      ? const Icon(Icons.group, size: 50, color: AppColors.primaryColor)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
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
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Group name
          TextField(
            controller: _groupNameController,
            decoration: InputDecoration(
              hintText: 'Group Name',
              prefixIcon: const Icon(Icons.group),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Group description
          TextField(
            controller: _groupDescController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Group Description (Optional)',
              prefixIcon: const Icon(Icons.description),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedMembersSection() {
    if (_selectedMembers.isEmpty) return const SizedBox.shrink();

    final selectedUsers = _searchResults
        .where((user) => _selectedMembers.contains(user.id))
        .toList();

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${_selectedMembers.length} Members Selected',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: selectedUsers.length,
              itemBuilder: (context, index) {
                final user = selectedUsers[index];
                return _buildSelectedMemberChip(user);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedMemberChip(UserModel user) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                    user.name[0],
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedMembers.remove(user.id));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                user.name.split(' ').first,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: _searchUsers,
        decoration: InputDecoration(
          hintText: 'Search contacts...',
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

  Widget _buildMembersList() {
    if (_isSearching) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_searchResults.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No contacts found',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final isSelected = _selectedMembers.contains(user.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primaryColor : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
                : [],
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedMembers.add(user.id);
                } else {
                  _selectedMembers.remove(user.id);
                }
              });
            },
            secondary: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryColor.withOpacity(0.1),
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.photoUrl == null
                  ? Text(
                user.name[0],
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
                  : null,
            ),
            title: Text(
              user.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              user.college ?? 'Student',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            activeColor: AppColors.primaryColor,
            controlAffinity: ListTileControlAffinity.trailing,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
        );
      },
    );
  }
}