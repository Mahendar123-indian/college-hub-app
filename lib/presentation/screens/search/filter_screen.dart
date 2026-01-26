import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/filter_provider.dart';
import '../../../providers/college_provider.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/color_constants.dart';

class FilterScreen extends StatefulWidget {
  final Map<String, String?>? currentFilters;
  const FilterScreen({Key? key, this.currentFilters}) : super(key: key);

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final TextEditingController _collegeSearchController = TextEditingController();
  final FocusNode _collegeSearchFocus = FocusNode();
  List<dynamic> _filteredColleges = [];
  bool _showCollegeSearch = false;

  List<String> _subjects = [];
  List<String> _years = [];
  bool _isLoadingDynamic = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _slideController.forward();
    _fadeController.forward();

    _loadDynamicData();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _collegeSearchController.dispose();
    _collegeSearchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadDynamicData() async {
    setState(() => _isLoadingDynamic = true);

    try {
      final subjectsSnapshot = await FirebaseFirestore.instance
          .collection('resources')
          .where('isActive', isEqualTo: true)
          .get();

      final subjectsSet = <String>{};
      final yearsSet = <String>{};

      for (var doc in subjectsSnapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());

        if (data['subject'] != null && data['subject'].toString().isNotEmpty) {
          subjectsSet.add(data['subject'].toString());
        }

        if (data['year'] != null && data['year'].toString().isNotEmpty) {
          yearsSet.add(data['year'].toString());
        }
      }

      if (mounted) {
        setState(() {
          _subjects = subjectsSet.toList()..sort();
          _years = yearsSet.toList()..sort((a, b) => b.compareTo(a));
          _isLoadingDynamic = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDynamic = false);
      }
    }
  }

