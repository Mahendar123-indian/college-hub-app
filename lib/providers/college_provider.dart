import 'package:flutter/foundation.dart';
import '../data/models/college_model.dart';
import '../data/models/department_model.dart';
import '../data/repositories/college_repository.dart';

class CollegeProvider with ChangeNotifier {
  final CollegeRepository _repository = CollegeRepository();

  List<CollegeModel> _colleges = [];
  List<CollegeModel> _filteredColleges = [];
  List<DepartmentModel> _departments = [];

  CollegeModel? _selectedCollege;
  DepartmentModel? _selectedDepartment;

  bool _isLoading = false;
  String? _errorMessage;

  // ✅ ADDED: Auto-initialization constructor
  CollegeProvider() {
    _autoInitialize();
  }

  // ✅ ADDED: Auto-load colleges on provider creation
  Future<void> _autoInitialize() async {
    try {
      await fetchAllColleges();
      debugPrint('✅ CollegeProvider auto-initialized with ${_colleges.length} colleges');
    } catch (e) {
      debugPrint('⚠️ CollegeProvider auto-init failed: $e');
      // Don't throw - allow app to continue even if colleges fail to load
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════
  List<CollegeModel> get colleges => _colleges;
  List<CollegeModel> get filteredColleges => _filteredColleges;
  List<DepartmentModel> get departments => _departments;
  CollegeModel? get selectedCollege => _selectedCollege;
  DepartmentModel? get selectedDepartment => _selectedDepartment;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ✅ ADDED: Helper getters for better debugging
  bool get hasColleges => _colleges.isNotEmpty;
  bool get hasDepartments => _departments.isNotEmpty;
  bool get hasSelection => _selectedCollege != null;
  int get collegeCount => _colleges.length;
  int get departmentCount => _departments.length;

  // ═══════════════════════════════════════════════════════════════
  // METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Fetch all colleges from the repository
  Future<void> fetchAllColleges() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _colleges = await _repository.getAllColleges();
      _filteredColleges = _colleges;
      _isLoading = false;

      debugPrint('✅ Fetched ${_colleges.length} colleges');
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to fetch colleges: $e';
      debugPrint('❌ Error fetching colleges: $e');
      notifyListeners();
    }
  }

  /// Search colleges based on a string query
  Future<void> searchColleges(String query) async {
    if (query.isEmpty) {
      _filteredColleges = _colleges;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _filteredColleges = await _repository.searchColleges(query);
      _isLoading = false;
      debugPrint('🔍 Search found ${_filteredColleges.length} colleges for query: $query');
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Search failed: $e';
      debugPrint('❌ Search error: $e');
      notifyListeners();
    }
  }

  /// Select a college and automatically trigger department loading
  Future<void> selectCollege(CollegeModel college) async {
    _selectedCollege = college;
    _selectedDepartment = null; // Reset department selection for new college
    _departments = []; // Clear old departments while loading new ones

    debugPrint('📍 Selected college: ${college.name}');
    notifyListeners();

    // Fetch departments for selected college
    await fetchDepartmentsByCollege(college.id);
  }

  /// Fetch departments associated with a specific college
  Future<void> fetchDepartmentsByCollege(String collegeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _departments = await _repository.getDepartmentsByCollege(collegeId);
      _isLoading = false;

      debugPrint('✅ Fetched ${_departments.length} departments for college: $collegeId');
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to fetch departments: $e';
      _departments = [];
      debugPrint('❌ Error fetching departments: $e');
      notifyListeners();
    }
  }

  /// Select a specific department (can be null for "All Departments")
  void selectDepartment(DepartmentModel? department) {
    _selectedDepartment = department;
    debugPrint('📍 Selected department: ${department?.name ?? "All Departments"}');
    notifyListeners();
  }

  /// Clear all selected college and department data
  void clearSelection() {
    _selectedCollege = null;
    _selectedDepartment = null;
    _departments = [];
    debugPrint('🧹 Cleared all selections');
    notifyListeners();
  }

  /// Reset the college filter list to show all colleges
  void resetFilter() {
    _filteredColleges = _colleges;
    debugPrint('🔄 Reset filter - showing all ${_colleges.length} colleges');
    notifyListeners();
  }

  /// Remove error message from state
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get specific college details by its ID
  Future<CollegeModel?> getCollegeById(String collegeId) async {
    try {
      final college = await _repository.getCollegeById(collegeId);
      if (college != null) {
        debugPrint('✅ Found college: ${college.name}');
      } else {
        debugPrint('⚠️ College not found: $collegeId');
      }
      return college;
    } catch (e) {
      _errorMessage = 'Failed to fetch college: $e';
      debugPrint('❌ Error fetching college: $e');
      notifyListeners();
      return null;
    }
  }

  /// Get specific department details by its ID
  Future<DepartmentModel?> getDepartmentById(String departmentId) async {
    try {
      final department = await _repository.getDepartmentById(departmentId);
      if (department != null) {
        debugPrint('✅ Found department: ${department.name}');
      } else {
        debugPrint('⚠️ Department not found: $departmentId');
      }
      return department;
    } catch (e) {
      _errorMessage = 'Failed to fetch department: $e';
      debugPrint('❌ Error fetching department: $e');
      notifyListeners();
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ ADDED: UTILITY & DEBUG METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Refresh all data (useful for pull-to-refresh)
  Future<void> refresh() async {
    debugPrint('🔄 Refreshing colleges...');
    await fetchAllColleges();
  }

  /// Check if a specific college exists in the list
  bool hasCollege(String collegeId) {
    return _colleges.any((college) => college.id == collegeId);
  }

  /// Check if a specific department exists in the list
  bool hasDepartment(String departmentId) {
    return _departments.any((dept) => dept.id == departmentId);
  }

  /// Get college by name (case-insensitive)
  CollegeModel? getCollegeByName(String name) {
    try {
      return _colleges.firstWhere(
            (college) => college.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get department by name (case-insensitive)
  DepartmentModel? getDepartmentByName(String name) {
    try {
      return _departments.firstWhere(
            (dept) => dept.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Reset provider to initial state
  void reset() {
    _colleges = [];
    _filteredColleges = [];
    _departments = [];
    _selectedCollege = null;
    _selectedDepartment = null;
    _isLoading = false;
    _errorMessage = null;
    debugPrint('🔄 CollegeProvider reset to initial state');
    notifyListeners();
  }

  /// Print current state for debugging
  void debugPrintState() {
    debugPrint('═══ CollegeProvider State ═══');
    debugPrint('Colleges: ${_colleges.length}');
    debugPrint('Filtered Colleges: ${_filteredColleges.length}');
    debugPrint('Departments: ${_departments.length}');
    debugPrint('Selected College: ${_selectedCollege?.name ?? "None"}');
    debugPrint('Selected Department: ${_selectedDepartment?.name ?? "None"}');
    debugPrint('Loading: $_isLoading');
    debugPrint('Error: ${_errorMessage ?? "None"}');
    debugPrint('═══════════════════════════════');
  }
}