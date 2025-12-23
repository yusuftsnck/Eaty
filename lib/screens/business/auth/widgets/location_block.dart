import 'package:flutter/material.dart';
import 'package:eatyy/screens/business/auth/models/tr_location_data.dart';
import 'package:eatyy/screens/business/auth/widgets/dropdown_field.dart';
import 'package:eatyy/screens/business/auth/widgets/labeled_field.dart';

class LocationBlock extends StatelessWidget {
  final TrLocationData? loc;
  final String? city;
  final String? district;
  final TextEditingController neighborhoodController;
  final ValueChanged<String?> onCityChanged;
  final ValueChanged<String?> onDistrictChanged;

  const LocationBlock({
    super.key,
    required this.loc,
    required this.city,
    required this.district,
    required this.neighborhoodController,
    required this.onCityChanged,
    required this.onDistrictChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cities = loc?.cities.map((c) => c.name).toList() ?? const <String>[];
    final selectedCity = loc?.cities.where((c) => c.name == city).toList();
    final districts = (selectedCity?.isNotEmpty == true)
        ? selectedCity!.first.districts.map((d) => d.name).toList()
        : const <String>[];

    return Column(
      children: [
        DropdownField(
          label: 'İl',
          value: city,
          hint: (loc == null) ? 'Yükleniyor...' : 'İl seçin',
          items: cities,
          onChanged: onCityChanged,
          validator: (v) => (v == null || v.isEmpty) ? 'İl seçin' : null,
        ),
        DropdownField(
          label: 'İlçe',
          value: district,
          hint: 'İlçe seçin',
          items: districts,
          onChanged: onDistrictChanged,
          validator: (v) => (v == null || v.isEmpty) ? 'İlçe seçin' : null,
        ),
        LabeledField(
          label: 'Mahalle',
          hint: 'Mahalle adı',
          controller: neighborhoodController,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Mahalle gerekli' : null,
        ),
      ],
    );
  }
}
