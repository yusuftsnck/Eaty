import 'dart:convert';

import 'package:eatyy/models/business_user.dart';
import 'package:eatyy/screens/business/tabs/business_dashboard_page.dart';
import 'package:eatyy/services/api_service.dart';
import 'package:eatyy/services/business_session_service.dart';
import 'package:eatyy/services/session_role_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:eatyy/screens/business/auth/models/tr_location_data.dart';
import 'package:eatyy/screens/business/auth/widgets/auth_switcher.dart';
import 'package:eatyy/screens/business/auth/widgets/dropdown_field.dart';
import 'package:eatyy/screens/business/auth/widgets/labeled_field.dart';
import 'package:eatyy/screens/business/auth/widgets/location_block.dart';

class BusinessAuthPage extends StatefulWidget {
  const BusinessAuthPage({super.key});

  @override
  State<BusinessAuthPage> createState() => _BusinessAuthPageState();
}

class _BusinessAuthPageState extends State<BusinessAuthPage> {
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  final _formKey = GlobalKey<FormState>();

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerPasswordConfirmController = TextEditingController();
  bool _obscure = true;
  bool _requireRegisterPassword = false;

  final _authNameController = TextEditingController(); // Yetkili Ad
  final _authSurnameController = TextEditingController(); // Yetkili Soyad
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final _companyNameController = TextEditingController(); // Şirket Adı
  final _tcknController = TextEditingController(); // TCKN
  final _restaurantNameController = TextEditingController(); // Restoran Adı
  final _openAddressController = TextEditingController(); // Açık adres

  final List<String> _kitchenTypes = const [
    'Döner',
    'Kebap',
    'Pizza',
    'Burger',
    'Pide/Lahmacun',
    'Tavuk',
    'Çiğ Köfte',
    'Tatlı/Pastane',
    'Kahve',
    'Ev Yemekleri',
    'Balık',
    'Uzak Doğu',
    'Vegan/Vejetaryen',
    'Diğer',
  ];
  String? _selectedKitchenType;

  // Seçeneklerin olduğu liste
  final List<String> _businessTypes = ['Restoran', 'Market'];

  // Seçilen değeri tutacak değişken
  String? _selectedBusinessType;

  // (il/ilçe/mahalle)
  TrLocationData? _loc;
  String? _selectedCity;
  String? _selectedDistrict;
  final _neighborhoodController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _checkSession();
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerPasswordController.dispose();
    _registerPasswordConfirmController.dispose();

