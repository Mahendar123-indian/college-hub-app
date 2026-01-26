import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/chat_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../core/constants/color_constants.dart';

class AddGroupMembersScreen extends StatefulWidget {
  final String conversationId;
  final List<String> existingMembers;

  const AddGroupMembersScreen({
    Key? key,
    required this.conversationId,
    required this.existingMembers,
  }) : super(key: key);

  @override
  State<AddGroupMembersScreen> createState() => _AddGroupMembersScreenState();
}

class _AddGroupMembersScreenState extends State<AddGroupMembersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedMembers = {};
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() async {
    final chat = Provider.of<ChatProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.currentUser != null) {
      setState(() => _isSearching = true);
      await chat.searchUsers('', auth.currentUser!.id);
      setState(() {
        // Filter out existing members
        _searchResults = chat.searchResults
            .where((user) => !widget.existingMembers.contains(user.id))
            .toList();
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
        _searchResults = chat.searchResults
            .where((user) => !widget.existingMembers.contains(user.id))
            .toList();
        _isSearching = false;
      });
    }
  }

  Future<void> _addMembers() async {
    if (_selectedMembers.isEmpty) return;

    setState(() => _isAdding = true);

    final chat = Provider.of<ChatProvider>(context, listen: false);

    try {
      // Get member details
      final memberDetails = <String, Map<String, dynamic>>{};
      for (final user in _searchResults.where((u) => _selectedMembers.contains(u.id))) {
        memberDetails[user.id] = {
          'name': user.name,
          'photoUrl': user.photoUrl,
        };
      }

      await chat.addGroupMembers(
        widget.conversationId,
        _selectedMembers.toList(),
        memberDetails,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedMembers.length} ${_selectedMembers.length == 1 ? "member" : "members"} added',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAdding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding members: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Members'),
            if (_selectedMembers.isNotEmpty)
              Text(
                '${_selectedMembers.length} selected',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          if (_isAdding)
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
          else if (_selectedMembers.isNotEmpty)
            TextButton(
              onPressed: _addMembers,
              child: const Text(
                'Add',
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
          if (_selectedMembers.isNotEmpty) _buildSelectedMembersSection(),
          _buildSearchBar(),
          Expanded(child: _buildMembersList()),
        ],
      ),
    );
  }

  Widget _buildSelectedMembersSection() {
    final selectedUsers = _searchResults
        .where((user) => _selectedMembers.contains(user.id))
        .toList();

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${_selectedMembers.length} Selected',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
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
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null
                    ? Text(user.name[0], style: const TextStyle(color: AppColors.primaryColor))
                    : null,
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedMembers.remove(user.id));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
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
          SizedBox(
            width: 60,
            child: Text(
              user.name.split(' ').first,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10),
            ),
          ),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No contacts available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All your contacts are already in this group',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final isSelected = _selectedMembers.contains(user.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppColors.primaryColor : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
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
              backgroundColor: AppColors.primaryColor.withOpacity(0.1),
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.photoUrl == null
                  ? Text(user.name[0], style: const TextStyle(color: AppColors.primaryColor))
                  : null,
            ),
            title: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              user.college ?? 'Student',
              style: const TextStyle(fontSize: 12),
            ),
            activeColor: AppColors.primaryColor,
            controlAffinity: ListTileControlAffinity.trailing,
          ),
        );
      },
    );
  }
}