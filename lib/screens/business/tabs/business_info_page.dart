import 'dart:convert';

import 'package:eatyy/models/business_user.dart';
import 'package:eatyy/screens/addresses/map_picker_page.dart';
import 'package:eatyy/services/api_service.dart';
import 'package:eatyy/widgets/app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

class BusinessInfoPage extends StatefulWidget {
  final BusinessUser user;
  const BusinessInfoPage({super.key, required this.user});

  @override
  State<BusinessInfoPage> createState() => _BusinessInfoPageState();
}

class _BusinessInfoPageState extends State<BusinessInfoPage> {
  final _api = ApiService();
  late Future<Map<String, dynamic>?> _profileFuture;
  bool _saving = false;
  final _minOrderController = TextEditingController();
  final _deliveryTimeController = TextEditingController();
  final _deliveryRadiusController = TextEditingController();
  final _picker = ImagePicker();
  String? _photoValue;
  LatLng? _selectedLocation;

  static const List<_DayTemplate> _dayTemplates = [
    _DayTemplate('mon', 'Pazartesi'),
    _DayTemplate('tue', 'Salı'),
    _DayTemplate('wed', 'Çarşamba'),
    _DayTemplate('thu', 'Perşembe'),
    _DayTemplate('fri', 'Cuma'),
    _DayTemplate('sat', 'Cumartesi'),
    _DayTemplate('sun', 'Pazar'),
  ];

  static final List<String> _timeOptions = _buildTimeOptions();

  List<_DayHours> _days = _dayTemplates
      .map((day) => _DayHours(key: day.key, label: day.label))
      .toList();

  @override
  void initState() {
    super.initState();
    _profileFuture = _api.getBusiness(widget.user.email);
    _profileFuture.then((profile) {
      if (!mounted || profile == null) return;
      setState(() {
        _applyProfile(profile);
      });
    });
  }

  Future<void> _refreshProfile() async {
    final future = _api.getBusiness(widget.user.email);
    setState(() {
      _profileFuture = future;
    });
    final profile = await future;
    if (!mounted || profile == null) return;
    setState(() {
      _applyProfile(profile);
    });
  }

  @override
  void dispose() {
    _minOrderController.dispose();
    _deliveryTimeController.dispose();
    _deliveryRadiusController.dispose();
    super.dispose();
  }

  static List<String> _buildTimeOptions() {
    final items = <String>[];
    for (int h = 0; h < 24; h++) {
      final hour = h.toString().padLeft(2, '0');
      items.add('$hour:00');
      items.add('$hour:30');
    }
    return items;
  }

