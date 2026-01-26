import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/previous_year_paper_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/previous_year_paper_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/color_constants.dart';
import '../../../config/routes.dart';
import 'upload_previous_year_paper_screen.dart';
import 'paper_detail_screen.dart';

class PreviousYearPapersScreen extends StatefulWidget {
  const PreviousYearPapersScreen({Key? key}) : super(key: key);

  @override
  State<PreviousYearPapersScreen> createState() => _PreviousYearPapersScreenState();
}

class _PreviousYearPapersScreenState extends State<PreviousYearPapersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String? _selectedYear;
  String? _selectedExamType;
  String? _selectedSemester;

  // Add this flag to track ifMyUploads has been loaded
  bool _myUploadsLoaded = false;

  final List<String> _years = List.generate(
    DateTime.now().year - 2015 + 1,
        (index) => (DateTime.now().year - index).toString(),
  );

  final List<String> _examTypes = [
    'Mid-Exam 1',
    'Mid-Exam 2',
    'Semester Exam',
    'Annual Exam',
    'Supplementary Exam',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Add listener to load MyUploads when tab is switched
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && !_myUploadsLoaded) {
      // Load MyUploads when switching to that tab for the first time
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final provider = Provider.of<PreviousYearPaperProvider>(context, listen: false);
      provider.fetchMyPapers(authProvider.currentUser!.id);
      _myUploadsLoaded = true;
    }
  }

  Future<void> _loadData() async {
    final provider = Provider.of<PreviousYearPaperProvider>(context, listen: false);
    await Future.wait([
      provider.fetchApprovedPapers(),
      provider.fetchRecentPapers(),
      provider.fetchTopPapers(),
    ]);
  }

  Future<void> _applyFilters() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    await Provider.of<PreviousYearPaperProvider>(context, listen: false).fetchPapersByFilters(
      college: user?.college,
      semester: _selectedSemester,
      examYear: _selectedYear,
      examType: _selectedExamType,
      onlyApproved: true,
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedYear = null;
      _selectedExamType = null;
      _selectedSemester = null;
    });
    _loadData();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Papers',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        _selectedYear = null;
                        _selectedExamType = null;
                        _selectedSemester = null;
                      });
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Year Filter
              DropdownButtonFormField<String>(
                value: _selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Exam Year',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                items: _years.map((year) {
                  return DropdownMenuItem(value: year, child: Text(year));
                }).toList(),
                onChanged: (value) {
                  setModalState(() => _selectedYear = value);
                  setState(() => _selectedYear = value);
                },
              ),
              const SizedBox(height: 16),

              // Exam Type Filter
              DropdownButtonFormField<String>(
                value: _selectedExamType,
                decoration: const InputDecoration(
                  labelText: 'Exam Type',
                  prefixIcon: Icon(Icons.school),
                ),
                items: _examTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setModalState(() => _selectedExamType = value);
                  setState(() => _selectedExamType = value);
                },
              ),
              const SizedBox(height: 16),

              // Semester Filter
              DropdownButtonFormField<String>(
                value: _selectedSemester,
                decoration: const InputDecoration(
                  labelText: 'Semester',
                  prefixIcon: Icon(Icons.stairs),
                ),
                items: AppConstants.semesters.map((sem) {
                  return DropdownMenuItem(value: sem, child: Text(sem));
                }).toList(),
                onChanged: (value) {
                  setModalState(() => _selectedSemester = value);
                  setState(() => _selectedSemester = value);
                },
              ),
              const SizedBox(height: 24),

              // Apply Button
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _applyFilters();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Apply Filters'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Previous Year Papers'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          if (_selectedYear != null || _selectedExamType != null || _selectedSemester != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearFilters,
              tooltip: 'Clear Filters',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Papers', icon: Icon(Icons.library_books)),
            Tab(text: 'My Uploads', icon: Icon(Icons.upload_file)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildAllPapersTab(),
          _buildMyUploadsTab(authProvider.currentUser!.id),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'upload_paper_fab',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UploadPreviousYearPaperScreen(),
            ),
          );
          if (result == true) {
            _loadData();
            // Reset flag to reload MyUploads on next visit
            _myUploadsLoaded = false;
          }
        },
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.upload),
        label: const Text('Upload Paper'),
      ),
    );
  }

  Widget _buildAllPapersTab() {
    return Consumer<PreviousYearPaperProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.papers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.papers.isEmpty) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: constraints.maxHeight,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open, size: 80, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No papers found',
                              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to upload!',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: provider.papers.length,
            itemBuilder: (context, index) {
              final paper = provider.papers[index];
              return _buildPaperCard(paper);
            },
          ),
        );
      },
    );
  }

  Widget _buildMyUploadsTab(String userId) {
    return Consumer<PreviousYearPaperProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.myPapers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.myPapers.isEmpty) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return RefreshIndicator(
                onRefresh: () {
                  _myUploadsLoaded = false;
                  return provider.fetchMyPapers(userId);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: constraints.maxHeight,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_file, size: 80, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No uploads yet',
                              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Upload your first paper!',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }

        return RefreshIndicator(
          onRefresh: () {
            _myUploadsLoaded = false;
            return provider.fetchMyPapers(userId);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: provider.myPapers.length,
            itemBuilder: (context, index) {
              final paper = provider.myPapers[index];
              return _buildPaperCard(paper, showStatus: true);
            },
          ),
        );
      },
    );
  }

  Widget _buildPaperCard(PreviousYearPaperModel paper, {bool showStatus = false}) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaperDetailScreen(paperId: paper.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paper.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          paper.subject,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showStatus)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: paper.isApproved
                            ? Colors.green.shade100
                            : paper.isPending
                            ? Colors.orange.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        paper.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: paper.isApproved
                              ? Colors.green.shade700
                              : paper.isPending
                              ? Colors.orange.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Details Row
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildInfoChip(Icons.calendar_today, paper.examYear, Colors.blue),
                  _buildInfoChip(Icons.school, paper.examType, Colors.purple),
                  _buildInfoChip(Icons.stairs, paper.semester, Colors.orange),
                  if (paper.regulation != null)
                    _buildInfoChip(Icons.rule, paper.regulation!, Colors.teal),
                ],
              ),
              const SizedBox(height: 12),

              // Stats Row
              Row(
                children: [
                  Icon(Icons.download, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('${paper.downloadCount}', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(width: 16),
                  Icon(Icons.visibility, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('${paper.viewCount}', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(width: 16),
                  Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Text(
                    paper.rating > 0 ? paper.rating.toStringAsFixed(1) : 'N/A',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Text(
                    paper.fileSizeFormatted,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
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
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}