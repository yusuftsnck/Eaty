import 'package:eatyy/models/user_address.dart';
import 'package:eatyy/screens/addresses/address_form_page.dart';
import 'package:eatyy/services/address_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  bool _saving = false;

  Future<void> _useCurrentLocation() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum servisleri kapalı.')),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Konum izni verilmedi.')));
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String addressLine = 'Mevcut Konum';
      String neighborhood = '';
      String district = '';
      String city = '';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          addressLine = [
            place.thoroughfare,
            place.subThoroughfare,
          ].where((p) => p != null && p.trim().isNotEmpty).join(' ');
          neighborhood = place.subLocality ?? '';
          district = place.locality ?? '';
          city = place.administrativeArea ?? '';
          if (addressLine.trim().isEmpty) {
            addressLine = [
              neighborhood,
              district,
              city,
            ].where((p) => p.trim().isNotEmpty).join(' ');
          }
        }
      } catch (_) {}

      final address = UserAddress(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: 'Mevcut Konum',
        addressLine: addressLine,
        neighborhood: neighborhood,
        district: district,
        city: city,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      await AddressService.instance.addOrUpdate(address, select: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openForm({UserAddress? address}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddressFormPage(initial: address)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Adreslerim'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: ValueListenableBuilder<List<UserAddress>>(
          valueListenable: AddressService.instance.addresses,
          builder: (context, list, _) {
            return ValueListenableBuilder<UserAddress?>(
              valueListenable: AddressService.instance.selected,
              builder: (context, selected, __) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    const SizedBox(height: 14),
                    _ActionCard(
                      icon: Icons.my_location,
                      text: 'Mevcut Konumumu Kullan',
                      onTap: _useCurrentLocation,
                    ),
                    const SizedBox(height: 10),
                    _ActionCard(
                      icon: Icons.add_circle_outline,
                      text: 'Yeni Adres Ekle',
                      onTap: () => _openForm(),
                    ),
                    const SizedBox(height: 16),
                    for (final address in list)
                      _AddressCard(
                        address: address,
                        selected: selected?.id == address.id,
                        onSelect: () => AddressService.instance.select(address),
                        onEdit: () => _openForm(address: address),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.deepOrange),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final UserAddress address;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;

  const _AddressCard({
    required this.address,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected ? Colors.deepOrange : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      address.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Düzenle'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (address.regionLine.isNotEmpty)
                Text(
                  address.regionLine,
                  style: const TextStyle(color: Colors.black54),
                ),
              if (address.addressLine.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(address.addressLine),
              ],
              if (address.note != null && address.note!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(address.note!),
              ],
              if (address.phone != null &&
                  address.phone!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(address.phone!),
              ],
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 110,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        address.latitude,
                        address.longitude,
                      ),
                      initialZoom: 15,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.eatyy',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(address.latitude, address.longitude),
                            width: 32,
                            height: 32,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.redAccent,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
