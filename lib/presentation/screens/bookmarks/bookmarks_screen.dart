import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/resource_model.dart';
import '../../widgets/resource_card.dart';
import '../../../config/routes.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _filterType = 'Department';
  bool _isGridView = false;
  bool _isSelectionMode = false;
  final Set<int> _selectedIndices = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<String> _getFilterOptions(Box box) {
    final options = <String>{'All'};
    try {
      for (int i = 0; i < box.length; i++) {
        final resourceData = box.getAt(i);
        if (resourceData == null) continue;

        // Safe casting with proper error handling
        Map<String, dynamic> resourceMap;
        if (resourceData is Map<String, dynamic>) {
          resourceMap = resourceData;
        } else if (resourceData is Map) {
          resourceMap = Map<String, dynamic>.from(resourceData.map(
                (key, value) => MapEntry(key.toString(), value),
          ));
        } else {
          continue;
        }

        final resource = ResourceModel.fromMap(resourceMap);

        switch (_filterType) {
          case 'Department':
            if (resource.department.isNotEmpty) options.add(resource.department);
            break;
          case 'Semester':
            if (resource.semester.isNotEmpty) options.add(resource.semester);
            break;
          case 'Subject':
            if (resource.subject.isNotEmpty) options.add(resource.subject);
            break;
          case 'ResourceType':
            if (resource.resourceType.isNotEmpty) options.add(resource.resourceType);
            break;
        }
      }
    } catch (e) {
      debugPrint('Error getting filter options: $e');
    }
    return options.toList();
  }

  List<ResourceModel> _getFilteredResources(Box box) {
    final resources = <ResourceModel>[];
    try {
      for (int i = 0; i < box.length; i++) {
        final resourceData = box.getAt(i);
        if (resourceData == null) continue;

        // Safe casting with proper error handling
        Map<String, dynamic> resourceMap;
        if (resourceData is Map<String, dynamic>) {
          resourceMap = resourceData;
        } else if (resourceData is Map) {
          resourceMap = Map<String, dynamic>.from(resourceData.map(
                (key, value) => MapEntry(key.toString(), value),
          ));
        } else {
          continue;
        }

        final resource = ResourceModel.fromMap(resourceMap);

        // Apply filter
        if (_selectedFilter != 'All') {
          bool matches = false;
          switch (_filterType) {
            case 'Department':
              matches = resource.department == _selectedFilter;
              break;
            case 'Semester':
              matches = resource.semester == _selectedFilter;
              break;
            case 'Subject':
              matches = resource.subject == _selectedFilter;
              break;
            case 'ResourceType':
              matches = resource.resourceType == _selectedFilter;
              break;
          }
          if (!matches) continue;
        }

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final matchesTitle = resource.title.toLowerCase().contains(query);
          final matchesDescription = resource.description.toLowerCase().contains(query);
          final matchesSubject = resource.subject.toLowerCase().contains(query);
          final matchesDepartment = resource.department.toLowerCase().contains(query);
          if (!matchesTitle && !matchesDescription && !matchesSubject && !matchesDepartment) {
            continue;
          }
        }

        resources.add(resource);
      }
    } catch (e) {
      debugPrint('Error filtering resources: $e');
    }
    return resources;
  }

  void _deleteSelectedBookmarks(Box box) {
    final sortedIndices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
    for (final index in sortedIndices) {
      box.deleteAt(index);
    }
    setState(() {
      _selectedIndices.clear();
      _isSelectionMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${sortedIndices.length} bookmark(s) deleted'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _clearAllBookmarks(Box box) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear All Bookmarks?'),
        content: const Text('This action cannot be undone. All bookmarks will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              box.clear();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('All bookmarks cleared'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showFilterTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Filter By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterTypeOption('Department'),
            _buildFilterTypeOption('Semester'),
            _buildFilterTypeOption('Subject'),
            _buildFilterTypeOption('ResourceType'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTypeOption(String type) {
    final isSelected = _filterType == type;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        type == 'ResourceType' ? 'Resource Type' : type,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      onTap: () {
        setState(() {
          _filterType = type;
          _selectedFilter = 'All';
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: _isSelectionMode
            ? Text('${_selectedIndices.length} selected')
            : const Text('Bookmarks'),
        leading: _isSelectionMode
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _isSelectionMode = false;
              _selectedIndices.clear();
            });
          },
        )
            : null,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                final box = Hive.box(AppConstants.bookmarksBox);
                _deleteSelectedBookmarks(box);
              },
            )
          else ...[
            IconButton(
              icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'select',
                  child: Row(
                    children: [
                      Icon(Icons.checklist, size: 20),
                      SizedBox(width: 12),
                      Text('Select Items'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Clear All', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'select') {
                  setState(() {
                    _isSelectionMode = true;
                  });
                } else if (value == 'clear') {
                  final box = Hive.box(AppConstants.bookmarksBox);
                  _clearAllBookmarks(box);
                }
              },
            ),
          ],
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box(AppConstants.bookmarksBox).listenable(),
        builder: (context, Box box, widget) {
          if (box.isEmpty) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 140),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
                        child: Image.asset(
                          'assets/images/illustrations/no_bookmarks.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'No Bookmarks Yet',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Start bookmarking your favorite resources to access them quickly',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final filterOptions = _getFilterOptions(box);
          final filteredResources = _getFilteredResources(box);

          return FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search bookmarks...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                          : null,
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),

                // Filter Section
                if (filterOptions.length > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _showFilterTypeDialog,
                          icon: const Icon(Icons.filter_list, size: 18),
                          label: Text(_filterType == 'ResourceType' ? 'Type' : _filterType),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: filterOptions.length,
                              itemBuilder: (context, index) {
                                final option = filterOptions[index];
                                final isSelected = _selectedFilter == option;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(option),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedFilter = option;
                                      });
                                    },
                                    backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                    selectedColor: theme.colorScheme.primaryContainer,
                                    checkmarkColor: theme.colorScheme.primary,
                                    labelStyle: TextStyle(
                                      color: isSelected ? theme.colorScheme.primary : null,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Results Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        '${filteredResources.length} ${filteredResources.length == 1 ? 'bookmark' : 'bookmarks'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bookmarks List/Grid
                Expanded(
                  child: filteredResources.isEmpty
                      ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 140),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No bookmarks found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or filters',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                      : _isGridView
                      ? GridView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 120),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredResources.length,
                    itemBuilder: (context, index) {
                      final resource = filteredResources[index];
                      final actualIndex = _findResourceIndex(box, resource.id);
                      final isSelected = actualIndex != -1 && _selectedIndices.contains(actualIndex);

                      return _buildGridItem(resource, actualIndex, isSelected, theme);
                    },
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 120),
                    itemCount: filteredResources.length,
                    itemBuilder: (context, index) {
                      final resource = filteredResources[index];
                      final actualIndex = _findResourceIndex(box, resource.id);
                      final isSelected = actualIndex != -1 && _selectedIndices.contains(actualIndex);

                      return _buildListItem(resource, actualIndex, isSelected, theme);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _findResourceIndex(Box box, String resourceId) {
    try {
      for (int i = 0; i < box.length; i++) {
        final resourceData = box.getAt(i);
        if (resourceData == null) continue;

        Map<String, dynamic> resourceMap;
        if (resourceData is Map<String, dynamic>) {
          resourceMap = resourceData;
        } else if (resourceData is Map) {
          resourceMap = Map<String, dynamic>.from(resourceData.map(
                (key, value) => MapEntry(key.toString(), value),
          ));
        } else {
          continue;
        }

        final resource = ResourceModel.fromMap(resourceMap);
        if (resource.id == resourceId) return i;
      }
    } catch (e) {
      debugPrint('Error finding resource index: $e');
    }
    return -1;
  }

  Widget _buildListItem(ResourceModel resource, int index, bool isSelected, ThemeData theme) {
    if (index == -1) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (_isSelectionMode) {
              setState(() {
                if (isSelected) {
                  _selectedIndices.remove(index);
                } else {
                  _selectedIndices.add(index);
                }
              });
            } else {
              AppRoutes.navigateToResourceDetail(context, resource.id);
            }
          },
          onLongPress: () {
            if (!_isSelectionMode) {
              setState(() {
                _isSelectionMode = true;
                _selectedIndices.add(index);
              });
            }
          },
          child: Stack(
            children: [
              ResourceCard(
                resource: resource,
                onTap: () {
                  if (_isSelectionMode) {
                    setState(() {
                      if (isSelected) {
                        _selectedIndices.remove(index);
                      } else {
                        _selectedIndices.add(index);
                      }
                    });
                  } else {
                    AppRoutes.navigateToResourceDetail(context, resource.id);
                  }
                },
              ),
              if (_isSelectionMode)
                Positioned(
                  top: 12,
                  right: 12,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isSelected ? Icons.check : null,
                      color: Colors.white,
                      size: 20,
                    ),
                    padding: const EdgeInsets.all(4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(ResourceModel resource, int index, bool isSelected, ThemeData theme) {
    if (index == -1) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (_isSelectionMode) {
              setState(() {
                if (isSelected) {
                  _selectedIndices.remove(index);
                } else {
                  _selectedIndices.add(index);
                }
              });
            } else {
              AppRoutes.navigateToResourceDetail(context, resource.id);
            }
          },
          onLongPress: () {
            if (!_isSelectionMode) {
              setState(() {
                _isSelectionMode = true;
                _selectedIndices.add(index);
              });
            }
          },
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getResourceIcon(resource.resourceType),
                        color: theme.colorScheme.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              resource.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            resource.subject,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        resource.department,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isSelectionMode)
                Positioned(
                  top: 8,
                  right: 8,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isSelected ? Icons.check : null,
                      color: Colors.white,
                      size: 16,
                    ),
                    padding: const EdgeInsets.all(4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getResourceIcon(String resourceType) {
    switch (resourceType.toLowerCase()) {
      case 'notes':
        return Icons.description;
      case 'book':
        return Icons.menu_book;
      case 'video':
        return Icons.video_library;
      case 'assignment':
        return Icons.assignment;
      case 'paper':
        return Icons.article;
      default:
        return Icons.bookmark;
    }
  }
}