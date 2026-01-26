import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════
/// PRODUCTION-GRADE USER MODEL - FULLY DYNAMIC & REAL-TIME
/// ═══════════════════════════════════════════════════════════════
/// Features:
/// ✅ Complete real-time Firestore synchronization
/// ✅ All fields from your Firestore database structure
/// ✅ Robust error handling with fallbacks
/// ✅ Deterministic date parsing for stability
/// ✅ Role-based permission logic
/// ✅ FCM token support for push notifications
/// ✅ Dynamic profile data (bio, interests, skills, hobbies)
/// ✅ Academic information (college, department, semester, batch)
/// ✅ Contact information (address, city, state, country, pincode)
/// ✅ Personal information (DOB, gender, blood group, nationality)
/// ✅ Statistics (resources uploaded, downloads, study streak)
/// ✅ FIXED: Handles missing documents gracefully
/// ✅ FIXED: Enhanced debug logging for troubleshooting
/// ═══════════════════════════════════════════════════════════════

class UserModel {
  // ═══════════════════════════════════════════════════════════════
  // CORE IDENTITY FIELDS
  // ═══════════════════════════════════════════════════════════════
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? phoneNumber; // Alternative field name
  final String? photoUrl;
  final String role; // 'admin' or 'student'

  // ═══════════════════════════════════════════════════════════════
  // ACADEMIC INFORMATION
  // ═══════════════════════════════════════════════════════════════
  final String? college;
  final String? department;
  final String? semester;
  final String? batchYear;
  final String? batch; // Alternative field name
  final String? className;
  final String? section;
  final String? rollNumber;
  final String? rollNo; // Alternative field name

  // ═══════════════════════════════════════════════════════════════
  // PROFILE & BIO
  // ═══════════════════════════════════════════════════════════════
  final String? bio;
  final String? about; // Alternative field name

  // ═══════════════════════════════════════════════════════════════
  // CONTACT INFORMATION
  // ═══════════════════════════════════════════════════════════════
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;
  final String? zipCode; // Alternative field name

  // ═══════════════════════════════════════════════════════════════
  // PERSONAL INFORMATION
  // ═══════════════════════════════════════════════════════════════
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? nationality;

  // ═══════════════════════════════════════════════════════════════
  // INTERESTS, SKILLS & HOBBIES
  // ═══════════════════════════════════════════════════════════════
  final List<String>? interests;
  final List<String>? skills;
  final List<String>? hobbies;

  // ═══════════════════════════════════════════════════════════════
  // STATISTICS & ANALYTICS
  // ═══════════════════════════════════════════════════════════════
  final int resourcesUploaded;
  final int totalDownloads;
  final int studyStreak;
  final int totalStudyTime; // in minutes
  final int pointsEarned;

  // ═══════════════════════════════════════════════════════════════
  // SYSTEM FIELDS
  // ═══════════════════════════════════════════════════════════════
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActive;
  final bool isActive;
  final bool emailVerified;
  final bool isOnline;

  // ═══════════════════════════════════════════════════════════════
  // PREFERENCES & SETTINGS
  // ═══════════════════════════════════════════════════════════════
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? settings;
  final List<String>? blockedUsers;
  final List<String>? mutedConversations;

  // ═══════════════════════════════════════════════════════════════
  // SOCIAL & CONNECTIONS
  // ═══════════════════════════════════════════════════════════════
  final List<String>? friends;
  final List<String>? followers;
  final List<String>? following;
  final int friendCount;

