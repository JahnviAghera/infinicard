class BusinessCard {
  final String id;
  final String name;
  final String title;
  final String company;
  final String email;
  final String phone;
  final String website;
  final String linkedIn;
  final String github;
  final int themeColor; // Color value
  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessCard({
    required this.id,
    required this.name,
    required this.title,
    required this.company,
    required this.email,
    required this.phone,
    this.website = '',
    this.linkedIn = '',
    this.github = '',
    this.themeColor = 0xFF1E88E5,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'title': title,
    'company': company,
    'email': email,
    'phone': phone,
    'website': website,
    'linkedIn': linkedIn,
    'github': github,
    'themeColor': themeColor,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory BusinessCard.fromJson(Map<String, dynamic> json) {
    // Parse color from hex string (e.g., "#1E88E5") to int
    int parseColor(dynamic colorValue) {
      if (colorValue == null) return 0xFF1E88E5;
      if (colorValue is int) return colorValue;
      if (colorValue is String) {
        String hex = colorValue.replaceAll('#', '');
        if (hex.length == 6) {
          hex = 'FF$hex'; // Add alpha channel
        }
        return int.tryParse(hex, radix: 16) ?? 0xFF1E88E5;
      }
      return 0xFF1E88E5;
    }

    return BusinessCard(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['full_name']?.toString() ?? '',
      title: json['title']?.toString() ?? json['job_title']?.toString() ?? '',
      company:
          json['company']?.toString() ?? json['company_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      linkedIn: json['linkedIn']?.toString() ?? '',
      github: json['github']?.toString() ?? '',
      themeColor: parseColor(json['color'] ?? json['themeColor']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null
                ? DateTime.parse(json['created_at'])
                : DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : (json['updated_at'] != null
                ? DateTime.parse(json['updated_at'])
                : DateTime.now()),
    );
  }

  BusinessCard copyWith({
    String? id,
    String? name,
    String? title,
    String? company,
    String? email,
    String? phone,
    String? website,
    String? linkedIn,
    String? github,
    int? themeColor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessCard(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      company: company ?? this.company,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      linkedIn: linkedIn ?? this.linkedIn,
      github: github ?? this.github,
      themeColor: themeColor ?? this.themeColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
