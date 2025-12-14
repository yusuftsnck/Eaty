import 'package:eatyy/screens/business/tabs/business_dashboard_page.dart';
import 'package:eatyy/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  bool _obscure = true;

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

  // (il/ilçe/mahalle)
  TrLocationData? _loc;
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedNeighborhood;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();

    _authNameController.dispose();
    _authSurnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyNameController.dispose();
    _tcknController.dispose();
    _restaurantNameController.dispose();
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

  Future<void> _loadLocations() async {
    setState(() {
      _loc = TrLocationData.demo();
      _error = _error;
    });
  }

  Future<void> _handleGoogleSignIn() async {
    if (_loading) return;

    // Kayıt modundaysak formu kontrol et
    if (!_isLogin && !_formKey.currentState!.validate()) return;

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

      final api = ApiService();

      if (!_isLogin) {
        final success = await api.registerBusiness({
          "email": account.email,
          "authorized_name": _authNameController.text.trim(),
          "authorized_surname": _authSurnameController.text.trim(),
          "phone": _phoneController.text.trim(),
          "company_name": _companyNameController.text.trim(),
          "tckn": _tcknController.text.trim(),
          "restaurant_name": _restaurantNameController.text.trim(),
          "kitchen_type": _selectedKitchenType,
          "city": _selectedCity,
          "district": _selectedDistrict,
          "neighborhood": _selectedNeighborhood,
          "open_address": _openAddressController.text.trim(),
          "category": "food",
          "photo_url": account.photoUrl,
        });

        if (!success) {
          throw Exception(
            "Kayıt başarısız. Bu e-posta zaten kayıtlı olabilir.",
          );
        }
      } else {
        // --- GİRİŞ (GOOGLE) ---
        final biz = await api.getBusiness(account.email);
        if (biz == null) {
          throw Exception(
            "Bu hesapla kayıtlı işletme bulunamadı. Lütfen önce kayıt olun.",
          );
        }
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BusinessDashboardPage(user: account)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll("Exception:", "").trim());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleEmailPasswordLogin() async {
    if (_loading) return;

    final email = _loginEmailController.text.trim();
    final pass = _loginPasswordController.text;

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

      final biz = await api.getBusiness(email);
      if (biz == null) {
        throw Exception(
          "Bu e-postayla kayıtlı işletme yok. Lütfen kayıt olun.",
        );
      }

      throw Exception(
        "Email/Şifre giriş UI hazır. DashboardPage(user) Google hesabı bekliyor. "
        "DashboardPage’i business modeli kabul edecek şekilde güncelleyelim.",
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceAll("Exception:", "").trim());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleEmailPasswordRegister() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ApiService();

      final success = await api.registerBusiness({
        "email": email,
        "authorized_name": _authNameController.text.trim(),
        "authorized_surname": _authSurnameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "company_name": _companyNameController.text.trim(),
        "tckn": _tcknController.text.trim(),
        "restaurant_name": _restaurantNameController.text.trim(),
        "kitchen_type": _selectedKitchenType,
        "city": _selectedCity,
        "district": _selectedDistrict,
        "neighborhood": _selectedNeighborhood,
        "open_address": _openAddressController.text.trim(),
        "category": "food",
      });

      if (!success)
        throw Exception("Kayıt başarısız. E-posta zaten kayıtlı olabilir.");

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

                            _AuthSwitcher(
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

        _LabeledField(
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
        _LabeledField(
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
          _LabeledField(
            label: 'Ad',
            hint: 'Yetkili adı',
            controller: _authNameController,
            validator: (v) => _required(v, 'Ad'),
          ),
          _LabeledField(
            label: 'Soyad',
            hint: 'Yetkili soyadı',
            controller: _authSurnameController,
            validator: (v) => _required(v, 'Soyad'),
          ),
          _LabeledField(
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
              if (!_isValidTrPhone(v!))
                return 'Geçerli TR telefon girin (05xxxxxxxxx)';
              return null;
            },
          ),
          _LabeledField(
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
          _LabeledField(
            label: 'Şirket Adı',
            hint: 'Dönercik Ltd.',
            controller: _companyNameController,
            validator: (v) => _required(v, 'Şirket Adı'),
          ),
          _LabeledField(
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
              if ((v!.replaceAll(RegExp(r'\D'), '')).length != 11)
                return 'TCKN 11 haneli olmalı';
              if (!_isValidTckn(v)) return 'Geçersiz TCKN';
              return null;
            },
          ),
          _LabeledField(
            label: 'Restoran Adı',
            hint: 'Dönercik',
            controller: _restaurantNameController,
            validator: (v) => _required(v, 'Restoran Adı'),
          ),

          _DropdownField(
            label: 'Mutfak Türü',
            value: _selectedKitchenType,
            hint: 'Seçiniz (Döner, Kebap, Pizza...)',
            items: _kitchenTypes,
            onChanged: (v) => setState(() => _selectedKitchenType = v),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Mutfak türü seçin' : null,
          ),

          _LocationBlock(
            loc: _loc,
            city: _selectedCity,
            district: _selectedDistrict,
            neighborhood: _selectedNeighborhood,
            onCityChanged: (v) => setState(() {
              _selectedCity = v;
              _selectedDistrict = null;
              _selectedNeighborhood = null;
            }),
            onDistrictChanged: (v) => setState(() {
              _selectedDistrict = v;
              _selectedNeighborhood = null;
            }),
            onNeighborhoodChanged: (v) => setState(() {
              _selectedNeighborhood = v;
            }),
          ),

          _LabeledField(
            label: 'Açık Adres',
            hint: 'Cadde, sokak, no, kat, daire...',
            controller: _openAddressController,
            validator: (v) => _required(v, 'Açık Adres'),
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

class _AuthSwitcher extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onChanged;
  const _AuthSwitcher({required this.isLogin, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F6),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTab(
            context,
            title: 'Giriş Yap',
            selected: isLogin,
            value: true,
          ),
          _buildTab(
            context,
            title: 'Kayıt Ol',
            selected: !isLogin,
            value: false,
          ),
        ],
      ),
    );
  }

  Expanded _buildTab(
    BuildContext context, {
    required String title,
    required bool selected,
    required bool value,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.black87 : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final Widget? suffix;

  const _LabeledField({
    required this.label,
    required this.hint,
    this.keyboardType,
    this.controller,
    this.validator,
    this.inputFormatters,
    this.obscureText = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
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
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            inputFormatters: inputFormatters,
            validator:
                validator ??
                (value) =>
                    (value == null || value.isEmpty) ? '$label gerekli' : null,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: suffix,
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
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
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
          DropdownButtonFormField<String>(
            value: value,
            items: items
                .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
            validator: validator,
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
          ),
        ],
      ),
    );
  }
}

class _LocationBlock extends StatelessWidget {
  final TrLocationData? loc;
  final String? city;
  final String? district;
  final String? neighborhood;
  final ValueChanged<String?> onCityChanged;
  final ValueChanged<String?> onDistrictChanged;
  final ValueChanged<String?> onNeighborhoodChanged;

  const _LocationBlock({
    required this.loc,
    required this.city,
    required this.district,
    required this.neighborhood,
    required this.onCityChanged,
    required this.onDistrictChanged,
    required this.onNeighborhoodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cities = loc?.cities.map((c) => c.name).toList() ?? const <String>[];
    final selectedCity = loc?.cities.where((c) => c.name == city).toList();
    final districts = (selectedCity?.isNotEmpty == true)
        ? selectedCity!.first.districts.map((d) => d.name).toList()
        : const <String>[];

    final selectedDistrict = (selectedCity?.isNotEmpty == true)
        ? selectedCity!.first.districts
              .where((d) => d.name == district)
              .toList()
        : <TrDistrict>[];

    final neighborhoods = (selectedDistrict.isNotEmpty)
        ? selectedDistrict.first.neighborhoods
        : const <String>[];

    return Column(
      children: [
        _DropdownField(
          label: 'İl',
          value: city,
          hint: (loc == null) ? 'Yükleniyor...' : 'İl seçin',
          items: cities,
          onChanged: onCityChanged,
          validator: (v) => (v == null || v.isEmpty) ? 'İl seçin' : null,
        ),
        _DropdownField(
          label: 'İlçe',
          value: district,
          hint: 'İlçe seçin',
          items: districts,
          onChanged: onDistrictChanged,
          validator: (v) => (v == null || v.isEmpty) ? 'İlçe seçin' : null,
        ),
        _DropdownField(
          label: 'Mahalle',
          value: neighborhood,
          hint: 'Mahalle seçin',
          items: neighborhoods,
          onChanged: onNeighborhoodChanged,
          validator: (v) => (v == null || v.isEmpty) ? 'Mahalle seçin' : null,
        ),
      ],
    );
  }
}

class TrLocationData {
  final List<TrCity> cities;
  TrLocationData({required this.cities});

  factory TrLocationData.fromJson(Map<String, dynamic> json) {
    final list = (json['cities'] as List<dynamic>)
        .map((e) => TrCity.fromJson(e as Map<String, dynamic>))
        .toList();
    return TrLocationData(cities: list);
  }

  // Demo veri
  factory TrLocationData.demo() {
    return TrLocationData(
      cities: [
        TrCity(
          name: 'Muğla',
          districts: [
            TrDistrict(
              name: 'Menteşe',
              neighborhoods: ['Kötekli Mh.', 'Orhaniye Mh.'],
            ),
            TrDistrict(
              name: 'Bodrum',
              neighborhoods: ['Gümbet Mh.', 'Bitez Mh.'],
            ),
          ],
        ),
        TrCity(
          name: 'İstanbul',
          districts: [
            TrDistrict(
              name: 'Kadıköy',
              neighborhoods: ['Caferağa Mh.', 'Fenerbahçe Mh.'],
            ),
            TrDistrict(
              name: 'Şişli',
              neighborhoods: ['Mecidiyeköy Mh.', 'Harbiye Mh.'],
            ),
          ],
        ),
      ],
    );
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
