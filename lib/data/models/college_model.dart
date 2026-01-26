import 'package:cloud_firestore/cloud_firestore.dart';

class CollegeModel {
  final String id;
  final String name;
  final String? location;
  final String? address;
  final String? website;
  final String? phone;
  final String? email;
  final List<String> departments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  CollegeModel({
    required this.id,
    required this.name,
    this.location,
    this.address,
    this.website,
    this.phone,
    this.email,
    this.departments = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'address': address,
      'website': website,
      'phone': phone,
      'email': email,
      'departments': departments,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  factory CollegeModel.fromMap(Map<String, dynamic> map) {
    return CollegeModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      location: map['location'],
      address: map['address'],
      website: map['website'],
      phone: map['phone'],
      email: map['email'],
      departments: List<String>.from(map['departments'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  factory CollegeModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CollegeModel.fromMap(data);
  }

  CollegeModel copyWith({
    String? id,
    String? name,
    String? location,
    String? address,
    String? website,
    String? phone,
    String? email,
    List<String>? departments,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return CollegeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      address: address ?? this.address,
      website: website ?? this.website,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      departments: departments ?? this.departments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}