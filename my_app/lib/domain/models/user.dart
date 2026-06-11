class User {
  final String id;
  final String phone;
  final String fullName;
  final String? avatarUrl;
  final String role; // student, teacher, admin
  final String? gradeLevel; // for students
  final String? subjectId; // for teachers
  final bool phoneVerified;
  final bool mustChangePassword;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.phone,
    required this.fullName,
    this.avatarUrl,
    required this.role,
    this.gradeLevel,
    this.subjectId,
    required this.phoneVerified,
    required this.mustChangePassword,
    required this.createdAt,
    required this.updatedAt,
  });

  // From JSON (Database → Dart)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      phone: json['phone'] as String,
      fullName: json['full_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      role: (json['role'] as String).toLowerCase().trim(),
      gradeLevel: json['grade_level'] as String?,
      subjectId: json['subject_id'] as String?,
      phoneVerified: (json['phone_verified'] as bool?) ?? false,
      mustChangePassword: (json['must_change_password'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // To JSON (Dart → Database)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'role': role,
      'grade_level': gradeLevel,
      'subject_id': subjectId,
      'phone_verified': phoneVerified,
      'must_change_password': mustChangePassword,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper: Is Student?
  bool get isStudent => role == 'student';

  // Helper: Is Teacher?
  bool get isTeacher => role == 'teacher';

  // Helper: Is Admin?
  bool get isAdmin => role == 'admin';

  // Copy with (for updating)
  User copyWith({
    String? id,
    String? phone,
    String? fullName,
    String? avatarUrl,
    String? role,
    String? gradeLevel,
    String? subjectId,
    bool? phoneVerified,
    bool? mustChangePassword,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      subjectId: subjectId ?? this.subjectId,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
