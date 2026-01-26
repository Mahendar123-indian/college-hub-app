import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../config/routes.dart';
import '../../../core/constants/color_constants.dart';
import '../../../data/models/resource_model.dart';
import '../../../providers/resource_provider.dart';
import '../../../providers/auth_provider.dart';

class ManageResourcesScreen extends StatefulWidget {
  const ManageResourcesScreen({Key? key}) : super(key: key);

  @override
  State<ManageResourcesScreen> createState() => _ManageResourcesScreenState();
}

class _ManageResourcesScreenState extends State<ManageResourcesScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterStatus = 'all'; // all, active, inactive
  Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadResources();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadResources() async {
    final provider = Provider.of<ResourceProvider>(context, listen: false);
    await provider.fetchAllResources();
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
              AppColors.primaryColor.withOpacity(0.05),
              Colors.white,
              AppColors.accentColor.withOpacity(0.05),
            ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildSearchAndFilter()),
            _buildTabBar(),
            _buildResourceList(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActions(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Manage Resources',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Consumer<ResourceProvider>(
                    builder: (context, provider, child) {
                      return Text(
                        '${provider.resources.length} total resources',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        if (_isSelectionMode) ...[
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            onPressed: _selectedIds.isEmpty ? null : _batchDelete,
            tooltip: 'Delete Selected',
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: _selectedIds.length != 1 ? null : _quickEdit,
            tooltip: 'Quick Edit',
          ),
        ],
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loadResources,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          Container(
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
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by title, department, or subject...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                _buildFilterChip('Active', 'active'),
                _buildFilterChip('Inactive', 'inactive'),
                _buildFilterChip('Featured', 'featured'),
                _buildFilterChip('Trending', 'trending'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _filterStatus = value),
        backgroundColor: Colors.white,
        selectedColor: AppColors.primaryColor.withOpacity(0.2),
        checkmarkColor: AppColors.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        child: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryColor,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Notes'),
            Tab(text: 'Papers'),
            Tab(text: 'Other'),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceList() {
    return Consumer<ResourceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Apply filters
        var resources = provider.resources.where((r) {
          // Search filter
          final matchesSearch = _searchQuery.isEmpty ||
              r.title.toLowerCase().contains(_searchQuery) ||
              r.department.toLowerCase().contains(_searchQuery) ||
              r.subject.toLowerCase().contains(_searchQuery);

          // Status filter
          final matchesStatus = _filterStatus == 'all' ||
              (_filterStatus == 'active' && r.isActive) ||
              (_filterStatus == 'inactive' && !r.isActive) ||
              (_filterStatus == 'featured' && r.isFeatured) ||
              (_filterStatus == 'trending' && r.isTrending);

          return matchesSearch && matchesStatus;
        }).toList();

        // Tab filter
        final currentTab = _tabController.index;
        if (currentTab == 1) {
          resources = resources.where((r) => r.resourceType == 'Notes').toList();
        } else if (currentTab == 2) {
          resources = resources.where((r) => r.resourceType.contains('Paper')).toList();
        } else if (currentTab == 3) {
          resources = resources
              .where((r) => r.resourceType != 'Notes' && !r.resourceType.contains('Paper'))
              .toList();
        }

        if (resources.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No resources found'),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final resource = resources[index];
              final isSelected = _selectedIds.contains(resource.id);

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: _buildResourceCard(resource, isSelected),
              );
            },
            childCount: resources.length,
          ),
        );
      },
    );
  }

  Widget _buildResourceCard(ResourceModel resource, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (_isSelectionMode) {
              setState(() {
                if (isSelected) {
                  _selectedIds.remove(resource.id);
                  if (_selectedIds.isEmpty) {
                    _isSelectionMode = false;
                  }
                } else {
                  _selectedIds.add(resource.id);
                }
              });
            } else {
              Navigator.pushNamed(
                context,
                AppRoutes.resourceDetail,
                arguments: resource.id,
              );
            }
          },
          onLongPress: () {
            setState(() {
              _isSelectionMode = true;
              _selectedIds.add(resource.id);
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_isSelectionMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedIds.add(resource.id);
                        } else {
                          _selectedIds.remove(resource.id);
                          if (_selectedIds.isEmpty) {
                            _isSelectionMode = false;
                          }
                        }
                      });
                    },
                    activeColor: AppColors.primaryColor,
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              resource.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (resource.isFeatured)
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 20,
                            ),
                          if (resource.isTrending)
                            const Icon(
                              Icons.trending_up_rounded,
                              color: Colors.green,
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${resource.department} • ${resource.semester}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatChip(
                            Icons.download_rounded,
                            resource.downloadCount.toString(),
                            Colors.green,
                          ),
                          const SizedBox(width: 8),
                          _buildStatChip(
                            Icons.remove_red_eye_rounded,
                            resource.viewCount.toString(),
                            Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          _buildStatChip(
                            Icons.star_rounded,
                            resource.rating.toStringAsFixed(1),
                            Colors.amber,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<void>(
                  icon: const Icon(Icons.more_vert_rounded),
                  itemBuilder: (context) => <PopupMenuEntry<void>>[
                    PopupMenuItem<void>(
                      child: const Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                      onTap: () {
                        Future.delayed(
                          const Duration(milliseconds: 0),
                              () => _editResource(resource),
                        );
                      },
                    ),
                    PopupMenuItem<void>(
                      child: Row(
                        children: [
                          Icon(
                            resource.isActive
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(resource.isActive ? 'Deactivate' : 'Activate'),
                        ],
                      ),
                      onTap: () {
                        Future.delayed(
                          const Duration(milliseconds: 0),
                              () => _toggleStatus(resource),
                        );
                      },
                    ),
                    PopupMenuItem<void>(
                      child: const Row(
                        children: [
                          Icon(Icons.content_copy_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                      onTap: () {
                        Future.delayed(
                          const Duration(milliseconds: 0),
                              () => _duplicateResource(resource),
                        );
                      },
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<void>(
                      child: const Row(
                        children: [
                          Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      onTap: () {
                        Future.delayed(
                          const Duration(milliseconds: 0),
                              () => _deleteResource(resource.id),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isSelectionMode && _selectedIds.isNotEmpty)
          FloatingActionButton.extended(
            heroTag: 'cancel_selection',
            onPressed: () {
              setState(() {
                _selectedIds.clear();
                _isSelectionMode = false;
              });
            },
            label: const Text('Cancel'),
            icon: const Icon(Icons.close_rounded),
            backgroundColor: Colors.grey,
          ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'add_resource',
          onPressed: () => Navigator.pushNamed(context, AppRoutes.uploadResource),
          child: const Icon(Icons.add_rounded),
          backgroundColor: AppColors.primaryColor,
        ),
      ],
    );
  }

  // Actions
  void _editResource(ResourceModel resource) {
    // Navigate to edit screen or show edit dialog
    Navigator.pushNamed(
      context,
      AppRoutes.uploadResource,
      arguments: resource,
    );
  }

  Future<void> _toggleStatus(ResourceModel resource) async {
    try {
      await FirebaseFirestore.instance
          .collection('resources')
          .doc(resource.id)
          .update({'isActive': !resource.isActive});

      _showSnack('Resource ${resource.isActive ? 'deactivated' : 'activated'}');
      _loadResources();
    } catch (e) {
      _showSnack('Failed to update status', isError: true);
    }
  }

  void _duplicateResource(ResourceModel resource) {
    // Create duplicate with "(Copy)" suffix
    final duplicate = resource.copyWith(
      title: '${resource.title} (Copy)',
      id: '', // Will be generated by Firestore
      uploadedAt: DateTime.now(),
    );

    Provider.of<ResourceProvider>(context, listen: false)
        .addResource(duplicate)
        .then((_) {
      _showSnack('Resource duplicated successfully');
      _loadResources();
    }).catchError((e) {
      _showSnack('Failed to duplicate resource', isError: true);
    });
  }

  Future<void> _deleteResource(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resource'),
        content: const Text('Are you sure you want to delete this resource?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Provider.of<ResourceProvider>(context, listen: false)
            .deleteResource(id);
        _showSnack('Resource deleted successfully');
        _loadResources();
      } catch (e) {
        _showSnack('Failed to delete resource', isError: true);
      }
    }
  }

  Future<void> _batchDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Resources'),
        content: Text('Delete ${_selectedIds.length} selected resources?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        for (var id in _selectedIds) {
          batch.delete(
            FirebaseFirestore.instance.collection('resources').doc(id),
          );
        }
        await batch.commit();

        _showSnack('${_selectedIds.length} resources deleted');
        setState(() {
          _selectedIds.clear();
          _isSelectionMode = false;
        });
        _loadResources();
      } catch (e) {
        _showSnack('Batch delete failed', isError: true);
      }
    }
  }

  void _quickEdit() {
    if (_selectedIds.length != 1) return;

    final resourceId = _selectedIds.first;
    final resource = Provider.of<ResourceProvider>(context, listen: false)
        .resources
        .firstWhere((r) => r.id == resourceId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuickEditSheet(resource: resource),
    ).then((_) {
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
      _loadResources();
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : AppColors.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Quick Edit Bottom Sheet
class _QuickEditSheet extends StatefulWidget {
  final ResourceModel resource;

  const _QuickEditSheet({required this.resource});

  @override
  State<_QuickEditSheet> createState() => _QuickEditSheetState();
}

class _QuickEditSheetState extends State<_QuickEditSheet> {
  late TextEditingController _titleController;
  late bool _isFeatured;
  late bool _isTrending;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.resource.title);
    _isFeatured = widget.resource.isFeatured;
    _isTrending = widget.resource.isTrending;
    _isActive = widget.resource.isActive;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      await FirebaseFirestore.instance
          .collection('resources')
          .doc(widget.resource.id)
          .update({
        'title': _titleController.text.trim(),
        'isFeatured': _isFeatured,
        'isTrending': _isTrending,
        'isActive': _isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resource updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(
              child: Text(
                'Quick Edit',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Featured'),
              value: _isFeatured,
              onChanged: (val) => setState(() => _isFeatured = val),
              activeColor: AppColors.primaryColor,
            ),
            SwitchListTile(
              title: const Text('Trending'),
              value: _isTrending,
              onChanged: (val) => setState(() => _isTrending = val),
              activeColor: AppColors.primaryColor,
            ),
            SwitchListTile(
              title: const Text('Active'),
              value: _isActive,
              onChanged: (val) => setState(() => _isActive = val),
              activeColor: AppColors.primaryColor,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}