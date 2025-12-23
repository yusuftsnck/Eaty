import 'package:eatyy/models/user_address.dart';
import 'package:eatyy/screens/addresses/map_picker_page.dart';
import 'package:eatyy/services/address_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class AddressFormPage extends StatefulWidget {
  final UserAddress? initial;
  const AddressFormPage({super.key, this.initial});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _labelCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _neighborhoodCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  LatLng? _selectedLocation;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _labelCtrl.text = initial.label;
      _addressCtrl.text = initial.addressLine;
      _neighborhoodCtrl.text = initial.neighborhood;
      _districtCtrl.text = initial.district;
      _cityCtrl.text = initial.city;
      _noteCtrl.text = initial.note ?? '';
      _phoneCtrl.text = initial.phone ?? '';
      _selectedLocation = LatLng(initial.latitude, initial.longitude);
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _addressCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _districtCtrl.dispose();
    _cityCtrl.dispose();
    _noteCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _applyPlacemark(Placemark place) {
    if (_addressCtrl.text.trim().isEmpty) {
      _addressCtrl.text = [
        place.thoroughfare,
        place.subThoroughfare,
      ].where((p) => p != null && p.trim().isNotEmpty).join(' ');
    }
    if (_neighborhoodCtrl.text.trim().isEmpty) {
      _neighborhoodCtrl.text = place.subLocality ?? '';
    }
    if (_districtCtrl.text.trim().isEmpty) {
      _districtCtrl.text = place.locality ?? '';
    }
    if (_cityCtrl.text.trim().isEmpty) {
      _cityCtrl.text = place.administrativeArea ?? '';
    }
  }

  Future<void> _updateLocation(LatLng location) async {
    setState(() => _selectedLocation = location);
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty) {
        _applyPlacemark(placemarks.first);
      }
    } catch (_) {}
  }

  Future<void> _pickLocationOnMap() async {
    final picked = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MapPickerPage(title: 'Konum Seç', initial: _selectedLocation),
      ),
    );
    if (picked != null) {
      await _updateLocation(picked);
    }
  }

  Future<void> _useCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Konum servisleri kapalı.')));
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
    await _updateLocation(LatLng(position.latitude, position.longitude));
  }

  Future<void> _save() async {
    if (_saving) return;
    final label = _labelCtrl.text.trim();
    final addressLine = _addressCtrl.text.trim();
    final neighborhood = _neighborhoodCtrl.text.trim();
    final district = _districtCtrl.text.trim();
    final city = _cityCtrl.text.trim();

    if (label.isEmpty || addressLine.isEmpty || city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen gerekli alanları doldurun.')),
      );
      return;
    }

    final location = _selectedLocation;
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen haritadan konum seçin.')),
      );
      return;
    }

    final id =
        widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final address = UserAddress(
      id: id,
      label: label,
      addressLine: addressLine,
      neighborhood: neighborhood,
      district: district,
      city: city,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      latitude: location.latitude,
      longitude: location.longitude,
    );

    setState(() => _saving = true);
    await AddressService.instance.addOrUpdate(address, select: true);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
  }

  Widget _buildMapPreview() {
    final location = _selectedLocation;
    final Widget content;
    if (location == null) {
      content = Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.map_outlined, color: Colors.black38, size: 40),
            SizedBox(height: 6),
            Text(
              'Konum seçilmedi',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      );
    } else {
      content = FlutterMap(
        options: MapOptions(
          initialCenter: location,
          initialZoom: 15,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.eatyy',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: location,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.redAccent,
                  size: 36,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return SizedBox(
      height: 160,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned.fill(child: IgnorePointer(child: content)),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: _pickLocationOnMap),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Yeni Adres' : 'Adresi Düzenle'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _Field(label: 'Adres Başlığı', controller: _labelCtrl),
            _Field(label: 'Adres', controller: _addressCtrl),
            _Field(label: 'Mahalle', controller: _neighborhoodCtrl),
            _Field(label: 'İlçe', controller: _districtCtrl),
            _Field(label: 'İl', controller: _cityCtrl),
            _Field(label: 'Adres Notu', controller: _noteCtrl),
            _Field(label: 'Telefon', controller: _phoneCtrl),
            const SizedBox(height: 8),
            _buildMapPreview(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickLocationOnMap,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Haritadan Seç'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _useCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Mevcut Konumu Kullan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const StadiumBorder(),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kaydet'),
              ),
            ),
            if (widget.initial != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await AddressService.instance.remove(widget.initial!.id);
                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                  child: const Text('Adresi Sil'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _Field({
    required this.label,
    required this.controller,
    // ignore: unused_element_parameter
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
