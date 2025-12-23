class BusinessUser {
  final int? id;
  final String email;
  final String? name;
  final String? photoUrl;
  final String? category;
  final bool isGoogle;

  const BusinessUser({
    required this.email,
    required this.isGoogle,
    this.id,
    this.name,
    this.photoUrl,
    this.category,
  });

  factory BusinessUser.fromProfile(
    Map<String, dynamic> json, {
    required bool isGoogle,
    String? fallbackName,
    String? fallbackPhotoUrl,
  }) {
    final name =
        json['name'] ??
        json['restaurant_name'] ??
        json['company_name'] ??
        fallbackName;
    final photoUrl = json['photo_url'] ?? fallbackPhotoUrl;
    return BusinessUser(
      id: json['id'] as int?,
      email: (json['email'] ?? '').toString(),
      name: name?.toString(),
      photoUrl: photoUrl?.toString(),
      category: json['category']?.toString(),
      isGoogle: isGoogle,
    );
  }

  factory BusinessUser.fromJson(Map<String, dynamic> json) {
    return BusinessUser(
      id: json['id'] as int?,
      email: (json['email'] ?? '').toString(),
      name: json['name']?.toString(),
      photoUrl: json['photoUrl']?.toString(),
      category: json['category']?.toString(),
      isGoogle: json['isGoogle'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'category': category,
      'isGoogle': isGoogle,
    };
  }
}
