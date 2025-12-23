class TrLocationData {
  final List<TrCity> cities;
  TrLocationData({required this.cities});

  factory TrLocationData.fromJson(Map<String, dynamic> json) {
    final list = (json['cities'] as List<dynamic>)
        .map((e) => TrCity.fromJson(e as Map<String, dynamic>))
        .toList();
    return TrLocationData(cities: list);
  }

  factory TrLocationData.fromIlIlceJson(dynamic json) {
    final rawList = json is List
        ? json
        : (json is Map<String, dynamic>
              ? json['data'] as List<dynamic>?
              : null);
    if (rawList == null) {
      return TrLocationData(cities: const []);
    }

    final cities = <TrCity>[];
    for (final entry in rawList) {
      if (entry is! Map) continue;
      final name = entry['il'] ?? entry['name'];
      if (name == null) continue;
      final districtsRaw = entry['ilceleri'] ?? entry['districts'];
      final districts = <TrDistrict>[];
      if (districtsRaw is List) {
        for (final item in districtsRaw) {
          if (item == null) continue;
          final districtName = item is Map ? item['name'] : item;
          if (districtName == null) continue;
          districts.add(
            TrDistrict(name: districtName.toString(), neighborhoods: const []),
          );
        }
      }
      cities.add(TrCity(name: name.toString(), districts: districts));
    }

    return TrLocationData(cities: cities);
  }
}

class TrCity {
  final String name;
  final List<TrDistrict> districts;
  TrCity({required this.name, required this.districts});

  factory TrCity.fromJson(Map<String, dynamic> json) {
    return TrCity(
      name: json['name'] as String,
      districts: (json['districts'] as List<dynamic>)
          .map((e) => TrDistrict.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TrDistrict {
  final String name;
  final List<String> neighborhoods;
  TrDistrict({required this.name, required this.neighborhoods});

  factory TrDistrict.fromJson(Map<String, dynamic> json) {
    return TrDistrict(
      name: json['name'] as String,
      neighborhoods: (json['neighborhoods'] as List<dynamic>).cast<String>(),
    );
  }
}
