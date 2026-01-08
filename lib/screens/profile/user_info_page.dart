import 'package:eatyy/models/app_user.dart';
import 'package:eatyy/services/customer_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UserInfoPage extends StatefulWidget {
  final AppUser user;
  const UserInfoPage({super.key, required this.user});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = CustomerProfileService.instance.profile.value;
    final fallbackName = widget.user.displayName ?? '';
    _nameCtrl.text = profile?.name?.trim().isNotEmpty == true
        ? profile!.name!
        : fallbackName;
    final phone = profile?.formattedPhone;
    if (phone != null && phone.isNotEmpty) {
      _phoneCtrl.text = phone;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _digitsOnly(String input) {
    return input.replaceAll(RegExp(r'\D'), '');
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameCtrl.text.trim();
    final digits = _digitsOnly(_phoneCtrl.text);
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İsim alanı boş olamaz.')),
      );
      return;
    }
    if (digits.isNotEmpty) {
      if (digits.length != 11 || !digits.startsWith('05')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Telefon 11 hane olmalı ve 05 ile başlamalı.'),
          ),
        );
        return;
      }
    }
    setState(() => _saving = true);
    await CustomerProfileService.instance.updateProfile(
      name: name,
      phoneDigits: digits.isEmpty ? null : digits,
      email: widget.user.email,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Kullanıcı Bilgilerim'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _Field(label: 'İsim Soyisim', controller: _nameCtrl),
          _Field(
            label: 'Telefon',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: const [_TrPhoneFormatter()],
            hintText: '0(5xx) xxx xx xx',
          ),
          const SizedBox(height: 16),
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
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? hintText;

  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.hintText,
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
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              hintText: hintText,
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

class _TrPhoneFormatter extends TextInputFormatter {
  const _TrPhoneFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (raw.isEmpty) {
      return const TextEditingValue(text: '');
    }

    var digits = raw;
    if (!digits.startsWith('0')) {
      if (digits.startsWith('5')) {
        digits = '0$digits';
      } else {
        digits = '05$digits';
      }
    } else if (digits.length == 1) {
      digits = '05';
    } else if (digits.length >= 2 && digits[1] != '5') {
      digits = '05${digits.substring(1)}';
    }

    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }

    final formatted = formatTrPhone(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
