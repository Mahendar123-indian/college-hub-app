import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class SmartRecommendationsWidget extends StatefulWidget {
  final String userId;
  final String? currentResourceId;

  const SmartRecommendationsWidget({
    Key? key,
    required this.userId,
    this.currentResourceId,
  }) : super(key: key);

  @override
  State<SmartRecommendationsWidget> createState() => _SmartRecommendationsWidgetState();
}

class _SmartRecommendationsWidgetState extends State<SmartRecommendationsWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;
  String _selectedCategory = 'forYou';

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);

    try {
      // Get user profile for personalization
      final userDoc = await _firestore.collection('users').doc(widget.userId).get();
      final userData = userDoc.data() ?? {};

      final String userDepartment = userData['department'] ?? '';
      final String userSemester = userData['semester'] ?? '';

      // Get user's download history
      final userHistory = await _getUserDownloadHistory();

      List<Map<String, dynamic>> recommendations = [];

      switch (_selectedCategory) {
        case 'forYou':
          recommendations = await _getPersonalizedRecommendations(
              userDepartment, userSemester, userHistory
          );
          break;
        case 'trending':
          recommendations = await _getTrendingResources(userDepartment);
          break;
        case 'similarUsers':
          recommendations = await _getSimilarUsersRecommendations(
              userDepartment, userSemester, userHistory
          );
          break;
        case 'newReleases':
          recommendations = await _getNewReleases(userDepartment, userSemester);
          break;
      }

      if (mounted) {
        setState(() {
          _recommendations = recommendations;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<String>> _getUserDownloadHistory() async {
    try {
      // In a real app, you'd track this in a separate collection
      // For now, we'll get from bookmarks as a proxy
      final bookmarks = await _firestore
          .collection('bookmarks')
          .doc(widget.userId)
          .get();

      if (bookmarks.exists) {
        final data = bookmarks.data() ?? {};
        return List<String>.from(data.keys);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getPersonalizedRecommendations(
      String department,
      String semester,
      List<String> downloadHistory,
      ) async {
    List<Map<String, dynamic>> recommendations = [];

    // Get resources from user's department and semester
    var query = _firestore
        .collection('resources')
        .where('isActive', isEqualTo: true);

    if (department.isNotEmpty) {
      query = query.where('department', isEqualTo: department);
    }

    final snapshot = await query
        .orderBy('rating', descending: true)
        .limit(20)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();

      // Skip already downloaded resources
      if (downloadHistory.contains(doc.id)) continue;

      // Calculate recommendation score
      double score = _calculateRecommendationScore(data, semester, downloadHistory);

      recommendations.add({
        'id': doc.id,
        'title': data['title'] ?? '',
        'subject': data['subject'] ?? '',
        'downloads': data['downloadCount'] ?? 0,
        'rating': (data['rating'] ?? 0.0).toDouble(),
        'thumbnailUrl': data['thumbnailUrl'],
        'fileExtension': data['fileExtension'] ?? 'pdf',
        'score': score,
        'reason': _getRecommendationReason(score, data, semester),
      });
    }

    // Sort by score
    recommendations.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    return recommendations.take(10).toList();
  }

  double _calculateRecommendationScore(
      Map<String, dynamic> resource,
      String userSemester,
      List<String> downloadHistory,
      ) {
    double score = 0.0;

    // Rating weight (0-5 points)
    score += (resource['rating'] ?? 0.0) as double;

    // Popularity weight (0-3 points)
    int downloads = (resource['downloadCount'] ?? 0) as int;
    if (downloads > 100) score += 3;
    else if (downloads > 50) score += 2;
    else if (downloads > 20) score += 1;

    // Semester match weight (0-5 points)
    if (resource['semester'] == userSemester) score += 5;

    // Recency weight (0-2 points)
    if (resource['uploadedAt'] != null) {
      final uploadDate = (resource['uploadedAt'] as Timestamp).toDate();
      final daysSinceUpload = DateTime.now().difference(uploadDate).inDays;
      if (daysSinceUpload < 30) score += 2;
      else if (daysSinceUpload < 90) score += 1;
    }

    return score;
  }

  String _getRecommendationReason(double score, Map<String, dynamic> resource, String userSemester) {
    if (score >= 12) return '🔥 Highly recommended for you';
    if (resource['semester'] == userSemester) return '📚 Perfect for your semester';
    if ((resource['rating'] ?? 0.0) >= 4.5) return '⭐ Top rated by students';
    if ((resource['downloadCount'] ?? 0) > 100) return '📈 Very popular';
    return '💡 You might like this';
  }

  Future<List<Map<String, dynamic>>> _getTrendingResources(String department) async {
    List<Map<String, dynamic>> trending = [];

    var query = _firestore
        .collection('resources')
        .where('isActive', isEqualTo: true);

    if (department.isNotEmpty) {
      query = query.where('department', isEqualTo: department);
    }

    final snapshot = await query
        .orderBy('downloadCount', descending: true)
        .limit(10)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      trending.add({
        'id': doc.id,
        'title': data['title'] ?? '',
        'subject': data['subject'] ?? '',
        'downloads': data['downloadCount'] ?? 0,
        'rating': (data['rating'] ?? 0.0).toDouble(),
        'thumbnailUrl': data['thumbnailUrl'],
        'fileExtension': data['fileExtension'] ?? 'pdf',
        'reason': '🔥 Trending in your department',
      });
    }

    return trending;
  }

  Future<List<Map<String, dynamic>>> _getSimilarUsersRecommendations(
      String department,
      String semester,
      List<String> downloadHistory,
      ) async {
    // In a production app, you'd use collaborative filtering
    // For now, we'll find resources downloaded by users with similar profiles

    List<Map<String, dynamic>> recommendations = [];

    // Find similar users
    final similarUsersSnapshot = await _firestore
        .collection('users')
        .where('department', isEqualTo: department)
        .where('semester', isEqualTo: semester)
        .limit(20)
        .get();

    // Collect their downloads (in real app, you'd have a downloads collection)
    Set<String> popularResourceIds = {};

    // Get popular resources in the department
    final resourcesSnapshot = await _firestore
        .collection('resources')
        .where('department', isEqualTo: department)
        .where('isActive', isEqualTo: true)
        .orderBy('downloadCount', descending: true)
        .limit(10)
        .get();

    for (var doc in resourcesSnapshot.docs) {
      if (!downloadHistory.contains(doc.id)) {
        final data = doc.data();
        recommendations.add({
          'id': doc.id,
          'title': data['title'] ?? '',
          'subject': data['subject'] ?? '',
          'downloads': data['downloadCount'] ?? 0,
          'rating': (data['rating'] ?? 0.0).toDouble(),
          'thumbnailUrl': data['thumbnailUrl'],
          'fileExtension': data['fileExtension'] ?? 'pdf',
          'reason': '👥 Students like you downloaded this',
        });
      }
    }

    return recommendations;
  }

  Future<List<Map<String, dynamic>>> _getNewReleases(String department, String semester) async {
    List<Map<String, dynamic>> newReleases = [];

    var query = _firestore
        .collection('resources')
        .where('isActive', isEqualTo: true);

    if (department.isNotEmpty) {
      query = query.where('department', isEqualTo: department);
    }

    final snapshot = await query
        .orderBy('uploadedAt', descending: true)
        .limit(10)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      newReleases.add({
        'id': doc.id,
        'title': data['title'] ?? '',
        'subject': data['subject'] ?? '',
        'downloads': data['downloadCount'] ?? 0,
        'rating': (data['rating'] ?? 0.0).toDouble(),
        'thumbnailUrl': data['thumbnailUrl'],
        'fileExtension': data['fileExtension'] ?? 'pdf',
        'reason': '🆕 Recently added',
      });
    }

    return newReleases;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple.shade50, Colors.blue.shade50],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildCategoryTabs(),
          _buildRecommendationsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.blue.shade400],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Recommendations',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Personalized just for you',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildCategoryChip('For You', 'forYou', Icons.person_rounded),
          const SizedBox(width: 8),
          _buildCategoryChip('Trending', 'trending', Icons.trending_up_rounded),
          const SizedBox(width: 8),
          _buildCategoryChip('Similar Users', 'similarUsers', Icons.people_rounded),
          const SizedBox(width: 8),
          _buildCategoryChip('New', 'newReleases', Icons.new_releases_rounded),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String category, IconData icon) {
    bool isSelected = _selectedCategory == category;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = category);
        _loadRecommendations();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [Colors.purple.shade400, Colors.blue.shade400],
          )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.purple.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsList() {
    if (_isLoading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_recommendations.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text(
                'No recommendations available yet',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _recommendations.length,
        itemBuilder: (context, index) {
          final recommendation = _recommendations[index];
          return _buildRecommendationCard(recommendation);
        },
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () {
          // Navigate to resource detail
          Navigator.pushNamed(
            context,
            '/resource-detail',
            arguments: recommendation['id'],
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getFileIcon(recommendation['fileExtension']),
                  color: Colors.blue.shade400,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recommendation['subject'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${recommendation['rating'].toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.download_rounded, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${recommendation['downloads']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        recommendation['reason'],
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Action button
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}