    _authNameController.dispose();
    _authSurnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyNameController.dispose();
    _tcknController.dispose();
    _restaurantNameController.dispose();
    _neighborhoodController.dispose();
    _openAddressController.dispose();
    super.dispose();
  }

  String? _required(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label gerekli';
    return null;
  }

  bool _isValidEmail(String v) {
    final s = v.trim();
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(s);
  }

  bool _isValidTrPhone(String v) {
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11 && digits.startsWith('0') && digits[1] == '5') {
      return true;
    }
    if (digits.length == 12 && digits.startsWith('90') && digits[2] == '5') {
      return true;
    }
    return false;
  }

  bool _isValidTckn(String v) {
    final s = v.replaceAll(RegExp(r'\D'), '');
    if (s.length != 11) return false;
    if (s.startsWith('0')) return false;

    final digits = s.split('').map(int.parse).toList();

    final oddSum = digits[0] + digits[2] + digits[4] + digits[6] + digits[8];
    final evenSum = digits[1] + digits[3] + digits[5] + digits[7];

    final d10 = ((oddSum * 7) - evenSum) % 10;
    if (d10 < 0) return false;
    if (digits[9] != d10) return false;

    final sumFirst10 = digits.take(10).reduce((a, b) => a + b);
    final d11 = sumFirst10 % 10;
    if (digits[10] != d11) return false;

    return true;
  }

  String? _mapBusinessTypeToCategory(String? type) {
    if (type == 'Market') return 'market';
    if (type == 'Restoran') return 'food';
    return null;
  }

  String _composeAddress() {
    final parts = <String>[];
    final open = _openAddressController.text.trim();
    if (open.isNotEmpty) parts.add(open);
    final neighborhood = _neighborhoodController.text.trim();
    if (neighborhood.isNotEmpty) {
      parts.add(neighborhood);
    }
    if ((_selectedDistrict ?? '').trim().isNotEmpty) {
      parts.add(_selectedDistrict!.trim());
    }
    if ((_selectedCity ?? '').trim().isNotEmpty) {
      parts.add(_selectedCity!.trim());
    }
    return parts.join(', ');
  }

  Future<void> _loadLocations() async {
    try {
      final raw = await rootBundle.loadString('assets/il_ilce.json');
      final decoded = jsonDecode(raw);
      final loc = TrLocationData.fromIlIlceJson(decoded);
      if (!mounted) return;
      setState(() => _loc = loc);
    } catch (_) {}
  }

  void _checkSession() {
    final sessionUser = BusinessSessionService.instance.user.value;
    if (sessionUser == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BusinessDashboardPage(user: sessionUser),
        ),
      );
    });
    SessionRoleService.instance.setRole('business');
  }

  Future<void> _handleGoogleSignIn() async {
    if (_loading) return;

    if (!_isLogin) {
      _requireRegisterPassword = false;
      if (!_formKey.currentState!.validate()) return;
    }

    final previousRole = SessionRoleService.instance.role.value;
    await SessionRoleService.instance.setRole('business');

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final signIn = GoogleSignIn.instance;
      await signIn.initialize();

      final GoogleSignInAccount? account = signIn.supportsAuthenticate()
          ? await signIn.authenticate()
          : await signIn.attemptLightweightAuthentication();

      if (account == null) throw Exception('Giriş iptal edildi.');
      final accountEmail = account.email.toLowerCase();

      final api = ApiService();
      Map<String, dynamic>? profile;

      if (!_isLogin) {
        final category = _mapBusinessTypeToCategory(_selectedBusinessType);
        if (category == null) {
          throw Exception("Lütfen işletme türünü seçin.");
        }
        final kitchenType = category == 'food' ? _selectedKitchenType : null;
        final password = _registerPasswordController.text.trim();
        final success = await api.registerBusiness({
          "email": accountEmail,
          "name": _restaurantNameController.text.trim(),
          "authorized_name": _authNameController.text.trim(),
          "authorized_surname": _authSurnameController.text.trim(),
          "phone": _phoneController.text.trim(),
          "address": _composeAddress(),
          "company_name": _companyNameController.text.trim(),
          "tckn": _tcknController.text.trim(),
          "restaurant_name": _restaurantNameController.text.trim(),
          "kitchen_type": kitchenType,
          "city": _selectedCity,
          "district": _selectedDistrict,
          "neighborhood": _neighborhoodController.text.trim(),
          "open_address": _openAddressController.text.trim(),
          "category": category,
          "photo_url": account.photoUrl,
          if (password.isNotEmpty) "password": password,
        });

        if (!success) {
          throw Exception(
            "Kayıt başarısız. Bu e-posta zaten kayıtlı olabilir.",
          );
        }
        profile = await api.getBusiness(accountEmail);
      } else {
        profile = await api.getBusiness(accountEmail);
        if (profile == null) {
          throw Exception(
            "Bu hesapla kayıtlı işletme bulunamadı. Lütfen önce kayıt olun.",
          );
        }
      }

      if (profile == null) {
        throw Exception("İşletme bilgileri alınamadı.");
      }

      final user = BusinessUser.fromProfile(
        profile,
        isGoogle: true,
        fallbackName: account.displayName,
        fallbackPhotoUrl: account.photoUrl,
      );
      await BusinessSessionService.instance.setUser(user);
      await SessionRoleService.instance.setRole('business');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BusinessDashboardPage(user: user)),
      );
    } catch (e) {
      if (previousRole != 'business') {
        await SessionRoleService.instance.setRole(previousRole);
      }
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll("Exception:", "").trim());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleEmailPasswordLogin() async {
    if (_loading) return;

    final email = _loginEmailController.text.trim().toLowerCase();
    final pass = _loginPasswordController.text.trim();

    if (!_isValidEmail(email)) {
      setState(() => _error = 'Geçerli bir e-posta girin.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Şifre en az 6 karakter olmalı.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ApiService();

      final profile = await api.loginBusiness(email, pass);
      final user = BusinessUser.fromProfile(profile, isGoogle: false);
      await BusinessSessionService.instance.setUser(user);
      await SessionRoleService.instance.setRole('business');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BusinessDashboardPage(user: user)),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceAll("Exception:", "").trim());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleEmailPasswordRegister() async {
    if (_loading) return;
    _requireRegisterPassword = true;
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    final category = _mapBusinessTypeToCategory(_selectedBusinessType);
    if (category == null) {
      setState(() => _error = "Lütfen işletme türünü seçin.");
      return;
    }
    final kitchenType = category == 'food' ? _selectedKitchenType : null;
    final password = _registerPasswordController.text.trim();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ApiService();

      final success = await api.registerBusiness({
        "email": email,
        "name": _restaurantNameController.text.trim(),
        "authorized_name": _authNameController.text.trim(),
        "authorized_surname": _authSurnameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "address": _composeAddress(),
        "company_name": _companyNameController.text.trim(),
        "tckn": _tcknController.text.trim(),
        "restaurant_name": _restaurantNameController.text.trim(),
        "kitchen_type": kitchenType,
        "city": _selectedCity,
        "district": _selectedDistrict,
        "neighborhood": _neighborhoodController.text.trim(),
        "open_address": _openAddressController.text.trim(),
        "category": category,
        "password": password,
      });

      if (!success) {
        throw Exception("Kayıt başarısız. E-posta zaten kayıtlı olabilir.");
      }

      // Kayıt başarılı mesajı
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıt oluşturuldu. Şimdi giriş yapabilirsiniz.'),
        ),
      );
      setState(() => _isLogin = true);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll("Exception:", "").trim());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF7A18), Color(0xFFE60012)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, padding.top + 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Geri'),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFFE6D1),
                                border: Border.all(
                                  color: const Color(0xFFFFAB76),
                                ),
                              ),
                              child: const Icon(
                                Icons.storefront,
                                color: Color(0xFFE85B2B),
                                size: 38,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'İşletme Girişi / Kaydı',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 18),

                            AuthSwitcher(
                              isLogin: _isLogin,
                              onChanged: (val) => setState(() {
                                _isLogin = val;
                                _error = null;
                              }),
                            ),
                            const SizedBox(height: 18),

                            if (_isLogin) ...[
                              _buildLoginBlock(),
                            ] else ...[
                              _buildRegisterBlock(),
                            ],

                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginBlock() {
    return Column(
      children: [
        const Text(
          'Hesabınıza giriş yapın',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
        const SizedBox(height: 12),

        LabeledField(
          label: 'E-posta',
          hint: 'ornek@firma.com',
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            final r = _required(v, 'E-posta');
            if (r != null) return r;
            if (!_isValidEmail(v!.trim())) return 'Geçerli e-posta girin';
            return null;
          },
        ),
        LabeledField(
          label: 'Şifre',
          hint: '••••••••',
          controller: _loginPasswordController,
          obscureText: _obscure,
          suffix: IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          ),
          validator: (v) {
            final r = _required(v, 'Şifre');
            if (r != null) return r;
            if (v!.length < 6) return 'Şifre en az 6 karakter olmalı';
            return null;
          },
        ),

        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _handleEmailPasswordLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('E-posta & Şifre ile Giriş'),
          ),
        ),

        const SizedBox(height: 10),
        _dividerOr(),

        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _handleGoogleSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              side: const BorderSide(color: Color(0xFFE0E0E0)),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Google ile Giriş Yap'),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterBlock() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const Text(
            'Tek form ile başvuru oluşturun',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 12),

          _sectionTitle('Şirket Yetkilisi Bilgileri'),
          LabeledField(
            label: 'Ad',
            hint: 'Yetkili adı',
            controller: _authNameController,
            validator: (v) => _required(v, 'Ad'),
          ),
          LabeledField(
            label: 'Soyad',
            hint: 'Yetkili soyadı',
            controller: _authSurnameController,
            validator: (v) => _required(v, 'Soyad'),
          ),
          LabeledField(
            label: 'Cep Telefonu',
            hint: '0555 123 45 67',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\s\+\(\)\-]')),
              LengthLimitingTextInputFormatter(16),
            ],
            validator: (v) {
              final r = _required(v, 'Cep Telefonu');
              if (r != null) return r;
              if (!_isValidTrPhone(v!)) {
                return 'Geçerli TR telefon girin (05xxxxxxxxx)';
              }
              return null;
            },
          ),
          LabeledField(
            label: 'E-posta Adresi',
            hint: 'ornek.yemek@gmail.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              final r = _required(v, 'E-posta');
              if (r != null) return r;
              if (!_isValidEmail(v!.trim())) return 'Geçerli e-posta girin';
              return null;
            },
          ),
          const SizedBox(height: 6),
          _sectionTitle('İşletme ve Konum Bilgileri'),
          LabeledField(
            label: 'Şirket Adı',
            hint: 'Dönercik Ltd.',
            controller: _companyNameController,
            validator: (v) => _required(v, 'Şirket Adı'),
          ),
          LabeledField(
            label: 'TCKN',
            hint: '11 haneli',
            controller: _tcknController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            validator: (v) {
              final r = _required(v, 'TCKN');
              if (r != null) return r;
              if ((v!.replaceAll(RegExp(r'\D'), '')).length != 11) {
                return 'TCKN 11 haneli olmalı';
              }
              if (!_isValidTckn(v)) return 'Geçersiz TCKN';
              return null;
            },
          ),
          DropdownField(
            label: 'İşletme Türü',
            value: _selectedBusinessType,
            hint: 'Seçiniz',
            items: _businessTypes,
            onChanged: (v) {
              setState(() {
                _selectedBusinessType = v;
                if (_selectedBusinessType == 'Market') {
                  _selectedKitchenType = null;
                }
              });
            },
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Lütfen işletme türünü seçin' : null,
          ),

          LabeledField(
            label: 'İşletme Adı',
            hint: '',
            controller: _restaurantNameController,
            validator: (v) => _required(v, 'İşletme Adı'),
          ),

          DropdownField(
            label: 'Mutfak Türü',
            value: _selectedKitchenType,
            hint: 'Seçiniz',
            items: _kitchenTypes,
            onChanged: (v) => setState(() => _selectedKitchenType = v),
            validator: (v) {
              if (_selectedBusinessType == 'Market') return null;
              return (v == null || v.isEmpty) ? 'Mutfak türü seçin' : null;
            },
          ),

          LocationBlock(
            loc: _loc,
            city: _selectedCity,
            district: _selectedDistrict,
            neighborhoodController: _neighborhoodController,
            onCityChanged: (v) => setState(() {
              _selectedCity = v;
              _selectedDistrict = null;
              _neighborhoodController.clear();
            }),
            onDistrictChanged: (v) => setState(() {
              _selectedDistrict = v;
              _neighborhoodController.clear();
            }),
          ),

          LabeledField(
            label: 'Açık Adres',
            hint: 'Cadde, sokak, no',
            controller: _openAddressController,
            validator: (v) => _required(v, 'Açık Adres'),
          ),

          _sectionTitle('İşletme Yönetim Paneli Giriş Bilgileri'),

          LabeledField(
            label: 'Şifre',
            hint: '••••••••',
            controller: _registerPasswordController,
            obscureText: _obscure,
            suffix: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
            ),
            validator: (v) {
              if (!_requireRegisterPassword &&
                  (v == null || v.trim().isEmpty)) {
                return null;
              }
              final r = _required(v, 'Şifre');
              if (r != null) return r;
              if (v!.length < 6) return 'Şifre en az 6 karakter olmalı';
              return null;
            },
          ),
          LabeledField(
            label: 'Şifreyi onaylayın',
            hint: '••••••••',
            controller: _registerPasswordConfirmController,
            obscureText: _obscure,
            suffix: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
            ),
            validator: (v) {
              if (!_requireRegisterPassword &&
                  (v == null || v.trim().isEmpty)) {
                return null;
              }
              final r = _required(v, 'Şifre');
              if (r != null) return r;
              if (v != _registerPasswordController.text) {
                return 'Şifreler eşleşmiyor';
              }
              return null;
            },
          ),

          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _handleEmailPasswordRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kaydı Oluştur'),
            ),
          ),

          const SizedBox(height: 10),
          _dividerOr(),
          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _handleGoogleSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Color(0xFFE0E0E0)),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Google ile Kayıt Ol'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dividerOr() {
    return Row(
      children: const [
        Expanded(child: Divider(height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('veya', style: TextStyle(color: Colors.black54)),
        ),
        Expanded(child: Divider(height: 1)),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
