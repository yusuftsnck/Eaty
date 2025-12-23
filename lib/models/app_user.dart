class AppUser {
  final String email;
  final String? displayName;
  final String? photoUrl;

  const AppUser({
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      email: json['email']?.toString() ?? '',
      displayName: json['displayName']?.toString(),
      photoUrl: json['photoUrl']?.toString(),
    );
  }
}
