import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/resource_model.dart';

class ResourceSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ═══════════════════════════════════════════════════════════════
  /// MASTER DATA LIST
  /// These match the folders and files seen in your Firebase Storage.
  /// Replace the placeholder URLs with your actual Firebase Download URLs.
  /// ═══════════════════════════════════════════════════════════════
  static final List<Map<String, dynamic>> _resourcesData = [
    {
      'id': '1765355119997',
      'title': 'Mahi Registration App Guide',
      'description': 'Step-by-step guide for student registration on the Mahi platform.',
      'college': 'Vidya Jyothi Institute of Technology',
      'department': 'CSE',
      'semester': 'Semester 1',
      'subject': 'Application Basics',
      'resourceType': 'Notes',
      'year': '2025',
      'fileUrl': 'https://firebasestorage.googleapis.com/v0/b/collegehub-711d5.firebasestorage.app/o/mahi%20registration%20app.pdf?alt=media',
      'fileName': 'mahi registration app.pdf',
      'fileExtension': 'pdf',
      'fileSize': 921487,
      'uploadedBy': 'admin_system',
    },
    {
      'id': '1765357336357',
      'title': 'SBI Account Opening Reference',
      'description': 'Documentation for opening a student savings account at SBI.',
      'college': 'JNTUH College of Engineering Hyderabad',
      'department': 'ECE',
      'semester': 'Semester 2',
      'subject': 'Finance 101',
      'resourceType': 'Previous Year Papers',
      'year': '2024',
      'fileUrl': 'https://firebasestorage.googleapis.com/v0/b/collegehub-711d5.firebasestorage.app/o/sbi%20account.pdf?alt=media',
      'fileName': 'sbi account.pdf',
      'fileExtension': 'pdf',
      'fileSize': 363345,
      'uploadedBy': 'admin_system',
    },
    {
      'id': '1765374009291',
      'title': 'Engineering Physics Unit 1',
      'description': 'Detailed notes on Quantum Physics and Laser technology.',
      'college': 'Vidya Jyothi Institute of Technology',
      'department': 'CSE (AI-ML)',
      'semester': 'Semester 1',
      'subject': 'Physics',
      'resourceType': 'Notes',
      'year': '2025',
      'fileUrl': 'REPLACE_WITH_ACTUAL_URL_FROM_STORAGE_FOLDER_1765374009291',
      'fileName': 'physics_unit1.pdf',
      'fileExtension': 'pdf',
      'fileSize': 1204500,
      'uploadedBy': 'admin_system',
    },
    {
      'id': '1765389413407',
      'title': 'Discrete Mathematics Question Bank',
      'description': 'Collection of important questions for End-Sem exams.',
      'college': 'Chaitanya Bharathi Institute of Technology',
      'department': 'CSE',
      'semester': 'Semester 3',
      'subject': 'Mathematics',
      'resourceType': 'Question Bank',
      'year': '2023',
      'fileUrl': 'REPLACE_WITH_ACTUAL_URL_FROM_STORAGE_FOLDER_1765389413407',
      'fileName': 'math_qbank.pdf',
      'fileExtension': 'pdf',
      'fileSize': 2405600,
      'uploadedBy': 'admin_system',
    },
    {
      'id': '1765448334514',
      'title': 'Digital Electronics Lab Manual',
      'description': 'Full lab experiments and circuit diagrams for ECE students.',
      'college': 'Vidya Jyothi Institute of Technology',
      'department': 'ECE',
      'semester': 'Semester 4',
      'subject': 'Digital Electronics',
      'resourceType': 'Lab Manual',
      'year': '2025',
      'fileUrl': 'REPLACE_WITH_ACTUAL_URL_FROM_STORAGE_FOLDER_1765448334514',
      'fileName': 'de_lab_manual.pdf',
      'fileExtension': 'pdf',
      'fileSize': 5403200,
      'uploadedBy': 'admin_system',
    },
    {
      'id': '1765456383781',
      'title': 'Python Programming Final Project',
      'description': 'Documentation for Python project on Data Analysis.',
      'college': 'Vasavi College of Engineering',
      'department': 'IT',
      'semester': 'Semester 5',
      'subject': 'Python',
      'resourceType': 'Project',
      'year': '2024',
      'fileUrl': 'REPLACE_WITH_ACTUAL_URL_FROM_STORAGE_FOLDER_1765456383781',
      'fileName': 'python_project.pdf',
      'fileExtension': 'pdf',
      'fileSize': 1100500,
      'uploadedBy': 'admin_system',
    },
    {
      'id': '1765457845529',
      'title': 'Compiler Design Lecture Notes',
      'description': 'Comprehensive notes covering Lexical Analysis to Code Generation.',
      'college': 'Vidya Jyothi Institute of Technology',
      'department': 'CSE',
      'semester': 'Semester 6',
      'subject': 'Compiler Design',
      'resourceType': 'Notes',
      'year': '2024',
      'fileUrl': 'REPLACE_WITH_ACTUAL_URL_FROM_STORAGE_FOLDER_1765457845529',
      'fileName': 'cd_notes.pdf',
      'fileExtension': 'pdf',
      'fileSize': 3200000,
      'uploadedBy': 'admin_system',
    },
    {
      'id': '1765634650533',
      'title': 'Cloud Computing Case Studies',
      'description': 'Analysis of AWS and Azure deployments for enterprise apps.',
      'college': 'JNTUH College of Engineering Hyderabad',
      'department': 'CSE',
      'semester': 'Semester 7',
      'subject': 'Cloud Computing',
      'resourceType': 'Case Study',
      'year': '2025',
      'fileUrl': 'REPLACE_WITH_ACTUAL_URL_FROM_STORAGE_FOLDER_1765634650533',
      'fileName': 'cloud_case_study.pdf',
      'fileExtension': 'pdf',
      'fileSize': 4500000,
      'uploadedBy': 'admin_system',
    },
  ];

  /// ✅ ROBUST SEEDING LOGIC
  /// Directly creates records in the 'resources' collection in Firestore.
  static Future<void> seedResources() async {
    print('🌱 [ResourceSeeder] Starting synchronization...');
    WriteBatch batch = _firestore.batch();
    int count = 0;

    try {
      for (var data in _resourcesData) {
        final docRef = _firestore.collection('resources').doc(data['id']);

        // Convert the map to the specific Firestore structure
        // Using serverTimestamp() for precise backend ordering
        batch.set(docRef, {
          'id': data['id'],
          'title': data['title'],
          'description': data['description'],
          'college': data['college'],
          'department': data['department'],
          'semester': data['semester'],
          'subject': data['subject'],
          'resourceType': data['resourceType'],
          'year': data['year'],
          'fileUrl': data['fileUrl'],
          'fileName': data['fileName'],
          'fileExtension': data['fileExtension'],
          'fileSize': data['fileSize'],
          'uploadedBy': data['uploadedBy'],
          'uploadedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'tags': [data['subject'], data['department'], data['resourceType']],
          'downloadCount': 0,
          'viewCount': 0,
          'rating': 0.0,
          'ratingCount': 0,
          'isFeatured': false,
          'isTrending': false,
          'isActive': true,
        }, SetOptions(merge: true));

        count++;

        // Safety check for Firestore batch limits (Max 500)
        if (count >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          count = 0;
        }
      }

      if (count > 0) await batch.commit();
      print('✅ [ResourceSeeder] Successfully synced ${_resourcesData.length} resources!');
    } catch (e) {
      print('❌ [ResourceSeeder] Sync Failed: $e');
      rethrow;
    }
  }
}