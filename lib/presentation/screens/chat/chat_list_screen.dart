import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/conversation_model.dart';
import '../../../core/constants/color_constants.dart';
import 'chat_requests_screen.dart';
import 'chat_detail_screen_advanced.dart';
import 'user_search_screen.dart';
import 'create_group_screen.dart';
import 'friend_requests_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isFabMenuOpen = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeStreams();
    });
  }

  void _initializeStreams() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser != null) {
      final chatProv = Provider.of<ChatProvider>(context, listen: false);
      chatProv.loadConversations(auth.currentUser!.id);
      chatProv.loadChatRequests(auth.currentUser!.id);
    }
  }

  void _toggleFabMenu() {
    setState(() {
      _isFabMenuOpen = !_isFabMenuOpen;
      if (_isFabMenuOpen) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatProv = Provider.of<ChatProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildModernAppBar(chatProv, currentUser.id),
              ];
            },
            body: Column(
              children: [
                if (chatProv.chatRequests.isNotEmpty)
                  _buildRequestsBanner(chatProv),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllChatsTab(chatProv, currentUser.id),
                      _buildGroupChatsTab(chatProv, currentUser.id),
                      _buildDirectChatsTab(chatProv, currentUser.id),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isFabMenuOpen)
            GestureDetector(
              onTap: _toggleFabMenu,
              child: AnimatedOpacity(
                opacity: _isFabMenuOpen ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: _buildAdvancedFAB(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildModernAppBar(ChatProvider chatProv, String userId) {
    final unreadCount = chatProv.getTotalUnreadCount(userId);

    return SliverAppBar(
      expandedHeight: _isSearching ? 140 : 90,
      floating: true,
      pinned: false,
      snap: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Messages',
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 26,
                                  ),
                                ),
                                if (unreadCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              '${chatProv.conversations.where((c) => c.isActive).length} conversations',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isSearching ? Icons.close : Icons.search_rounded,
                          color: Colors.black,
                          size: 26,
                        ),
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
                        icon: const Icon(Icons.more_vert, color: Colors.black),
                        onSelected: (value) {
                          switch (value) {
                            case 'new_group':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CreateGroupScreen(),
                                ),
                              );
                              break;
                            case 'friend_requests':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const FriendRequestsScreen(),
                                ),
                              );
                              break;
                            case 'refresh':
                              _initializeStreams();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'new_group',
                            child: Row(
                              children: [
                                Icon(Icons.group_add, size: 20),
                                SizedBox(width: 12),
                                Text('New Group'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'friend_requests',
                            child: Row(
                              children: [
                                Icon(Icons.person_add, size: 20),
                                SizedBox(width: 12),
                                Text('Friend Requests'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'refresh',
                            child: Row(
                              children: [
                                Icon(Icons.refresh, size: 20),
                                SizedBox(width: 12),
                                Text('Refresh'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_isSearching) ...[
                    const SizedBox(height: 12),
                    _buildSearchBar(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: Colors.grey.shade600, size: 20),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primaryColor,
        indicatorWeight: 3,
        labelColor: AppColors.primaryColor,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Groups'),
          Tab(text: 'Direct'),
        ],
      ),
    );
  }

  Widget _buildAllChatsTab(ChatProvider chatProv, String currentUserId) {
    return _buildConversationList(
      chatProv.conversations.where((c) => c.isActive).toList(),
      currentUserId,
    );
  }

  Widget _buildGroupChatsTab(ChatProvider chatProv, String currentUserId) {
    final groupChats = chatProv.conversations
        .where((c) => c.isActive && c.type == ConversationType.group)
        .toList();
    return _buildConversationList(groupChats, currentUserId);
  }

  Widget _buildDirectChatsTab(ChatProvider chatProv, String currentUserId) {
    final directChats = chatProv.conversations
        .where((c) => c.isActive && c.type == ConversationType.oneToOne)
        .toList();
    return _buildConversationList(directChats, currentUserId);
  }

  Widget _buildConversationList(
      List<ConversationModel> conversations, String currentUserId) {
    final filteredConversations = _searchQuery.isEmpty
        ? conversations
        : conversations
        .where((c) => c
        .getDisplayName(currentUserId)
        .toLowerCase()
        .contains(_searchQuery))
        .toList();

    if (filteredConversations.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => _initializeStreams(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, left: 0, right: 0, bottom: 100),
        itemCount: filteredConversations.length,
        itemBuilder: (context, index) {
          final conv = filteredConversations[index];
          return _buildConversationCard(conv, currentUserId);
        },
      ),
    );
  }

  Widget _buildConversationCard(
      ConversationModel conv, String currentUserId) {
    final unread = conv.getUnreadCount(currentUserId);
    final isPinned = conv.isPinnedBy(currentUserId);
    final isMuted = conv.isMutedBy(currentUserId);

    return Dismissible(
      key: Key(conv.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade400, Colors.red.shade600],
          ),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Chat?'),
            content: const Text(
                'This will delete the conversation. This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPinned
              ? Border.all(color: Colors.amber.shade300, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Stack(
            children: [
              Hero(
                tag: 'chat_avatar_${conv.id}',
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                  backgroundImage: conv.getDisplayPhoto(currentUserId) != null
                      ? NetworkImage(conv.getDisplayPhoto(currentUserId)!)
                      : null,
                  child: conv.getDisplayPhoto(currentUserId) == null
                      ? Text(
                    conv.getDisplayName(currentUserId)[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                      : null,
                ),
              ),
              if (conv.isGroup)
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
              if (unread > 0 && !conv.isGroup)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              if (isPinned)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.push_pin, size: 14, color: Colors.amber),
                ),
              Expanded(
                child: Text(
                  conv.getDisplayName(currentUserId),
                  style: TextStyle(
                    fontWeight:
                    unread > 0 ? FontWeight.bold : FontWeight.w600,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isMuted)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.volume_off, size: 14, color: Colors.grey),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                if (conv.lastMessageSenderId == currentUserId) ...[
                  Icon(
                    _getMessageStatusIcon(conv),
                    size: 14,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    conv.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unread > 0 ? Colors.black87 : Colors.grey,
                      fontWeight:
                      unread > 0 ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeago.format(conv.lastMessageTime, locale: 'en_short'),
                style: TextStyle(
                  fontSize: 11,
                  color: unread > 0
                      ? AppColors.primaryColor
                      : Colors.grey.shade600,
                  fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (unread > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryColor, Color(0xFFE53935)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDetailScreen(
                conversationId: conv.id,
                conversationName: conv.getDisplayName(currentUserId),
                conversationPhoto: conv.getDisplayPhoto(currentUserId),
                isGroup: conv.isGroup,
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getMessageStatusIcon(ConversationModel conv) {
    return Icons.done_all;
  }

  Widget _buildRequestsBanner(ChatProvider prov) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatRequestsScreen()),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Chat Requests',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${prov.chatRequests.length} pending',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // New Chat Option
        ScaleTransition(
          scale: _fabAnimation,
          child: FadeTransition(
            opacity: _fabAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'New Chat',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Material(
                    elevation: 6,
                    shape: const CircleBorder(),
                    color: Colors.white,
                    child: InkWell(
                      onTap: () {
                        _toggleFabMenu();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserSearchScreen(),
                          ),
                        );
                      },
                      customBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: AppColors.primaryColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // New Group Option
        ScaleTransition(
          scale: _fabAnimation,
          child: FadeTransition(
            opacity: _fabAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'New Group',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Material(
                    elevation: 6,
                    shape: const CircleBorder(),
                    color: const Color(0xFF7C4DFF),
                    child: InkWell(
                      onTap: () {
                        _toggleFabMenu();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateGroupScreen(),
                          ),
                        );
                      },
                      customBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.group_add_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Main FAB
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            heroTag: null,
            backgroundColor: AppColors.primaryColor,
            elevation: 0,
            onPressed: _toggleFabMenu,
            child: AnimatedRotation(
              turns: _isFabMenuOpen ? 0.125 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _isFabMenuOpen ? Icons.close : Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
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
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No messages yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation to get connected',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserSearchScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Start Chatting'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}