  String _formatAmountValue(dynamic value) {
    if (value == null) return '';
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value.toString());
    if (parsed == null) return value.toString();
    return parsed.truncateToDouble() == parsed
        ? parsed.toStringAsFixed(0)
        : parsed.toStringAsFixed(2);
  }

  String _formatIntValue(dynamic value) {
    if (value == null) return '';
    final parsed = value is num
        ? value.toInt()
        : int.tryParse(value.toString());
    return parsed?.toString() ?? value.toString();
  }

  Map<String, dynamic>? _parseWorkingHours(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  List<_DayHours> _buildDaysFromProfile(Map<String, dynamic> profile) {
    final parsed = _parseWorkingHours(profile['working_hours']?.toString());
    return _dayTemplates.map((template) {
      final raw = parsed?[template.key];
      String? open;
      String? close;
      bool closed = false;
      if (raw is Map) {
        open = raw['open']?.toString();
        close = raw['close']?.toString();
        closed = raw['closed'] == true;
      }
      if (open != null && !_timeOptions.contains(open)) {
        open = null;
      }
      if (close != null && !_timeOptions.contains(close)) {
        close = null;
      }
      if (open == null && close == null) {
        closed = true;
      }
      return _DayHours(
        key: template.key,
        label: template.label,
        open: open,
        close: close,
        closed: closed,
      );
    }).toList();
  }

  void _applyProfile(Map<String, dynamic> profile) {
    _days = _buildDaysFromProfile(profile);
    _photoValue = profile['photo_url']?.toString();
    _minOrderController.text = _formatAmountValue(profile['min_order_amount']);
    _deliveryTimeController.text = _formatIntValue(
      profile['delivery_time_mins'],
    );
    _deliveryRadiusController.text =
        _formatAmountValue(profile['delivery_radius_km']);
    final lat = (profile['latitude'] as num?)?.toDouble();
    final lon = (profile['longitude'] as num?)?.toDouble();
    if (lat != null && lon != null) {
      _selectedLocation = LatLng(lat, lon);
    } else {
      _selectedLocation = null;
    }
  }

  String _guessMime(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _pickBusinessImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final base64Data = base64Encode(bytes);
    final mime = _guessMime(file.path);
    setState(() {
      _photoValue = 'data:$mime;base64,$base64Data';
    });
  }

  Future<void> _fillCurrentLocation() async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konum izni verilmedi.')),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _selectedLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _pickLocationOnMap() async {
    final picked = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerPage(
          title: 'İşletme Konumu',
          initial: _selectedLocation,
        ),
      ),
    );
    if (picked != null) {
      setState(() => _selectedLocation = picked);
    }
  }

  String? _validateDays() {
    for (final day in _days) {
      if (!day.closed) {
        if (day.open == null || day.close == null) {
          return '${day.label} için saat seçin.';
        }
      }
    }
    return null;
  }

  Future<void> _saveBusinessInfo() async {
    if (_saving) return;
    final error = _validateDays();
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final minOrderText = _minOrderController.text.trim();
    final deliveryText = _deliveryTimeController.text.trim();
    final radiusText = _deliveryRadiusController.text.trim();
    double? minOrderAmount;
    int? deliveryTimeMins;
    double? deliveryRadiusKm;
    double? latitude;
    double? longitude;
    if (minOrderText.isNotEmpty) {
      final normalized = minOrderText.replaceAll(',', '.');
      minOrderAmount = double.tryParse(normalized);
      if (minOrderAmount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Minimum sepet tutarı geçersiz.')),
        );
        return;
      }
    }
    if (deliveryText.isNotEmpty) {
      deliveryTimeMins = int.tryParse(deliveryText);
      if (deliveryTimeMins == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teslimat süresi geçersiz.')),
        );
        return;
      }
    }
    if (radiusText.isNotEmpty) {
      final normalized = radiusText.replaceAll(',', '.');
      deliveryRadiusKm = double.tryParse(normalized);
      if (deliveryRadiusKm == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teslimat yarıçapı geçersiz.')),
        );
        return;
      }
    }
    if (_selectedLocation != null) {
      latitude = _selectedLocation!.latitude;
      longitude = _selectedLocation!.longitude;
    }
    if (deliveryRadiusKm != null && (latitude == null || longitude == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teslimat için konum seçin.')),
      );
      return;
    }

    final payload = <String, dynamic>{};
    for (final day in _days) {
      payload[day.key] = {
        'open': day.open,
        'close': day.close,
        'closed': day.closed || (day.open == null && day.close == null),
      };
    }

    setState(() => _saving = true);
    final success = await _api.updateBusinessProfile(
      widget.user.email,
      photoUrl: (_photoValue != null && _photoValue!.trim().isNotEmpty)
          ? _photoValue
          : null,
      minOrderAmount: minOrderAmount,
      deliveryTimeMins: deliveryTimeMins,
      deliveryRadiusKm: deliveryRadiusKm,
      latitude: latitude,
      longitude: longitude,
      workingHours: jsonEncode(payload),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      await _refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşletme bilgileri kaydedildi.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Güncelleme başarısız oldu.')),
      );
    }
  }

  Widget _buildPhotoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AppImage(
              source: _photoValue,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: Container(
                height: 160,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.storefront,
                  color: Colors.black38,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickBusinessImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Galeriden Resim Seç'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String suffixText,
    bool decimal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: decimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              decimal ? RegExp(r'[0-9,\.]') : RegExp(r'[0-9]'),
            ),
          ],
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffixText,
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
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
    );
  }

  Widget _buildDeliveryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildNumberField(
            label: 'Minimum Sepet Tutarı',
            controller: _minOrderController,
            hint: 'Örn: 120',
            suffixText: 'TL',
            decimal: true,
          ),
          const SizedBox(height: 12),
          _buildNumberField(
            label: 'Teslimat Süresi',
            controller: _deliveryTimeController,
            hint: 'Örn: 30',
            suffixText: 'dk',
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPreview() {
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
      height: 150,
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

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildNumberField(
            label: 'Teslimat Yarıçapı',
            controller: _deliveryRadiusController,
            hint: 'Örn: 5',
            suffixText: 'km',
            decimal: true,
          ),
          const SizedBox(height: 12),
          _buildLocationPreview(),
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
                  onPressed: _fillCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Mevcut Konumu Al'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('İşletme bilgileri'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            final profile = snapshot.data;
            if (snapshot.connectionState == ConnectionState.waiting &&
                profile == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                if (snapshot.hasError)
                  const Text(
                    'Profil bilgileri alınamadı.',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                if (profile != null) ...[
                  const _SectionTitle('İşletme Detayları'),
                  const SizedBox(height: 10),
                  _InfoCard(items: _buildInfoItems(profile)),
                  const SizedBox(height: 20),
                ],
                const _SectionTitle('İşletme Fotoğrafı'),
                const SizedBox(height: 10),
                _buildPhotoCard(),
                const SizedBox(height: 20),
                const _SectionTitle('Teslimat Ayarları'),
                const SizedBox(height: 10),
                _buildDeliveryCard(),
                const SizedBox(height: 20),
                const _SectionTitle('Konum ve Teslimat Alanı'),
                const SizedBox(height: 10),
                _buildLocationCard(),
                const SizedBox(height: 20),
                const _SectionTitle('Çalışma Saatleri'),
                const SizedBox(height: 10),
                for (final day in _days) _buildDayCard(day),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveBusinessInfo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Kaydet'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDayCard(_DayHours day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  day.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Text(
                'Kapalı',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
              Switch(
                value: day.closed,
                onChanged: (value) {
                  setState(() {
                    day.closed = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TimeDropdown(
                  hint: 'Açılış',
                  value: day.open,
                  enabled: !day.closed,
                  onChanged: (value) {
                    setState(() {
                      day.open = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimeDropdown(
                  hint: 'Kapanış',
                  value: day.close,
                  enabled: !day.closed,
                  onChanged: (value) {
                    setState(() {
                      day.close = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<_InfoItem> _buildInfoItems(Map<String, dynamic> profile) {
    final items = <_InfoItem>[];

    void addItem(String label, String? value) {
      if (value == null) return;
      final text = value.trim();
      if (text.isEmpty) return;
      items.add(_InfoItem(label, text));
    }

    final authName = [profile['authorized_name'], profile['authorized_surname']]
        .where((v) => v != null && v.toString().trim().isNotEmpty)
        .map((v) => v.toString().trim())
        .join(' ');

    addItem('Yetkili', authName.isEmpty ? null : authName);
    addItem('Telefon', profile['phone']?.toString());
    addItem('E-posta', profile['email']?.toString());
    addItem('Şirket Adı', profile['company_name']?.toString());
    addItem('TCKN', profile['tckn']?.toString());

    final businessName =
        profile['restaurant_name']?.toString() ?? profile['name']?.toString();
    addItem('İşletme Adı', businessName);
    addItem('Mutfak Türü', profile['kitchen_type']?.toString());
    addItem('İl', profile['city']?.toString());
    addItem('İlçe', profile['district']?.toString());
    addItem('Mahalle', profile['neighborhood']?.toString());
    final minOrderValue = _formatAmountValue(profile['min_order_amount']);
    if (minOrderValue.isNotEmpty) {
      addItem('Minimum Sepet', '$minOrderValue TL');
    }
    final deliveryValue = _formatIntValue(profile['delivery_time_mins']);
    if (deliveryValue.isNotEmpty) {
      addItem('Teslimat Süresi', '$deliveryValue dk');
    }
    final radiusValue = _formatAmountValue(profile['delivery_radius_km']);
    if (radiusValue.isNotEmpty) {
      addItem('Teslimat Yarıçapı', '$radiusValue km');
    }
    final latValue = _formatAmountValue(profile['latitude']);
    final lonValue = _formatAmountValue(profile['longitude']);
    if (latValue.isNotEmpty && lonValue.isNotEmpty) {
      addItem('Konum', '$latValue, $lonValue');
    }

    final openAddress = profile['open_address']?.toString();
    if (openAddress != null && openAddress.trim().isNotEmpty) {
      addItem('Açık Adres', openAddress);
    } else {
      addItem('Adres', profile['address']?.toString());
    }

    final category = profile['category']?.toString();
    if (category != null) {
      addItem('İşletme Türü', category == 'market' ? 'Market' : 'Restoran');
    }

    return items;
  }
}

class _DayTemplate {
  final String key;
  final String label;
  const _DayTemplate(this.key, this.label);
}

class _DayHours {
  final String key;
  final String label;
  String? open;
  String? close;
  bool closed;

  _DayHours({
    required this.key,
    required this.label,
    this.open,
    this.close,
    this.closed = false,
  });
}

class _TimeDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  const _TimeDropdown({
    required this.hint,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      items: _BusinessInfoPageState._timeOptions
          .map((time) => DropdownMenuItem(value: time, child: Text(time)))
          .toList(),
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
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
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  const _InfoItem(this.label, this.value);
}

class _InfoCard extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Text('Bilgi bulunamadı.'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _InfoRow(label: items[i].label, value: items[i].value),
            if (i != items.length - 1) const Divider(height: 18),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    );
  }
}
