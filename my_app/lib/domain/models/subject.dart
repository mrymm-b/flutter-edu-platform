class Subject {
  final String id;
  final String name;
  final String? nameAr;
  final String? iconUrl;
  final bool isActive;

  Subject({
    required this.id,
    required this.name,
    this.nameAr,
    this.iconUrl,
    required this.isActive,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String,
      name: json['name'] as String,
      nameAr: json['name_ar'] as String?,
      iconUrl: json['icon_url'] as String?,
      isActive: json['is_active'] as bool,
    );
  }

  String get displayName => nameAr ?? name;
}
