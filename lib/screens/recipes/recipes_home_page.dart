import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

class RecipesHomePage extends StatefulWidget {
  const RecipesHomePage({super.key});

  @override
  State<RecipesHomePage> createState() => _RecipesHomePageState();
}

class _RecipesHomePageState extends State<RecipesHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _aiLoading = false;
  String? _aiText;
  String? _aiError;

  late final List<_RecipeCardData> _recipes;
  final List<_RecipeCardData> _community = [];

  @override
  void initState() {
    super.initState();
    _recipes = [
      const _RecipeCardData(
        title: 'Klasik Margherita Pizza',
        subtitle: 'İtalyan mutfağının vazgeçilmezi',
        time: '45 dk',
        servings: '4 kişilik',
        difficulty: 'Orta',
        imageUrl:
            'https://images.unsplash.com/photo-1498654896293-37aacf113fd9?auto=format&fit=crop&w=800&q=80',
      ),
      const _RecipeCardData(
        title: 'Sebzeli Makarna',
        subtitle: 'Sağlıklı ve lezzetli',
        time: '30 dk',
        servings: '2 kişilik',
        difficulty: 'Kolay',
        imageUrl:
            'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
      ),
      const _RecipeCardData(
        title: 'Sezar Salatası',
        subtitle: 'Ferahlık ve doyuruculuk bir arada',
        time: '20 dk',
        servings: '3 kişilik',
        difficulty: 'Kolay',
        imageUrl:
            'https://images.unsplash.com/photo-1604908177520-402d8363f67f?auto=format&fit=crop&w=800&q=80',
      ),
      const _RecipeCardData(
        title: 'Izgara Somon',
        subtitle: 'Protein dolu hafif bir akşam yemeği',
        time: '35 dk',
        servings: '2 kişilik',
        difficulty: 'Orta',
        imageUrl:
            'https://images.unsplash.com/photo-1525755662778-989d0524087e?auto=format&fit=crop&w=800&q=80',
      ),
    ];
  }

  LinearGradient get _brandGradient => const LinearGradient(
        colors: [Color(0xFF8B00FF), Color(0xFFFF006C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  List<_RecipeCardData> get _filteredPopular {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _recipes;
    return _recipes
        .where((r) =>
            r.title.toLowerCase().contains(query) ||
            r.subtitle.toLowerCase().contains(query))
        .toList();
  }

  List<_RecipeCardData> get _filteredCommunity {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _community;
    return _community
        .where((r) =>
            r.title.toLowerCase().contains(query) ||
            r.subtitle.toLowerCase().contains(query))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runAiChef({Uint8List? imageBytes}) async {
    final pantryText = _searchController.text.trim().isEmpty
        ? 'domates, mozzarella, fesleğen, zeytinyağı, tavuk, makarna'
        : _searchController.text.trim();

    setState(() {
      _aiLoading = true;
      _aiText = null;
      _aiError = null;
    });

    try {
      final model = FirebaseAI.vertexAI().generativeModel(
        model: 'gemini-1.5-flash',
        systemInstruction: Content.system(
          'Sen yaratıcı bir şefsin. Yalnızca tarif önerisi, porsiyon, süre, zorluk '
          've kısa adımları paylaş. Cevapları Türkçe ve net tut.',
        ),
      );

      final promptParts = <Part>[
        TextPart(
          'Eldeki malzemeler veya fotoğraftaki içeriklerle yapılabilecek 3 tarif öner. '
          'Malzemeler: $pantryText. Her tarif için isim, 3 adımlık yöntem, '
          'tahmini süre, porsiyon ve zorluk seviyesini belirt.',
        ),
        if (imageBytes != null) InlineDataPart('image/jpeg', imageBytes),
      ];

      final response = await model.generateContent([
        Content.multi(promptParts),
      ]);

      setState(() {
        _aiText = response.text ?? 'AI şu an bir cevap üretemedi.';
      });
    } catch (error) {
      setState(() {
        _aiError = 'AI asistan yanıtı alınamadı: $error';
      });
    } finally {
      setState(() {
        _aiLoading = false;
      });
    }
  }

  Future<void> _captureFromCamera() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      imageQuality: 75,
    );

    if (image == null) return;
    final bytes = await image.readAsBytes();
    await _runAiChef(imageBytes: bytes);
  }

  Future<void> _pickFromGallery() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 75,
    );

    if (image == null) return;
    final bytes = await image.readAsBytes();
    await _runAiChef(imageBytes: bytes);
  }
  Future<void> _openCreateRecipeSheet() async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    final subtitle = TextEditingController();
    final time = TextEditingController(text: '30 dk');
    final servings = TextEditingController(text: '2 kişilik');
    String difficulty = 'Kolay';
    final image = TextEditingController(
      text:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
    );

    final newRecipe = await showModalBottomSheet<_RecipeCardData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Yeni Tarif Ekle',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _InputField(
                    controller: title,
                    label: 'Tarif adı',
                    hint: 'Örn: Fırında Sebzeli Somon',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Lütfen bir isim girin' : null,
                  ),
                  _InputField(
                    controller: subtitle,
                    label: 'Kısa açıklama',
                    hint: 'Örn: Hafif ve protein dolu akşam yemeği',
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _InputField(
                          controller: time,
                          label: 'Süre',
                          hint: '30 dk',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InputField(
                          controller: servings,
                          label: 'Kişi sayısı',
                          hint: '2 kişilik',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Zorluk',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: ['Kolay', 'Orta', 'Zor']
                        .map(
                          (d) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(d),
                              selected: difficulty == d,
                              onSelected: (_) => setState(() {
                                difficulty = d;
                              }),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  _InputField(
                    controller: image,
                    label: 'Kapak görseli URL',
                    hint: 'https://',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B00FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        Navigator.pop(
                          ctx,
                          _RecipeCardData(
                            title: title.text.trim(),
                            subtitle: subtitle.text.trim().isEmpty
                                ? 'Topluluktan yeni bir tarif'
                                : subtitle.text.trim(),
                            time: time.text.trim(),
                            servings: servings.text.trim(),
                            difficulty: difficulty,
                            imageUrl: image.text.trim(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text(
                        'Kaydet ve Paylaş',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (newRecipe != null) {
      setState(() {
        _community.insert(0, newRecipe);
      });
      await _shareRecipe(newRecipe);
    }
  }

  Future<void> _shareRecipe(_RecipeCardData recipe) async {
    final content = _formatRecipeForShare(recipe);
    await Share.share(content, subject: 'Eaty Tarif Paylaşımı');
  }

  Future<void> _shareCommunity() async {
    if (_community.isEmpty) {
      if (_recipes.isEmpty) return;
      await _shareRecipe(_recipes.first);
      return;
    }
    await _shareRecipe(_community.first);
  }

  String _formatRecipeForShare(_RecipeCardData recipe) {
    return [
      recipe.title,
      recipe.subtitle,
      'Süre: ${recipe.time}',
      'Kişi: ${recipe.servings}',
      'Zorluk: ${recipe.difficulty}',
      if (_aiText != null) 'AI önerisi:\n$_aiText',
    ].where((line) => line.isNotEmpty).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateRecipeSheet,
        backgroundColor: const Color(0xFF8B00FF),
        label: const Text(
          'Tarif ekle',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        icon: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeroHeader(context),
              const SizedBox(height: 110),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickActions(),
                    const SizedBox(height: 12),
                    _buildAiScannerCard(),
                    const SizedBox(height: 12),
                    if (_aiLoading || _aiText != null || _aiError != null)
                      _buildAiOutput(),
                    const SizedBox(height: 8),
                    Text(
                      'Popüler Tarifler',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E1F4B),
                          ),
                    ),
                    const SizedBox(height: 8),
                    ..._filteredPopular.map((r) => _buildRecipeCard(
                          r,
                          onShare: () => _shareRecipe(r),
                        )),
                    if (_community.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Topluluk Paylaşımları',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E1F4B),
                                ),
                      ),
                      const SizedBox(height: 8),
                      ..._filteredCommunity.map(
                        (r) => _buildRecipeCard(
                          r,
                          badge: 'Topluluk',
                          onShare: () => _shareRecipe(r),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          decoration: BoxDecoration(
            gradient: _brandGradient,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.bolt, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'AI Asistan',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Yemek Tarifleri',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Lezzetli tarifler keşfet, paylaş ve AI ile kişiselleştir.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Tarif ara, malzeme gir...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF8B00FF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: -72,
          child: _buildAiDiscoverCard(),
        ),
      ],
    );
  }

  Widget _buildAiDiscoverCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: _brandGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'AI ile Tarif Keşfet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Malzeme listesi ya da fotoğraf yükle, Gemini önerilerini anında al.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _aiLoading ? null : _runAiChef,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF8B00FF),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Hemen Dene',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _QuickActionPill(
          icon: Icons.explore,
          label: 'Tarif keşfi',
          onTap: () {},
        ),
        _QuickActionPill(
          icon: Icons.add_circle_outline,
          label: 'Yeni tarif ekle',
          onTap: _openCreateRecipeSheet,
        ),
        _QuickActionPill(
          icon: Icons.share_outlined,
          label: 'Topluluk paylaşımı',
          onTap: _shareCommunity,
        ),
        _QuickActionPill(
          icon: Icons.bolt,
          label: 'AI önerileri',
          onTap: _aiLoading ? null : _runAiChef,
        ),
        _QuickActionPill(
          icon: Icons.camera_alt_outlined,
          label: 'Fotoğrafla öner',
          onTap: _aiLoading ? null : _captureFromCamera,
        ),
      ],
    );
  }

  Widget _buildAiScannerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4ECFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.photo_camera_back_outlined,
                color: Color(0xFF8B00FF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Malzemelerinin fotoğrafını çek',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1F4B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Gemini, görüntüden malzemeleri okuyup sana uygun tarifler önersin.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5B5C73),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              ElevatedButton.icon(
                onPressed: _aiLoading ? null : _captureFromCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B00FF),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Kamera'),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: _aiLoading ? null : _pickFromGallery,
                child: const Text('Galeriden yükle'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiOutput() {
    final hasError = _aiError != null;
    final text = hasError ? _aiError! : (_aiText ?? 'Öneri hazırlanıyor...');

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasError ? const Color(0xFFFFF1F1) : const Color(0xFFF5F1FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError ? Colors.red.shade100 : const Color(0xFFE2D9FF),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasError ? Colors.red.shade50 : const Color(0xFFE8DEFF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasError ? Icons.error_outline : Icons.auto_awesome,
              color: hasError ? Colors.red.shade400 : const Color(0xFF7C4DFF),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasError ? 'AI yanıtı' : 'AI önerileri',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1E1F4B),
                  ),
                ),
                const SizedBox(height: 6),
                if (_aiLoading)
                  const LinearProgressIndicator(
                    minHeight: 4,
                    backgroundColor: Colors.white,
                    color: Color(0xFF8B00FF),
                  ),
                if (!_aiLoading)
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4A4B67),
                      height: 1.5,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildRecipeCard(
    _RecipeCardData recipe, {
    String? badge,
    VoidCallback? onShare,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              bottomLeft: Radius.circular(18),
            ),
            child: Image.network(
              recipe.imageUrl,
              width: 110,
              height: 110,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipe.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF1E1F4B),
                          ),
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8DEFF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6A4BFF),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6C6D83),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.schedule,
                        label: recipe.time,
                      ),
                      const SizedBox(width: 6),
                      _InfoChip(
                        icon: Icons.group_outlined,
                        label: recipe.servings,
                      ),
                      const SizedBox(width: 6),
                      _DifficultyChip(label: recipe.difficulty),
                      const Spacer(),
                      if (onShare != null)
                        IconButton(
                          onPressed: onShare,
                          icon: const Icon(Icons.ios_share, size: 20),
                          tooltip: 'Paylaş',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionPill extends StatelessWidget {
  const _QuickActionPill({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF8B00FF), size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2E4D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6C6D83)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4A4B67),
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({required this.label});

  final String label;

  Color get _chipColor {
    switch (label.toLowerCase()) {
      case 'kolay':
        return const Color(0xFFE3F7E8);
      case 'orta':
        return const Color(0xFFFFF4E5);
      default:
        return const Color(0xFFEAE6FF);
    }
  }

  Color get _textColor {
    switch (label.toLowerCase()) {
      case 'kolay':
        return const Color(0xFF3C9A4E);
      case 'orta':
        return const Color(0xFFCA8A04);
      default:
        return const Color(0xFF5C4DFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _chipColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _textColor,
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeCardData {
  const _RecipeCardData({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.servings,
    required this.difficulty,
    required this.imageUrl,
  });

  final String title;
  final String subtitle;
  final String time;
  final String servings;
  final String difficulty;
  final String imageUrl;
}