  void _onCollegeSearchChanged(String query, List<dynamic> allColleges) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredColleges = [];
      } else {
        _filteredColleges = allColleges
            .where((college) =>
        college.name.toLowerCase().contains(query.toLowerCase()) ||
            (college.location != null &&
                college.location!.toLowerCase().contains(query.toLowerCase())))
            .toList();
      }
    });
  }

  int _getActiveFilterCount(FilterProvider provider) {
    int count = 0;
    if (provider.selectedCollege != null) count++;
    if (provider.selectedDepartment != null) count++;
    if (provider.selectedSemester != null) count++;
    if (provider.selectedSubject != null) count++;
    if (provider.selectedResourceType != null) count++;
    if (provider.selectedYear != null) count++;
    if (provider.selectedSortBy != null) count++;
    return count;
  }

  // ✅ CRITICAL FIX: Navigate to resource list with filters
  void _applyFiltersAndNavigate() {
    final filterProvider = Provider.of<FilterProvider>(context, listen: false);

    HapticFeedback.mediumImpact();

    // Close filter screen and navigate to resource list
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.resourceList,
      arguments: {
        'category': filterProvider.selectedResourceType,
        'filters': filterProvider.getFilterMap(),
      },
    );
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
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildFilterContent(),
                  ),
                ),
              ),
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Consumer<FilterProvider>(
      builder: (context, filterProvider, child) {
        final activeCount = _getActiveFilterCount(filterProvider);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (activeCount > 0)
                      Text(
                        '$activeCount active filter${activeCount > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              if (activeCount > 0)
                TextButton.icon(
                  onPressed: () {
                    filterProvider.clearFilters();
                    _collegeSearchController.clear();
                    _filteredColleges.clear();
                    _showCollegeSearch = false;
                  },
                  icon: const Icon(Icons.clear_all_rounded, size: 18),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterContent() {
    return Consumer2<FilterProvider, CollegeProvider>(
      builder: (context, filterProvider, collegeProvider, child) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnimatedFilterSection(
                title: 'College',
                icon: Icons.school_rounded,
                child: _buildProfessionalCollegeFilter(collegeProvider, filterProvider),
                delay: 0,
              ),

              if (filterProvider.selectedCollege != null)
                _buildAnimatedFilterSection(
                  title: 'Department',
                  icon: Icons.category_rounded,
                  child: _buildDepartmentFilter(collegeProvider, filterProvider),
                  delay: 100,
                ),

              _buildAnimatedFilterSection(
                title: 'Resource Type',
                icon: Icons.folder_special_rounded,
                child: _buildChipFilter(
                  options: AppConstants.resourceTypes,
                  selected: filterProvider.selectedResourceType,
                  onSelected: (value) => filterProvider.setResourceType(value),
                ),
                delay: 200,
              ),

              _buildAnimatedFilterSection(
                title: 'Semester',
                icon: Icons.calendar_today_rounded,
                child: _buildChipFilter(
                  options: AppConstants.semesters,
                  selected: filterProvider.selectedSemester,
                  onSelected: (value) => filterProvider.setSemester(value),
                ),
                delay: 300,
              ),

              if (!_isLoadingDynamic && _subjects.isNotEmpty)
                _buildAnimatedFilterSection(
                  title: 'Subject',
                  icon: Icons.book_rounded,
                  child: _buildChipFilter(
                    options: _subjects,
                    selected: filterProvider.selectedSubject,
                    onSelected: (value) => filterProvider.setSubject(value),
                  ),
                  delay: 400,
                ),

              if (!_isLoadingDynamic && _years.isNotEmpty)
                _buildAnimatedFilterSection(
                  title: 'Year',
                  icon: Icons.date_range_rounded,
                  child: _buildChipFilter(
                    options: _years,
                    selected: filterProvider.selectedYear,
                    onSelected: (value) => filterProvider.setYear(value),
                  ),
                  delay: 500,
                ),

              _buildAnimatedFilterSection(
                title: 'Sort By',
                icon: Icons.sort_rounded,
                child: _buildSortFilter(filterProvider),
                delay: 600,
              ),

              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedFilterSection({
    required String title,
    required IconData icon,
    required Widget child,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.primaryColor),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalCollegeFilter(
      CollegeProvider collegeProvider, FilterProvider filterProvider) {
    if (collegeProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (collegeProvider.colleges.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.school_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No colleges available',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (filterProvider.selectedCollege != null && !_showCollegeSearch) {
      final selectedCollege = collegeProvider.colleges.firstWhere(
            (c) => c.name == filterProvider.selectedCollege,
        orElse: () => collegeProvider.colleges.first,
      );

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryColor,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.school_rounded,
              color: AppColors.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedCollege.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                      fontSize: 15,
                    ),
                  ),
                  if (selectedCollege.location != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      selectedCollege.location!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.primaryColor),
              onPressed: () {
                filterProvider.setCollege(null);
                filterProvider.setDepartment(null);
                _collegeSearchController.clear();
                _filteredColleges.clear();
                setState(() => _showCollegeSearch = false);
              },
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: _collegeSearchController,
            focusNode: _collegeSearchFocus,
            onChanged: (query) {
              setState(() => _showCollegeSearch = true);
              _onCollegeSearchChanged(query, collegeProvider.colleges);
            },
            decoration: InputDecoration(
              hintText: 'Search your college...',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[600]),
              suffixIcon: _collegeSearchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () {
                  _collegeSearchController.clear();
                  _filteredColleges.clear();
                  setState(() => _showCollegeSearch = false);
                },
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 12),

        if (!_showCollegeSearch || _collegeSearchController.text.isEmpty) ...[
          Text(
            'Popular Colleges',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          ...collegeProvider.colleges.take(5).map((college) {
            return _buildCollegeCard(college, filterProvider);
          }).toList(),
        ] else if (_filteredColleges.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No colleges found',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          Text(
            '${_filteredColleges.length} result${_filteredColleges.length > 1 ? 's' : ''} found',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          ..._filteredColleges.map((college) {
            return _buildCollegeCard(college, filterProvider);
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildCollegeCard(dynamic college, FilterProvider filterProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            filterProvider.setCollege(college.name);
            filterProvider.setDepartment(null);
            setState(() {
              _showCollegeSearch = false;
              _collegeSearchController.clear();
              _filteredColleges.clear();
            });
            _collegeSearchFocus.unfocus();
            HapticFeedback.lightImpact();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        college.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (college.location != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          college.location!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentFilter(
      CollegeProvider collegeProvider, FilterProvider filterProvider) {
    final selectedCollege = collegeProvider.colleges.firstWhere(
          (c) => c.name == filterProvider.selectedCollege,
      orElse: () => collegeProvider.colleges.first,
    );

    if (selectedCollege.departments.isEmpty) {
      return const Text(
        'No departments available',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: selectedCollege.departments.map((dept) {
        final isSelected = filterProvider.selectedDepartment == dept;

        return FilterChip(
          label: Text(dept),
          selected: isSelected,
          onSelected: (selected) {
            filterProvider.setDepartment(selected ? dept : null);
            HapticFeedback.selectionClick();
          },
          backgroundColor: Colors.grey[100],
          selectedColor: AppColors.primaryColor.withOpacity(0.2),
          checkmarkColor: AppColors.primaryColor,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primaryColor : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChipFilter({
    required List<String> options,
    required String? selected,
    required Function(String?) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected == option;

        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (value) {
            onSelected(value ? option : null);
            HapticFeedback.selectionClick();
          },
          backgroundColor: Colors.grey[100],
          selectedColor: AppColors.primaryColor.withOpacity(0.2),
          checkmarkColor: AppColors.primaryColor,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primaryColor : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSortFilter(FilterProvider filterProvider) {
    final sortOptions = {
      'newest': 'Newest First',
      'oldest': 'Oldest First',
      'mostDownloaded': 'Most Downloaded',
      'highestRated': 'Highest Rated',
      'nameAsc': 'Name (A-Z)',
      'nameDesc': 'Name (Z-A)',
    };

    return Column(
      children: sortOptions.entries.map((entry) {
        return RadioListTile<String>(
          title: Text(
            entry.value,
            style: const TextStyle(fontSize: 14),
          ),
          value: entry.key,
          groupValue: filterProvider.selectedSortBy,
          onChanged: (value) {
            filterProvider.setSortBy(value);
            HapticFeedback.selectionClick();
          },
          activeColor: AppColors.primaryColor,
          contentPadding: EdgeInsets.zero,
          dense: true,
        );
      }).toList(),
    );
  }

  Widget _buildBottomActions() {
    return Consumer<FilterProvider>(
      builder: (context, filterProvider, child) {
        final activeCount = _getActiveFilterCount(filterProvider);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                if (activeCount > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        filterProvider.clearFilters();
                        _collegeSearchController.clear();
                        _filteredColleges.clear();
                        setState(() => _showCollegeSearch = false);
                        HapticFeedback.mediumImpact();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _applyFiltersAndNavigate, // ✅ FIXED
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      activeCount > 0
                          ? 'Apply $activeCount Filter${activeCount > 1 ? 's' : ''}'
                          : 'Show All Resources',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}