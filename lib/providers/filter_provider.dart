import 'package:flutter/foundation.dart';

class FilterProvider with ChangeNotifier {
  // Filter values
  String? _selectedCollege;
  String? _selectedDepartment;
  String? _selectedSemester;
  String? _selectedSubject;
  String? _selectedResourceType;
  String? _selectedYear;
  String? _selectedSortBy;

  // Getters
  String? get selectedCollege => _selectedCollege;
  String? get selectedDepartment => _selectedDepartment;
  String? get selectedSemester => _selectedSemester;
  String? get selectedSubject => _selectedSubject;
  String? get selectedResourceType => _selectedResourceType;
  String? get selectedYear => _selectedYear;
  String? get selectedSortBy => _selectedSortBy;

  // Check if any filters are active
  bool get hasFilters =>
      _selectedCollege != null ||
          _selectedDepartment != null ||
          _selectedSemester != null ||
          _selectedSubject != null ||
          _selectedResourceType != null ||
          _selectedYear != null ||
          _selectedSortBy != null;

  // Get active filter count
  int get activeFilterCount {
    int count = 0;
    if (_selectedCollege != null) count++;
    if (_selectedDepartment != null) count++;
    if (_selectedSemester != null) count++;
    if (_selectedSubject != null) count++;
    if (_selectedResourceType != null) count++;
    if (_selectedYear != null) count++;
    if (_selectedSortBy != null) count++;
    return count;
  }

  // Get filter summary for display
  Map<String, String> get filterSummary {
    final Map<String, String> summary = {};
    if (_selectedCollege != null) summary['College'] = _selectedCollege!;
    if (_selectedDepartment != null) summary['Department'] = _selectedDepartment!;
    if (_selectedSemester != null) summary['Semester'] = _selectedSemester!;
    if (_selectedSubject != null) summary['Subject'] = _selectedSubject!;
    if (_selectedResourceType != null) summary['Type'] = _selectedResourceType!;
    if (_selectedYear != null) summary['Year'] = _selectedYear!;
    if (_selectedSortBy != null) summary['Sort'] = _getSortLabel(_selectedSortBy!);
    return summary;
  }

  String _getSortLabel(String sortKey) {
    switch (sortKey) {
      case 'newest':
        return 'Newest';
      case 'oldest':
        return 'Oldest';
      case 'mostDownloaded':
        return 'Popular';
      case 'highestRated':
        return 'Top Rated';
      case 'nameAsc':
        return 'A-Z';
      case 'nameDesc':
        return 'Z-A';
      default:
        return sortKey;
    }
  }

  // Setters
  void setCollege(String? value) {
    _selectedCollege = value;
    notifyListeners();
  }

  void setDepartment(String? value) {
    _selectedDepartment = value;
    notifyListeners();
  }

  void setSemester(String? value) {
    _selectedSemester = value;
    notifyListeners();
  }

  void setSubject(String? value) {
    _selectedSubject = value;
    notifyListeners();
  }

  void setResourceType(String? value) {
    _selectedResourceType = value;
    notifyListeners();
  }

  void setYear(String? value) {
    _selectedYear = value;
    notifyListeners();
  }

  void setSortBy(String? value) {
    _selectedSortBy = value;
    notifyListeners();
  }

  // Batch setters
  void setFilters({
    String? college,
    String? department,
    String? semester,
    String? subject,
    String? resourceType,
    String? year,
    String? sortBy,
  }) {
    _selectedCollege = college;
    _selectedDepartment = department;
    _selectedSemester = semester;
    _selectedSubject = subject;
    _selectedResourceType = resourceType;
    _selectedYear = year;
    _selectedSortBy = sortBy;
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _selectedCollege = null;
    _selectedDepartment = null;
    _selectedSemester = null;
    _selectedSubject = null;
    _selectedResourceType = null;
    _selectedYear = null;
    _selectedSortBy = null;
    notifyListeners();
  }

  // Clear specific filter
  void clearFilter(String filterKey) {
    switch (filterKey) {
      case 'college':
        _selectedCollege = null;
        _selectedDepartment = null; // Also clear department when college is cleared
        break;
      case 'department':
        _selectedDepartment = null;
        break;
      case 'semester':
        _selectedSemester = null;
        break;
      case 'subject':
        _selectedSubject = null;
        break;
      case 'resourceType':
        _selectedResourceType = null;
        break;
      case 'year':
        _selectedYear = null;
        break;
      case 'sortBy':
        _selectedSortBy = null;
        break;
    }
    notifyListeners();
  }

  // Get filter map for API calls
  Map<String, String?> getFilterMap() {
    return {
      'college': _selectedCollege,
      'department': _selectedDepartment,
      'semester': _selectedSemester,
      'subject': _selectedSubject,
      'resourceType': _selectedResourceType,
      'year': _selectedYear,
      'sortBy': _selectedSortBy,
    };
  }

  // Load filters from saved state
  void loadFilters(Map<String, String?> filters) {
    _selectedCollege = filters['college'];
    _selectedDepartment = filters['department'];
    _selectedSemester = filters['semester'];
    _selectedSubject = filters['subject'];
    _selectedResourceType = filters['resourceType'];
    _selectedYear = filters['year'];
    _selectedSortBy = filters['sortBy'];
    notifyListeners();
  }

  // Reset to default sort
  void resetSort() {
    _selectedSortBy = 'newest';
    notifyListeners();
  }

  // Quick filter methods for common combinations
  void quickFilterBySemester(String semester) {
    _selectedSemester = semester;
    notifyListeners();
  }

  void quickFilterByResourceType(String type) {
    _selectedResourceType = type;
    notifyListeners();
  }

  void quickFilterByCollegeDepartment(String college, String? department) {
    _selectedCollege = college;
    _selectedDepartment = department;
    notifyListeners();
  }

  // Validation helpers
  bool isFilterCompatible(String filterKey, String value) {
    // Check if the filter value is compatible with current selection
    // This can be enhanced based on your business logic
    return true;
  }

  // Get suggested filters based on current selection
  List<String> getSuggestedFilters() {
    final List<String> suggestions = [];

    if (_selectedCollege == null) {
      suggestions.add('Select a college to see relevant resources');
    } else if (_selectedDepartment == null) {
      suggestions.add('Select a department for more specific results');
    }

    if (_selectedSemester == null) {
      suggestions.add('Filter by semester');
    }

    if (_selectedResourceType == null) {
      suggestions.add('Choose resource type (Notes, Papers, etc.)');
    }

    return suggestions;
  }

  // Debug helper
  void printCurrentFilters() {
    debugPrint('═══ Current Filters ═══');
    debugPrint('College: $_selectedCollege');
    debugPrint('Department: $_selectedDepartment');
    debugPrint('Semester: $_selectedSemester');
    debugPrint('Subject: $_selectedSubject');
    debugPrint('Resource Type: $_selectedResourceType');
    debugPrint('Year: $_selectedYear');
    debugPrint('Sort By: $_selectedSortBy');
    debugPrint('Total Active: $activeFilterCount');
  }
}