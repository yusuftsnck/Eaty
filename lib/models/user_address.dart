class UserAddress {
  final String id;
  final String label;
  final String addressLine;
  final String neighborhood;
  final String district;
  final String city;
  final String? note;
  final String? phone;
  final double latitude;
  final double longitude;

  const UserAddress({
    required this.id,
    required this.label,
    required this.addressLine,
    required this.neighborhood,
    required this.district,
    required this.city,
    required this.latitude,
    required this.longitude,
    this.note,
    this.phone,
  });

  String get regionLine => [
        neighborhood,
        district,
        city,
      ].where((part) => part.trim().isNotEmpty).join(' / ');

  String get headerTitle =>
      addressLine.trim().isNotEmpty ? addressLine.trim() : label.trim();

  String get headerSubtitle => [
        district,
        city,
      ].where((part) => part.trim().isNotEmpty).join(' ');

  String get fullAddress => [
        addressLine,
        regionLine,
      ].where((part) => part.trim().isNotEmpty).join(', ');

  UserAddress copyWith({
    String? id,
    String? label,
    String? addressLine,
    String? neighborhood,
    String? district,
    String? city,
    String? note,
    String? phone,
    double? latitude,
    double? longitude,
  }) {
    return UserAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      addressLine: addressLine ?? this.addressLine,
      neighborhood: neighborhood ?? this.neighborhood,
      district: district ?? this.district,
      city: city ?? this.city,
      note: note ?? this.note,
      phone: phone ?? this.phone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'addressLine': addressLine,
      'neighborhood': neighborhood,
      'district': district,
      'city': city,
      'note': note,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      addressLine: json['addressLine']?.toString() ?? '',
      neighborhood: json['neighborhood']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      note: json['note']?.toString(),
      phone: json['phone']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}
