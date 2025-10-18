class Contact {
  final String id;
  final String name;
  final String title;
  final String company;
  final String email;
  final String phone;
  final String website;
  final String linkedIn;
  final String github;
  final String? avatarUrl;
  final String notes;
  final String address;
  final bool isFavorite;
  final DateTime? reminderDate;
  final List<String> tags;
  final DateTime createdAt;

  Contact({
    required this.id,
    required this.name,
    this.title = '',
    this.company = '',
    required this.email,
    required this.phone,
    this.website = '',
    this.linkedIn = '',
    this.github = '',
    this.avatarUrl,
    this.notes = '',
    this.address = '',
    this.isFavorite = false,
    this.reminderDate,
    this.tags = const [],
    required this.createdAt,
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
    'avatarUrl': avatarUrl,
    'notes': notes,
    'address': address,
    'isFavorite': isFavorite,
    'reminderDate': reminderDate?.toIso8601String(),
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    id: json['id'],
    name: json['name'],
    title: json['title'] ?? '',
    company: json['company'] ?? '',
    email: json['email'],
    phone: json['phone'],
    website: json['website'] ?? '',
    linkedIn: json['linkedIn'] ?? '',
    github: json['github'] ?? '',
    avatarUrl: json['avatarUrl'],
    notes: json['notes'] ?? '',
    address: json['address'] ?? '',
    isFavorite: json['isFavorite'] ?? false,
    reminderDate: json['reminderDate'] != null
        ? DateTime.parse(json['reminderDate'])
        : null,
    tags: List<String>.from(json['tags'] ?? []),
    createdAt: DateTime.parse(json['createdAt']),
  );

  Contact copyWith({
    String? id,
    String? name,
    String? title,
    String? company,
    String? email,
    String? phone,
    String? website,
    String? linkedIn,
    String? github,
    String? avatarUrl,
    String? notes,
    String? address,
    bool? isFavorite,
    DateTime? reminderDate,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      company: company ?? this.company,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      linkedIn: linkedIn ?? this.linkedIn,
      github: github ?? this.github,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      notes: notes ?? this.notes,
      address: address ?? this.address,
      isFavorite: isFavorite ?? this.isFavorite,
      reminderDate: reminderDate ?? this.reminderDate,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
