import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../../../providers/resource_provider.dart';
import '../../../providers/filter_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../config/routes.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/resource_card.dart';

class ResourceListScreen extends StatefulWidget {
  final String? category;
  final Map<String, String?>? filters;

  const ResourceListScreen({
    Key? key,
    this.category,
    this.filters,
  }) : super(key: key);

  @override
  State<ResourceListScreen> createState() => _ResourceListScreenState();
}

class _ResourceListScreenState extends State<ResourceListScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _localSearchQuery = '';
  String? _errorMessage;
  bool _isGridView = false;
  bool _showScrollToTop = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentPage = 1;
  final int _itemsPerPage = 20;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scrollController.addListener(_onScroll);

    _fadeController.forward();
    _slideController.forward();

    // ✅ LOAD RESOURCES AFTER FRAME BUILD
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFiltersAndLoad();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ✅ NEW: Initialize filters from arguments
  void _initializeFiltersAndLoad() {
    if (widget.filters != null && widget.filters!.isNotEmpty) {
      final filterProv = Provider.of<FilterProvider>(context, listen: false);

      // Apply filters from navigation arguments
      if (widget.filters!['college'] != null) {
        filterProv.setCollege(widget.filters!['college']);
      }
      if (widget.filters!['department'] != null) {
        filterProv.setDepartment(widget.filters!['department']);
      }
      if (widget.filters!['semester'] != null) {
        filterProv.setSemester(widget.filters!['semester']);
      }
      if (widget.filters!['subject'] != null) {
        filterProv.setSubject(widget.filters!['subject']);
      }
      if (widget.filters!['resourceType'] != null) {
        filterProv.setResourceType(widget.filters!['resourceType']);
      }
      if (widget.filters!['year'] != null) {
        filterProv.setYear(widget.filters!['year']);
      }
      if (widget.filters!['sortBy'] != null) {
        filterProv.setSortBy(widget.filters!['sortBy']);
      }
    }

    _loadResources();
  }

  void _onScroll() {
    if (_scrollController.offset > 400 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset <= 400 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }

    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore) {
        _loadMoreResources();
      }
    }
  }

  Future<void> _loadResources() async {
    if (!mounted) return;

    setState(() {
      _errorMessage = null;
      _currentPage = 1;
    });

    try {
      final resourceProv = Provider.of<ResourceProvider>(context, listen: false);
      final filterProv = Provider.of<FilterProvider>(context, listen: false);

      // ✅ PRIORITY: widget.filters > filterProvider
      final college = widget.filters?['college'] ?? filterProv.selectedCollege;
      final department = widget.filters?['department'] ?? filterProv.selectedDepartment;
      final semester = widget.filters?['semester'] ?? filterProv.selectedSemester;
      final year = widget.filters?['year'] ?? filterProv.selectedYear;
      final subject = widget.filters?['subject'] ?? filterProv.selectedSubject;
      final resourceType = widget.category ?? widget.filters?['resourceType'] ?? filterProv.selectedResourceType;

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔍 RESOURCE LIST SCREEN - LOADING');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📱 Category: ${widget.category}');
      debugPrint('🎯 Resource Type: $resourceType');
      debugPrint('🏫 College: $college');
      debugPrint('🎓 Department: $department');
      debugPrint('📅 Semester: $semester');
      debugPrint('📚 Subject: $subject');
      debugPrint('🗓️ Year: $year');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      await resourceProv.fetchResourcesByFilters(
        resourceType: resourceType,
        college: college,
        department: department,
        semester: semester,
        year: year,
        subject: subject,
      );

      debugPrint('✅ Fetched: ${resourceProv.resources.length} resources');

      if (filterProv.selectedSortBy != null) {
        _applySorting(resourceProv, filterProv.selectedSortBy!);
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to load resources. Please try again.');
        debugPrint('❌ ERROR: $e');
        debugPrint('📋 Stack: $stackTrace');
      }
    }
  }

  Future<void> _loadMoreResources() async {
    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _currentPage++;
      _isLoadingMore = false;
    });
  }

  void _applySorting(ResourceProvider provider, String sortBy) {
    final resources = provider.resources;

    switch (sortBy) {
      case 'newest':
        resources.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
        break;
      case 'oldest':
        resources.sort((a, b) => a.uploadedAt.compareTo(b.uploadedAt));
        break;
      case 'mostDownloaded':
        resources.sort((a, b) => b.downloadCount.compareTo(a.downloadCount));
        break;
      case 'highestRated':
        resources.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'nameAsc':
        resources.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'nameDesc':
        resources.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
    }
  }

  void _scrollToTop() {
    HapticFeedback.lightImpact();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: RefreshIndicator(
        onRefresh: _loadResources,
        color: AppColors.primaryColor,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            _buildSearchHeader(),
            _buildActiveFilters(),
            _buildQuickStats(),
            _buildResourceList(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActions(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor,
                AppColors.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getCategoryIcon(),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.category ?? 'All Resources',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Consumer<ResourceProvider>(
                    builder: (context, provider, child) {
                      final count = provider.resources.length;
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.folder_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$count resource${count != 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (provider.isLoading) ...[
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
      ),
      actions: [
        IconButton(
          icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
          onPressed: () {
            HapticFeedback.selectionClick();
            setState(() => _isGridView = !_isGridView);
          },
          tooltip: _isGridView ? 'List View' : 'Grid View',
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pushNamed(context, AppRoutes.filter).then((_) {
                  _loadResources();
                });
              },
              tooltip: 'Filters',
            ),
            Consumer<FilterProvider>(
              builder: (context, filterProv, child) {
                final count = filterProv.activeFilterCount;
                if (count == 0) return const SizedBox.shrink();

                return Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  IconData _getCategoryIcon() {
    final category = widget.category?.toLowerCase() ?? '';
    if (category.contains('notes')) return Icons.description_rounded;
    if (category.contains('exam') || category.contains('paper')) return Icons.quiz_rounded;
    if (category.contains('assignment')) return Icons.assignment_rounded;
    if (category.contains('lab')) return Icons.science_rounded;
    if (category.contains('syllabus')) return Icons.list_alt_rounded;
    if (category.contains('guide')) return Icons.library_books_rounded;
    if (category.contains('previous')) return Icons.history_edu_rounded;
    return Icons.folder_special_rounded;
  }

  Widget _buildSearchHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _localSearchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search in ${widget.category ?? 'resources'}...',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              suffixIcon: _localSearchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _localSearchQuery = '');
                  HapticFeedback.lightImpact();
                },
              )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    return SliverToBoxAdapter(
      child: Consumer<FilterProvider>(
        builder: (context, filterProv, child) {
          final filterSummary = filterProv.filterSummary;
          if (filterSummary.isEmpty) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.filter_alt_rounded,
                      size: 18,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Active Filters (${filterSummary.length})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        filterProv.clearFilters();
                        _loadResources();
                        HapticFeedback.lightImpact();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                      ),
                      child: const Text(
                        'Clear All',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: filterSummary.entries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor.withOpacity(0.15),
                            AppColors.primaryColor.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getFilterIcon(entry.key),
                            size: 14,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${entry.key}: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              filterProv.clearFilter(entry.key.toLowerCase());
                              _loadResources();
                              HapticFeedback.lightImpact();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 12,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getFilterIcon(String key) {
    switch (key.toLowerCase()) {
      case 'college':
        return Icons.school_rounded;
      case 'department':
        return Icons.category_rounded;
      case 'semester':
        return Icons.calendar_today_rounded;
      case 'subject':
        return Icons.book_rounded;
      case 'type':
        return Icons.folder_special_rounded;
      case 'year':
        return Icons.date_range_rounded;
      case 'sort':
        return Icons.sort_rounded;
      default:
        return Icons.filter_alt_rounded;
    }
  }

  Widget _buildQuickStats() {
    return SliverToBoxAdapter(
      child: Consumer<ResourceProvider>(
        builder: (context, provider, child) {
          if (provider.resources.isEmpty || provider.isLoading) {
            return const SizedBox.shrink();
          }

          final totalDownloads = provider.resources.fold<int>(
            0,
                (sum, resource) => sum + resource.downloadCount,
          );
          final avgRating = provider.resources.fold<double>(
            0.0,
                (sum, resource) => sum + resource.rating,
          ) / provider.resources.length;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.successColor.withOpacity(0.1),
                  AppColors.infoColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.download_rounded,
                  value: totalDownloads.toString(),
                  label: 'Downloads',
                  color: AppColors.successColor,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                _buildStatItem(
                  icon: Icons.star_rounded,
                  value: avgRating.toStringAsFixed(1),
                  label: 'Avg Rating',
                  color: AppColors.warningColor,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                _buildStatItem(
                  icon: Icons.folder_rounded,
                  value: provider.resources.length.toString(),
                  label: 'Files',
                  color: AppColors.infoColor,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildResourceList() {
    return Consumer<ResourceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.resources.isEmpty) {
          return SliverFillRemaining(
            child: _buildLoadingState(),
          );
        }

        if (_errorMessage != null) {
          return SliverFillRemaining(
            child: _buildErrorState(),
          );
        }

        final query = _localSearchQuery.trim().toLowerCase();
        final results = provider.resources.where((res) {
          if (query.isEmpty) return true;
          return res.title.toLowerCase().contains(query) ||
              res.subject.toLowerCase().contains(query) ||
              res.description.toLowerCase().contains(query);
        }).toList();

        if (results.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: _isGridView ? _buildGridView(results) : _buildListView(results),
        );
      },
    );
  }

  Widget _buildGridView(List results) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: child,
                ),
              );
            },
            child: ResourceCard(
              resource: results[index],
              onTap: () {
                HapticFeedback.mediumImpact();
                AppRoutes.navigateToResourceDetail(context, results[index].id);
              },
            ),
          );
        },
        childCount: results.length,
      ),
    );
  }

  Widget _buildListView(List results) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          if (index == results.length && _isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 200 + (index * 30)),
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
            child: ResourceCard(
              resource: results[index],
              onTap: () {
                HapticFeedback.mediumImpact();
                AppRoutes.navigateToResourceDetail(context, results[index].id);
              },
            ),
          );
        },
        childCount: results.length + (_isLoadingMore ? 1 : 0),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: AppColors.primaryColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading resources...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.15),
                    AppColors.accentColor.withOpacity(0.10),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 80,
                color: AppColors.primaryColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'No Resources Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _localSearchQuery.isNotEmpty
                  ? 'No results for "$_localSearchQuery"'
                  : 'Try adjusting your filters or search terms',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                if (_localSearchQuery.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _localSearchQuery = '');
                      HapticFeedback.lightImpact();
                    },
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Clear Search'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pushNamed(context, AppRoutes.filter).then((_) {
                      _loadResources();
                    });
                  },
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Adjust Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _loadResources();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_showScrollToTop) ...[
          FloatingActionButton.small(
            heroTag: 'scrollTop',
            onPressed: _scrollToTop,
            backgroundColor: Colors.white,
            elevation: 4,
            child: const Icon(Icons.arrow_upward, color: AppColors.primaryColor),
          ),
          const SizedBox(height: 12),
        ],
        FloatingActionButton(
          heroTag: 'refresh',
          onPressed: () {
            HapticFeedback.mediumImpact();
            _loadResources();
          },
          backgroundColor: AppColors.primaryColor,
          child: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}