  // ═══════════════════════════════════════════════════════════════
  // BADGES & ACHIEVEMENTS
  // ═══════════════════════════════════════════════════════════════
  final List<String>? badges;
  final List<String>? achievements;
  final String? rank;
  final int level;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.phoneNumber,
    this.photoUrl,
    required this.role,
    this.college,
    this.department,
    this.semester,
    this.batchYear,
    this.batch,
    this.className,
    this.section,
    this.rollNumber,
    this.rollNo,
    this.bio,
    this.about,
    this.address,
    this.city,
    this.state,
    this.country,
    this.pincode,
    this.zipCode,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.nationality,
    this.interests,
    this.skills,
    this.hobbies,
    this.resourcesUploaded = 0,
    this.totalDownloads = 0,
    this.studyStreak = 0,
    this.totalStudyTime = 0,
    this.pointsEarned = 0,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
    this.lastActive,
    this.isActive = true,
    this.emailVerified = false,
    this.isOnline = false,
    this.preferences,
    this.settings,
    this.blockedUsers,
    this.mutedConversations,
    this.friends,
    this.followers,
    this.following,
    this.friendCount = 0,
    this.badges,
    this.achievements,
    this.rank,
    this.level = 1,
  });

  // ═══════════════════════════════════════════════════════════════
  // ✅ FIRESTORE CONVERSION - TO MAP
  // ═══════════════════════════════════════════════════════════════

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone ?? phoneNumber,
      'phoneNumber': phoneNumber ?? phone,
      'photoUrl': photoUrl,
      'role': role,
      'college': college,
      'department': department,
      'semester': semester,
      'batchYear': batchYear ?? batch,
      'batch': batch ?? batchYear,
      'className': className,
      'section': section,
      'rollNumber': rollNumber ?? rollNo,
      'rollNo': rollNo ?? rollNumber,
      'bio': bio ?? about,
      'about': about ?? bio,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode ?? zipCode,
      'zipCode': zipCode ?? pincode,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'nationality': nationality,
      'interests': interests,
      'skills': skills,
      'hobbies': hobbies,
      'resourcesUploaded': resourcesUploaded,
      'totalDownloads': totalDownloads,
      'studyStreak': studyStreak,
      'totalStudyTime': totalStudyTime,
      'pointsEarned': pointsEarned,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'isActive': isActive,
      'emailVerified': emailVerified,
      'isOnline': isOnline,
      'preferences': preferences,
      'settings': settings,
      'blockedUsers': blockedUsers,
      'mutedConversations': mutedConversations,
      'friends': friends,
      'followers': followers,
      'following': following,
      'friendCount': friendCount,
      'badges': badges,
      'achievements': achievements,
      'rank': rank,
      'level': level,
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ FIRESTORE CONVERSION - FROM MAP (FULLY DYNAMIC)
  // ═══════════════════════════════════════════════════════════════

  factory UserModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    try {
      // Use provided documentId or fallback to map['id']
      final userId = documentId ?? map['id']?.toString() ?? '';

      if (userId.isEmpty) {
        debugPrint('⚠️ USER MODEL WARNING: Missing user ID in document');
      }

      // Validate required fields
      final userName = map['name']?.toString();
      final userEmail = map['email']?.toString();

      if (userName == null || userName.isEmpty) {
        debugPrint('⚠️ USER MODEL WARNING: Missing name for user $userId');
      }

      if (userEmail == null || userEmail.isEmpty) {
        debugPrint('⚠️ USER MODEL WARNING: Missing email for user $userId');
      }

      return UserModel(
        id: userId,
        name: userName ?? 'Unknown User',
        email: userEmail ?? 'no-email@example.com',
        phone: map['phone']?.toString(),
        phoneNumber: map['phoneNumber']?.toString(),
        photoUrl: map['photoUrl']?.toString(),
        role: map['role']?.toString() ?? 'student',

        // Academic Information
        college: map['college']?.toString(),
        department: map['department']?.toString(),
        semester: map['semester']?.toString(),
        batchYear: map['batchYear']?.toString(),
        batch: map['batch']?.toString(),
        className: map['className']?.toString() ?? map['class']?.toString(),
        section: map['section']?.toString(),
        rollNumber: map['rollNumber']?.toString(),
        rollNo: map['rollNo']?.toString(),

        // Profile & Bio
        bio: map['bio']?.toString(),
        about: map['about']?.toString(),

        // Contact Information
        address: map['address']?.toString(),
        city: map['city']?.toString(),
        state: map['state']?.toString(),
        country: map['country']?.toString(),
        pincode: map['pincode']?.toString(),
        zipCode: map['zipCode']?.toString(),

        // Personal Information
        dateOfBirth: _parseDateTime(map['dateOfBirth']),
        gender: map['gender']?.toString(),
        bloodGroup: map['bloodGroup']?.toString(),
        nationality: map['nationality']?.toString(),

        // Interests, Skills & Hobbies
        interests: _parseStringList(map['interests']),
        skills: _parseStringList(map['skills']),
        hobbies: _parseStringList(map['hobbies']),

        // Statistics
        resourcesUploaded: _parseInt(map['resourcesUploaded']),
        totalDownloads: _parseInt(map['totalDownloads']),
        studyStreak: _parseInt(map['studyStreak']),
        totalStudyTime: _parseInt(map['totalStudyTime']),
        pointsEarned: _parseInt(map['pointsEarned']),

        // System Fields
        fcmToken: map['fcmToken']?.toString(),
        createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
        lastActive: _parseDateTime(map['lastActive']),
        isActive: map['isActive'] ?? true,
        emailVerified: map['emailVerified'] ?? false,
        isOnline: map['isOnline'] ?? false,

        // Preferences & Settings
        preferences: map['preferences'] != null
            ? Map<String, dynamic>.from(map['preferences'])
            : null,
        settings: map['settings'] != null
            ? Map<String, dynamic>.from(map['settings'])
            : null,
        blockedUsers: _parseStringList(map['blockedUsers']),
        mutedConversations: _parseStringList(map['mutedConversations']),

        // Social
        friends: _parseStringList(map['friends']),
        followers: _parseStringList(map['followers']),
        following: _parseStringList(map['following']),
        friendCount: _parseInt(map['friendCount']),

        // Achievements
        badges: _parseStringList(map['badges']),
        achievements: _parseStringList(map['achievements']),
        rank: map['rank']?.toString(),
        level: _parseInt(map['level']) > 0 ? _parseInt(map['level']) : 1,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ USER MODEL ERROR: Failed to parse user data');
      debugPrint('   Document ID: ${documentId ?? map['id']}');
      debugPrint('   Error: $e');
      debugPrint('   Stack trace: $stackTrace');
      debugPrint('   Available fields: ${map.keys.toList()}');

      // Return a minimal valid user model instead of throwing
      return UserModel(
        id: documentId ?? map['id']?.toString() ?? 'unknown',
        name: map['name']?.toString() ?? 'Unknown User',
        email: map['email']?.toString() ?? 'no-email@example.com',
        role: 'student',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ FIRESTORE CONVERSION - FROM DOCUMENT (PRIMARY ENTRY POINT)
  // ═══════════════════════════════════════════════════════════════

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    if (!doc.exists) {
      debugPrint('❌ USER MODEL ERROR: Document does not exist: ${doc.id}');

      // ✅ CRITICAL FIX: Return a minimal valid user instead of throwing
      return UserModel(
        id: doc.id,
        name: 'User Not Found',
        email: 'unavailable@example.com',
        role: 'student',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: false,
      );
    }

    try {
      final data = doc.data() as Map<String, dynamic>?;

      if (data == null) {
        debugPrint('⚠️ USER MODEL WARNING: Document ${doc.id} has null data');

        return UserModel(
          id: doc.id,
          name: 'User Data Unavailable',
          email: 'unavailable@example.com',
          role: 'student',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: false,
        );
      }

      debugPrint('✅ USER MODEL: Successfully loaded user ${doc.id}');

      // Ensure the ID from the document is always used
      return UserModel.fromMap({
        ...data,
        'id': doc.id, // Override with document ID
      }, documentId: doc.id);

    } catch (e, stackTrace) {
      debugPrint('❌ USER MODEL ERROR: Failed to parse document ${doc.id}');
      debugPrint('   Error: $e');
      debugPrint('   Stack trace: $stackTrace');

      // Return minimal valid user model
      return UserModel(
        id: doc.id,
        name: 'Error Loading User',
        email: 'error@example.com',
        role: 'student',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: false,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ HELPER PARSING METHODS - ROBUST ERROR HANDLING
  // ═══════════════════════════════════════════════════════════════

  /// Safely parses DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    try {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    } catch (e) {
      debugPrint('⚠️ USER MODEL: Failed to parse DateTime: $e');
    }

    return null;
  }

  /// Safely parses integer values
  static int _parseInt(dynamic value) {
    if (value == null) return 0;

    try {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
    } catch (e) {
      debugPrint('⚠️ USER MODEL: Failed to parse int: $e');
    }

    return 0;
  }

  /// Safely parses string lists from various formats
  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;

    try {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is String) {
        // Handle comma-separated strings
        if (value.isEmpty) return null;
        return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    } catch (e) {
      debugPrint('⚠️ USER MODEL: Failed to parse string list: $e');
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ COPY WITH METHOD - FOR UPDATES
  // ═══════════════════════════════════════════════════════════════

  UserModel copyWith({
    String? name,
    String? phone,
    String? phoneNumber,
    String? photoUrl,
    String? college,
    String? department,
    String? semester,
    String? batchYear,
    String? className,
    String? section,
    String? rollNumber,
    String? bio,
    String? address,
    String? city,
    String? state,
    String? country,
    String? pincode,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? nationality,
    List<String>? interests,
    List<String>? skills,
    List<String>? hobbies,
    int? resourcesUploaded,
    int? totalDownloads,
    int? studyStreak,
    int? totalStudyTime,
    int? pointsEarned,
    String? fcmToken,
    DateTime? updatedAt,
    DateTime? lastActive,
    bool? emailVerified,
    bool? isOnline,
    bool? isActive,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? settings,
    List<String>? blockedUsers,
    List<String>? mutedConversations,
    List<String>? friends,
    List<String>? followers,
    List<String>? following,
    int? friendCount,
    List<String>? badges,
    List<String>? achievements,
    String? rank,
    int? level,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role,
      college: college ?? this.college,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      batchYear: batchYear ?? this.batchYear,
      batch: batchYear ?? this.batch,
      className: className ?? this.className,
      section: section ?? this.section,
      rollNumber: rollNumber ?? this.rollNumber,
      rollNo: rollNumber ?? this.rollNo,
      bio: bio ?? this.bio,
      about: bio ?? this.about,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      pincode: pincode ?? this.pincode,
      zipCode: pincode ?? this.zipCode,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      nationality: nationality ?? this.nationality,
      interests: interests ?? this.interests,
      skills: skills ?? this.skills,
      hobbies: hobbies ?? this.hobbies,
      resourcesUploaded: resourcesUploaded ?? this.resourcesUploaded,
      totalDownloads: totalDownloads ?? this.totalDownloads,
      studyStreak: studyStreak ?? this.studyStreak,
      totalStudyTime: totalStudyTime ?? this.totalStudyTime,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActive: lastActive ?? this.lastActive,
      isActive: isActive ?? this.isActive,
      emailVerified: emailVerified ?? this.emailVerified,
      isOnline: isOnline ?? this.isOnline,
      preferences: preferences ?? this.preferences,
      settings: settings ?? this.settings,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      mutedConversations: mutedConversations ?? this.mutedConversations,
      friends: friends ?? this.friends,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      friendCount: friendCount ?? this.friendCount,
      badges: badges ?? this.badges,
      achievements: achievements ?? this.achievements,
      rank: rank ?? this.rank,
      level: level ?? this.level,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ HELPER GETTERS - COMPUTED PROPERTIES
  // ═══════════════════════════════════════════════════════════════

  /// Check if user is admin
  bool get isAdmin => role.toLowerCase() == 'admin';

  /// Check if user is student
  bool get isStudent => role.toLowerCase() == 'student';

  /// Check if user has profile photo
  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  /// Get display phone number (prioritizes 'phone' field)
  String? get displayPhone => phone ?? phoneNumber;

  /// Get display batch year
  String? get displayBatchYear => batchYear ?? batch;

  /// Get display roll number
  String? get displayRollNumber => rollNumber ?? rollNo;

  /// Get display bio/about
  String? get displayBio => bio ?? about;

  /// Get display pincode
  String? get displayPincode => pincode ?? zipCode;

  /// Check if profile is complete
  bool get isProfileComplete {
    return name.isNotEmpty &&
        email.isNotEmpty &&
        photoUrl != null &&
        college != null &&
        department != null;
  }

  /// Get completion percentage
  int get profileCompletionPercentage {
    int completed = 0;
    int total = 10;

    if (name.isNotEmpty) completed++;
    if (email.isNotEmpty) completed++;
    if (hasPhoto) completed++;
    if (phone != null) completed++;
    if (college != null) completed++;
    if (department != null) completed++;
    if (semester != null) completed++;
    if (batchYear != null) completed++;
    if (bio != null) completed++;
    if (gender != null) completed++;

    return ((completed / total) * 100).round();
  }

  /// Get full address
  String? get fullAddress {
    final parts = <String>[];
    if (address != null) parts.add(address!);
    if (city != null) parts.add(city!);
    if (state != null) parts.add(state!);
    if (country != null) parts.add(country!);
    if (displayPincode != null) parts.add(displayPincode!);

    return parts.isEmpty ? null : parts.join(', ');
  }

  /// Get academic info string
  String? get academicInfo {
    final parts = <String>[];
    if (college != null) parts.add(college!);
    if (department != null) parts.add(department!);
    if (semester != null) parts.add('Sem $semester');

    return parts.isEmpty ? null : parts.join(' • ');
  }

  /// Check if user data is valid (not error/fallback)
  bool get isValidUser {
    return email != 'no-email@example.com' &&
        email != 'unavailable@example.com' &&
        email != 'error@example.com' &&
        name != 'Unknown User' &&
        name != 'User Not Found' &&
        name != 'User Data Unavailable' &&
        name != 'Error Loading User';
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ JSON SERIALIZATION (FOR API CALLS)
  // ═══════════════════════════════════════════════════════════════

  Map<String, dynamic> toJson() => toMap();

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel.fromMap(json);

  // ═══════════════════════════════════════════════════════════════
  // ✅ DEBUG & LOGGING
  // ═══════════════════════════════════════════════════════════════

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, role: $role, college: $college, isValid: $isValidUser)';
  }

  /// Get detailed debug info
  String toDebugString() {
    return '''
UserModel {
  ID: $id
  Name: $name
  Email: $email
  Phone: $displayPhone
  Role: $role
  College: $college
  Department: $department
  Semester: $semester
  Batch: $displayBatchYear
  Photo: ${hasPhoto ? 'Yes' : 'No'}
  Email Verified: $emailVerified
  Online: $isOnline
  Last Active: $lastActive
  Profile Complete: $isProfileComplete ($profileCompletionPercentage%)
  Valid User: $isValidUser
  Active: $isActive
}
''';
  }
}