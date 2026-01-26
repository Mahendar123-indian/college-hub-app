import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class SmartNotesScreen extends StatefulWidget {
  final String? resourceId;
  const SmartNotesScreen({super.key, this.resourceId});

  @override
  State<SmartNotesScreen> createState() => _SmartNotesScreenState();
}

class _SmartNotesScreenState extends State<SmartNotesScreen> with SingleTickerProviderStateMixin {
  List<Note> _notes = [];
  final _searchController = TextEditingController();
  String _viewMode = 'grid';
  String _sortBy = 'recent';
  bool _isLoading = true;
  Set<String> _selectedTags = {};
  List<String> _availableTags = [];
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadNotes();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString('smart_notes') ?? '[]';
      final List<dynamic> decoded = json.decode(notesJson);

      _notes = decoded.map((item) => Note.fromJson(item)).toList();
      _updateAvailableTags();

      _viewMode = prefs.getString('notes_view_mode') ?? 'grid';
      _sortBy = prefs.getString('notes_sort_by') ?? 'recent';

      _animationController.forward();
    } catch (e) {
      _showSnackBar('Error loading notes: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = json.encode(_notes.map((n) => n.toJson()).toList());
      await prefs.setString('smart_notes', notesJson);
      await prefs.setString('notes_view_mode', _viewMode);
      await prefs.setString('notes_sort_by', _sortBy);
    } catch (e) {
      _showSnackBar('Error saving notes: $e', isError: true);
    }
  }

  void _updateAvailableTags() {
    final tags = <String>{};
    for (var note in _notes) {
      tags.addAll(note.tags);
    }
    _availableTags = tags.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade600,
              Colors.deepOrange.shade400,
              Colors.orange.shade50
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildEnhancedHeader(),
              _buildStatsCards(),
              _buildSearchBar(),
              _buildFilterBar(),
              if (_selectedTags.isNotEmpty) _buildSelectedTagsChips(),
              Expanded(
                child: _isLoading
                    ? Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                    : _buildNotesList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart Notes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${_notes.length} ${_notes.length == 1 ? 'note' : 'notes'}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _viewMode == 'grid' ? Icons.view_list : Icons.grid_view,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () {
                setState(() {
                  _viewMode = _viewMode == 'grid' ? 'list' : 'grid';
                });
                _saveNotes();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final pinnedCount = _notes.where((n) => n.isPinned).length;
    final favoriteCount = _notes.where((n) => n.isFavorite).length;
    final todayCount = _notes.where((n) {
      final today = DateTime.now();
      return n.createdAt.year == today.year &&
          n.createdAt.month == today.month &&
          n.createdAt.day == today.day;
    }).length;

    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatCard('Total', _notes.length.toString(), Icons.note, Colors.blue),
          _buildStatCard('Today', todayCount.toString(), Icons.today, Colors.green),
          _buildStatCard('Pinned', pinnedCount.toString(), Icons.push_pin, Colors.orange),
          _buildStatCard('Favorites', favoriteCount.toString(), Icons.star, Colors.amber),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search notes, subjects, or tags...',
          prefixIcon: const Icon(Icons.search, color: Colors.orange),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() {});
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('Recent', 'recent', Icons.access_time),
          _buildFilterChip('A-Z', 'alphabetical', Icons.sort_by_alpha),
          _buildFilterChip('Subject', 'subject', Icons.category),
          _buildFilterChip('Pinned', 'pinned', Icons.push_pin),
          _buildFilterChip('Modified', 'modified', Icons.edit),
          _buildFilterChip('Favorites', 'favorites', Icons.star),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = value);
        _saveNotes();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [Colors.orange.shade600, Colors.deepOrange.shade500])
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isSelected ? Colors.orange.shade300 : Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTagsChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _selectedTags.map((tag) {
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text('#$tag'),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() => _selectedTags.remove(tag));
                },
                backgroundColor: Colors.orange.shade100,
                labelStyle: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotesList() {
    final filteredNotes = _getFilteredNotes();

    if (filteredNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.note_outlined,
                size: 80,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchController.text.isNotEmpty || _selectedTags.isNotEmpty
                  ? 'No matching notes found'
                  : 'No notes yet',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchController.text.isNotEmpty || _selectedTags.isNotEmpty
                  ? 'Try adjusting your filters'
                  : 'Start creating your first note',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (_searchController.text.isNotEmpty || _selectedTags.isNotEmpty) {
                  _searchController.clear();
                  setState(() => _selectedTags.clear());
                } else {
                  _showNoteEditor();
                }
              },
              icon: Icon(
                _searchController.text.isNotEmpty || _selectedTags.isNotEmpty
                    ? Icons.clear
                    : Icons.add,
              ),
              label: Text(
                _searchController.text.isNotEmpty || _selectedTags.isNotEmpty
                    ? 'Clear Filters'
                    : 'Create Note',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.orange.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_viewMode == 'grid') {
      return GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: filteredNotes.length,
        itemBuilder: (context, index) {
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  index * 0.05,
                  1.0,
                  curve: Curves.easeOut,
                ),
              ),
            ),
            child: _buildNoteCard(filteredNotes[index]),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filteredNotes.length,
      itemBuilder: (context, index) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                index * 0.05,
                1.0,
                curve: Curves.easeOut,
              ),
            ),
          ),
          child: _buildNoteListTile(filteredNotes[index]),
        );
      },
    );
  }

  Widget _buildNoteCard(Note note) {
    return GestureDetector(
      onTap: () => _showNoteEditor(note: note),
      onLongPress: () => _showNoteOptions(note),
      child: Container(
        decoration: BoxDecoration(
          color: note.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: note.color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (note.isPinned)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.push_pin, size: 14, color: Colors.grey.shade700),
                        ),
                      if (note.isPinned && note.isFavorite) const SizedBox(width: 4),
                      if (note.isFavorite)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    note.title.isEmpty ? 'Untitled Note' : note.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: note.title.isEmpty ? Colors.grey.shade500 : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      note.content,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (note.subject.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        note.subject,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (note.tags.isNotEmpty) const SizedBox(height: 6),
                  if (note.tags.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: note.tags.take(2).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#$tag',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                    ),
                  const Spacer(),
                  Text(
                    _formatDate(note.updatedAt),
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade700, size: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (context) => _buildPopupMenuItems(note),
                  onSelected: (value) => _handleMenuAction(value, note),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteListTile(Note note) {
    return Dismissible(
      key: Key(note.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade400, Colors.red.shade600],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete Note'),
            content: const Text('Are you sure you want to delete this note?'),
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
      onDismissed: (direction) => _deleteNote(note, showConfirm: false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: note.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: note.color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              note.isPinned ? Icons.push_pin : Icons.note,
              color: Colors.orange.shade700,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  note.title.isEmpty ? 'Untitled Note' : note.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: note.title.isEmpty ? Colors.grey.shade500 : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (note.isFavorite)
                Icon(Icons.star, size: 16, color: Colors.amber.shade700),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (note.subject.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        note.subject,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (note.subject.isNotEmpty) const SizedBox(width: 8),
                  Text(
                    _formatDate(note.updatedAt),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => _buildPopupMenuItems(note),
            onSelected: (value) => _handleMenuAction(value, note),
          ),
          onTap: () => _showNoteEditor(note: note),
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildPopupMenuItems(Note note) {
    return <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        value: 'pin',
        child: Row(
          children: [
            Icon(note.isPinned ? Icons.push_pin_outlined : Icons.push_pin, size: 18),
            const SizedBox(width: 12),
            Text(note.isPinned ? 'Unpin' : 'Pin'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'favorite',
        child: Row(
          children: [
            Icon(note.isFavorite ? Icons.star_outline : Icons.star, size: 18),
            const SizedBox(width: 12),
            Text(note.isFavorite ? 'Unfavorite' : 'Favorite'),
          ],
        ),
      ),
      const PopupMenuItem<String>(
        value: 'duplicate',
        child: Row(
          children: [
            Icon(Icons.copy, size: 18),
            SizedBox(width: 12),
            Text('Duplicate'),
          ],
        ),
      ),
      const PopupMenuItem<String>(
        value: 'share',
        child: Row(
          children: [
            Icon(Icons.share, size: 18),
            SizedBox(width: 12),
            Text('Share'),
          ],
        ),
      ),
      if (_availableTags.isNotEmpty)
        const PopupMenuItem<String>(
          value: 'filter_tags',
          child: Row(
            children: [
              Icon(Icons.filter_list, size: 18),
              SizedBox(width: 12),
              Text('Filter by Tags'),
            ],
          ),
        ),
      const PopupMenuDivider(),
      const PopupMenuItem<String>(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete, size: 18, color: Colors.red),
            SizedBox(width: 12),
            Text('Delete', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    ];
  }

  void _handleMenuAction(String action, Note note) {
    switch (action) {
      case 'pin':
        _togglePin(note);
        break;
      case 'favorite':
        _toggleFavorite(note);
        break;
      case 'duplicate':
        _duplicateNote(note);
        break;
      case 'share':
        _shareNote(note);
        break;
      case 'filter_tags':
        _showFilterDialog();
        break;
      case 'delete':
        _deleteNote(note);
        break;
    }
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _showNoteEditor(),
      backgroundColor: Colors.orange.shade600,
      elevation: 8,
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }

  void _showNoteEditor({Note? note}) {
    final isEditing = note != null;
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');
    final subjectController = TextEditingController(text: note?.subject ?? '');
    final tagsController = TextEditingController(text: note?.tags.join(', ') ?? '');
    Color selectedColor = note?.color ?? Colors.blue.shade100;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.deepOrange.shade400],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Note' : 'Create New Note',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (isEditing)
                        IconButton(
                          icon: Icon(
                            note.isFavorite ? Icons.star : Icons.star_outline,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            _toggleFavorite(note);
                            Navigator.pop(context);
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    left: 24,
                    right: 24,
                    top: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: 'Note Title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.title),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: subjectController,
                        decoration: InputDecoration(
                          hintText: 'Subject (e.g., Mathematics, Physics)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.subject),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: tagsController,
                        decoration: InputDecoration(
                          hintText: 'Tags (comma separated)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.label),
                          helperText: 'Example: study, important, exam',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(
                          minHeight: 200,
                          maxHeight: 300,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: TextField(
                          controller: contentController,
                          decoration: const InputDecoration(
                            hintText: 'Start writing your note...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                          maxLines: null,
                          minLines: 8,
                          textAlignVertical: TextAlignVertical.top,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Select Color',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          Colors.blue.shade100,
                          Colors.green.shade100,
                          Colors.orange.shade100,
                          Colors.pink.shade100,
                          Colors.purple.shade100,
                          Colors.teal.shade100,
                          Colors.amber.shade100,
                          Colors.cyan.shade100,
                          Colors.lime.shade100,
                          Colors.indigo.shade100,
                        ].map((color) {
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedColor = color),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor == color ? Colors.black : Colors.grey.shade300,
                                  width: selectedColor == color ? 3 : 1,
                                ),
                                boxShadow: selectedColor == color
                                    ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                                    : [],
                              ),
                              child: selectedColor == color
                                  ? const Icon(Icons.check, size: 24, color: Colors.black87)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () => _saveNote(
                            note: note,
                            title: titleController.text.trim(),
                            content: contentController.text.trim(),
                            subject: subjectController.text.trim(),
                            tags: tagsController.text
                                .split(',')
                                .map((t) => t.trim())
                                .where((t) => t.isNotEmpty)
                                .toList(),
                            color: selectedColor,
                            context: context,
                          ),
                          child: Text(
                            isEditing ? 'Update Note' : 'Create Note',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      ),
    );
  }

  Future<void> _saveNote({
    Note? note,
    required String title,
    required String content,
    required String subject,
    required List<String> tags,
    required Color color,
    required BuildContext context,
  }) async {
    if (title.isEmpty && content.isEmpty) {
      _showSnackBar('Please add a title or content', isError: true);
      return;
    }

    final now = DateTime.now();

    if (note == null) {
      final newNote = Note(
        id: now.millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        subject: subject,
        tags: tags,
        color: color,
        createdAt: now,
        updatedAt: now,
      );
      setState(() => _notes.insert(0, newNote));
      _showSnackBar('Note created successfully');
    } else {
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        setState(() {
          _notes[index] = Note(
            id: note.id,
            title: title,
            content: content,
            subject: subject,
            tags: tags,
            color: color,
            isPinned: note.isPinned,
            isFavorite: note.isFavorite,
            createdAt: note.createdAt,
            updatedAt: now,
          );
        });
        _showSnackBar('Note updated successfully');
      }
    }

    _updateAvailableTags();
    await _saveNotes();
    Navigator.pop(context);
    _animationController.reset();
    _animationController.forward();
  }

  List<Note> _getFilteredNotes() {
    var notes = List<Note>.from(_notes);

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      notes = notes.where((n) {
        return n.title.toLowerCase().contains(query) ||
            n.content.toLowerCase().contains(query) ||
            n.subject.toLowerCase().contains(query) ||
            n.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    if (_selectedTags.isNotEmpty) {
      notes = notes.where((n) {
        return _selectedTags.every((tag) => n.tags.contains(tag));
      }).toList();
    }

    switch (_sortBy) {
      case 'recent':
        notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'modified':
        notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case 'alphabetical':
        notes.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'subject':
        notes.sort((a, b) => a.subject.toLowerCase().compareTo(b.subject.toLowerCase()));
        break;
      case 'pinned':
        notes.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
      case 'favorites':
        notes.sort((a, b) {
          if (a.isFavorite && !b.isFavorite) return -1;
          if (!a.isFavorite && b.isFavorite) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
    }

    return notes;
  }

  Future<void> _togglePin(Note note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      setState(() {
        _notes[index] = note.copyWith(isPinned: !note.isPinned);
      });
      await _saveNotes();
      _showSnackBar(note.isPinned ? 'Note unpinned' : 'Note pinned');
    }
  }

  Future<void> _toggleFavorite(Note note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      setState(() {
        _notes[index] = note.copyWith(isFavorite: !note.isFavorite);
      });
      await _saveNotes();
      _showSnackBar(note.isFavorite ? 'Removed from favorites' : 'Added to favorites');
    }
  }

  Future<void> _duplicateNote(Note note) async {
    final now = DateTime.now();
    final duplicatedNote = Note(
      id: now.millisecondsSinceEpoch.toString(),
      title: '${note.title} (Copy)',
      content: note.content,
      subject: note.subject,
      tags: note.tags,
      color: note.color,
      createdAt: now,
      updatedAt: now,
    );
    setState(() => _notes.insert(0, duplicatedNote));
    await _saveNotes();
    _showSnackBar('Note duplicated successfully');
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _deleteNote(Note note, {bool showConfirm = true}) async {
    if (showConfirm) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Note'),
          content: const Text('Are you sure you want to delete this note? This action cannot be undone.'),
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

      if (confirmed != true) return;
    }

    setState(() => _notes.removeWhere((n) => n.id == note.id));
    await _saveNotes();
    _updateAvailableTags();
    _showSnackBar('Note deleted successfully');
  }

  void _shareNote(Note note) {
    final text = '''
${note.title}

${note.content}

${note.subject.isNotEmpty ? 'Subject: ${note.subject}' : ''}
${note.tags.isNotEmpty ? 'Tags: ${note.tags.map((t) => '#$t').join(', ')}' : ''}
''';
    _showSnackBar('Share: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
  }

  void _showNoteOptions(Note note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(note.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
              title: Text(note.isPinned ? 'Unpin Note' : 'Pin Note'),
              onTap: () {
                Navigator.pop(context);
                _togglePin(note);
              },
            ),
            ListTile(
              leading: Icon(note.isFavorite ? Icons.star_outline : Icons.star),
              title: Text(note.isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
              onTap: () {
                Navigator.pop(context);
                _toggleFavorite(note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate Note'),
              onTap: () {
                Navigator.pop(context);
                _duplicateNote(note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Note'),
              onTap: () {
                Navigator.pop(context);
                _shareNote(note);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Note', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteNote(note);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Filter by Tags'),
        content: _availableTags.isEmpty
            ? const Padding(
          padding: EdgeInsets.all(20),
          child: Text('No tags available. Add tags to your notes to filter them.'),
        )
            : SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _availableTags.map((tag) {
              return CheckboxListTile(
                title: Text('#$tag'),
                value: _selectedTags.contains(tag),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          if (_selectedTags.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() => _selectedTags.clear());
                Navigator.pop(context);
              },
              child: const Text('Clear All'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }
}

class Note {
  final String id;
  final String title;
  final String content;
  final String subject;
  final List<String> tags;
  final Color color;
  final bool isPinned;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.subject,
    required this.tags,
    required this.color,
    this.isPinned = false,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'subject': subject,
      'tags': tags,
      'color': color.value,
      'isPinned': isPinned,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      subject: json['subject'],
      tags: List<String>.from(json['tags'] ?? []),
      color: Color(json['color']),
      isPinned: json['isPinned'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Note copyWith({
    String? title,
    String? content,
    String? subject,
    List<String>? tags,
    Color? color,
    bool? isPinned,
    bool? isFavorite,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      subject: subject ?? this.subject,
      tags: tags ?? this.tags,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}