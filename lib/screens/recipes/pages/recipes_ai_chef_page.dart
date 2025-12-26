import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RecipesAiChefPage extends StatefulWidget {
  const RecipesAiChefPage({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  State<RecipesAiChefPage> createState() => _RecipesAiChefPageState();
}

class _RecipesAiChefPageState extends State<RecipesAiChefPage> {
  final TextEditingController _aiPromptController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _aiLoading = false;
  String? _aiText;
  String? _aiError;

  LinearGradient get _brandGradient => const LinearGradient(
    colors: [Color(0xFF8B00FF), Color(0xFFFF006C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  String get _defaultIngredients =>
      'domates, mozzarella, fesleğen, zeytinyağı, tavuk, makarna';

  @override
  void dispose() {
    _aiPromptController.dispose();
    super.dispose();
  }

  Future<void> _runAiChef({Uint8List? imageBytes, String? prompt}) async {
    if (!mounted) return;
    final promptText = prompt ?? _aiPromptController.text.trim();
    final pantryText = promptText.isEmpty ? _defaultIngredients : promptText;

    setState(() {
      _aiLoading = true;
      _aiText = null;
      _aiError = null;
      if (_aiPromptController.text.trim().isEmpty) {
        _aiPromptController.text = pantryText;
      }
    });

    try {
      final model = FirebaseAI.vertexAI().generativeModel(
        model: 'gemini-2.0-flash',
        systemInstruction: Content.system(
          'Sen yaratıcı bir şefsin. 3 tarif üret ve her tarif için aşağıdaki formatı kullan. '
          'Her tarifin başına "Tarif 1", "Tarif 2", "Tarif 3" satırı ekle.\n'
          'Başlık: ...\n'
          'Porsiyon: ...\n'
          'Hazırlama: ...\n'
          'Pişirme: ...\n'
          'Malzemeler:\n- ...\n'
          'Sosu için:\n- ... (yoksa "Yok" yaz)\n'
          'Servis için:\n- ... (yoksa "Yok" yaz)\n'
          'Hazırlanışı:\n1. ...\n2. ...\n'
          'Format dışına çıkma, ek açıklama ekleme. Cevabı Türkçe yaz.',
        ),
      );

      final promptParts = <Part>[
        TextPart(
          'Eldeki malzemelerle 3 tarif öner. Formatı birebir koru. '
          'Malzemeler: $pantryText. '
          'Adımlar en az 5 madde olsun, net ve uygulanabilir yaz.',
        ),
        if (imageBytes != null) InlineDataPart('image/jpeg', imageBytes),
      ];

      final response = await model.generateContent([
        Content.multi(promptParts),
      ]);

      if (!mounted) return;
      setState(() {
        _aiText = response.text ?? 'AI şu an bir cevap üretemedi.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _aiError = 'AI asistan yanıtı alınamadı: $error';
      });
    } finally {
      if (!mounted) return;
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
    if (!mounted) return;
    if (_aiPromptController.text.trim().isEmpty) {
      _aiPromptController.text =
          'Fotoğraftaki malzemelerle ne yapılır? Uygun, pratik tarif öner.';
    }
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
    if (!mounted) return;
    if (_aiPromptController.text.trim().isEmpty) {
      _aiPromptController.text =
          'Fotoğraftaki malzemelerle ne yapılır? Uygun, pratik tarif öner.';
    }
    await _runAiChef(imageBytes: bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('AI Şef'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: _brandGradient,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAiPromptCard(),
            const SizedBox(height: 12),
            _buildPhotoSuggestionCard(),
            const SizedBox(height: 12),
            if (_aiLoading || _aiText != null || _aiError != null)
              _buildAiOutput(),
          ],
        ),
      ),
    );
  }

  Widget _buildAiPromptCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: _brandGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gemini tarif asistanı',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1F4B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Malzemeleri yaz ya da hedefini belirt, AI pratik tarif fikri üretsin.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5B5C73),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _aiPromptController,
            minLines: 2,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText:
                  'Örn: 20 dakikada tavuk, mantar ve krema ile akşam yemeği',
              filled: true,
              fillColor: const Color(0xFFF6F7FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _aiPromptController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _aiLoading
                          ? null
                          : () {
                              _aiPromptController.clear();
                              setState(() {});
                            },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _aiLoading
                      ? null
                      : () => _runAiChef(prompt: _aiPromptController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B00FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.bolt),
                  label: Text(
                    _aiLoading ? 'Hazırlanıyor...' : 'Gemini\'den iste',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSuggestionCard() {
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
              color: const Color(0xFFF1E9FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.photo_camera_back_outlined,
              color: Color(0xFF8B00FF),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Malzemeyi fotoğrafla tara',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1E1F4B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Görüntüdeki malzemeleri algılayıp buna göre pratik tarif fikri sunar.',
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Kamera'),
              ),
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
    if (_aiLoading) {
      return _buildAiLoading();
    }
    if (_aiError != null) {
      return _buildAiError(_aiError!);
    }
    final text = _aiText;
    if (text == null || text.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final recipes = _parseAiRecipes(text);
    final valid = recipes.where((recipe) => recipe.hasContent).toList();
    if (valid.isNotEmpty) {
      return Column(
        children: [
          for (var i = 0; i < valid.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == valid.length - 1 ? 0 : 12),
              child: _buildStructuredOutput(
                valid[i],
                index: valid.length > 1 ? i + 1 : null,
              ),
            ),
        ],
      );
    }
    return _buildPlainText(text);
  }

  Widget _buildAiLoading() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2D9FF)),
      ),
      child: Row(
        children: const [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('AI tarifi hazırlanıyor...'),
        ],
      ),
    );
  }

  Widget _buildAiError(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }

  Widget _buildPlainText(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAEAF2)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF4A4B67),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildStructuredOutput(_AiRecipeSections data, {int? index}) {
    final timeParts = <String>[];
    if (data.cookTime != null && data.cookTime!.isNotEmpty) {
      timeParts.add('${data.cookTime} Pişirme');
    }
    if (data.prepTime != null && data.prepTime!.isNotEmpty) {
      timeParts.add('${data.prepTime} Hazırlama');
    }

    final metaChips = <Widget>[];
    if (data.servings != null && data.servings!.isNotEmpty) {
      metaChips.add(
        _MetaChip(icon: Icons.people_alt_outlined, label: data.servings!),
      );
    }
    if (timeParts.isNotEmpty) {
      metaChips.add(
        _MetaChip(icon: Icons.schedule, label: timeParts.join(', ')),
      );
    }

    final title = (data.title != null && data.title!.isNotEmpty)
        ? data.title
        : (index != null ? 'Tarif $index' : null);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1F4B),
                ),
              ),
            ),
          if (metaChips.isNotEmpty) ...[
            Wrap(spacing: 10, runSpacing: 8, children: metaChips),
            const SizedBox(height: 16),
          ],
          _SectionTitle(text: 'Malzemeler'),
          const SizedBox(height: 8),
          _BulletList(items: data.ingredients),
          if (data.sauce.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionTitle(text: 'Sosu için'),
            const SizedBox(height: 8),
            _BulletList(items: data.sauce),
          ],
          if (data.service.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionTitle(text: 'Servis için'),
            const SizedBox(height: 8),
            _BulletList(items: data.service),
          ],
          if (data.steps.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 24, color: Color(0xFFEAEAF2)),
            _SectionTitle(text: 'Hazırlanışı'),
            const SizedBox(height: 10),
            ...data.steps.asMap().entries.map(
              (entry) => _StepCard(index: entry.key + 1, text: entry.value),
            ),
          ],
        ],
      ),
    );
  }

  List<_AiRecipeSections> _parseAiRecipes(String raw) {
    final recipes = <_AiRecipeSections>[];
    String? title;
    String? servings;
    String? prepTime;
    String? cookTime;
    List<String> ingredients = [];
    List<String> sauce = [];
    List<String> service = [];
    List<String> steps = [];
    String? section;

    void reset() {
      title = null;
      servings = null;
      prepTime = null;
      cookTime = null;
      ingredients = [];
      sauce = [];
      service = [];
      steps = [];
      section = null;
    }

    void commit() {
      final data = _AiRecipeSections(
        title: title,
        servings: servings,
        prepTime: prepTime,
        cookTime: cookTime,
        ingredients: ingredients,
        sauce: sauce,
        service: service,
        steps: steps,
      );
      if (data.hasContent) {
        recipes.add(data);
      }
    }

    reset();
    final lines = raw.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final lower = trimmed.toLowerCase();

      if (_isRecipeHeader(lower)) {
        commit();
        reset();
        continue;
      }

      if (_startsWithKey(lower, 'başlık') || _startsWithKey(lower, 'baslik')) {
        if (title != null || ingredients.isNotEmpty || steps.isNotEmpty) {
          commit();
          reset();
        }
        title = _valueAfterColon(trimmed);
        section = null;
        continue;
      }
      if (_startsWithKey(lower, 'porsiyon')) {
        servings = _valueAfterColon(trimmed);
        section = null;
        continue;
      }
      if (_startsWithKey(lower, 'hazırlama') ||
          _startsWithKey(lower, 'hazirlama')) {
        prepTime = _valueAfterColon(trimmed);
        section = null;
        continue;
      }
      if (_startsWithKey(lower, 'pişirme') || _startsWithKey(lower, 'pisme')) {
        cookTime = _valueAfterColon(trimmed);
        section = null;
        continue;
      }

      final header = _matchSection(lower);
      if (header != null) {
        section = header;
        final value = _valueAfterColon(trimmed);
        if (value != null && !_isEmptyValue(value)) {
          _addToSection(section!, value, ingredients, sauce, service, steps);
        }
        continue;
      }

      if (section == null) continue;

      final cleaned = section == 'steps'
          ? _stripStepPrefix(trimmed)
          : _stripBulletPrefix(trimmed);
      if (cleaned.isEmpty || _isEmptyValue(cleaned)) continue;

      _addToSection(section!, cleaned, ingredients, sauce, service, steps);
    }

    commit();
    return recipes;
  }

  bool _startsWithKey(String lower, String key) => lower.startsWith('$key:');

  bool _isRecipeHeader(String lower) {
    return RegExp(r'^tarif\s*\d+').hasMatch(lower) || lower == 'tarif';
  }

  String? _matchSection(String lower) {
    if (lower == 'malzemeler' || lower.startsWith('malzemeler:')) {
      return 'ingredients';
    }
    if (lower == 'sosu için' ||
        lower == 'sosu icin' ||
        lower.startsWith('sosu için:') ||
        lower.startsWith('sosu icin:')) {
      return 'sauce';
    }
    if (lower == 'servis için' ||
        lower == 'servis icin' ||
        lower.startsWith('servis için:') ||
        lower.startsWith('servis icin:')) {
      return 'service';
    }
    if (lower == 'hazırlanışı' ||
        lower == 'hazirlanisi' ||
        lower == 'hazirlanis' ||
        lower.startsWith('hazırlanışı:') ||
        lower.startsWith('hazirlanisi:') ||
        lower.startsWith('hazirlanis:')) {
      return 'steps';
    }
    return null;
  }

  String? _valueAfterColon(String line) {
    final index = line.indexOf(':');
    if (index == -1) return null;
    final value = line.substring(index + 1).trim();
    return value.isEmpty ? null : value;
  }

  bool _isEmptyValue(String value) {
    final lower = value.toLowerCase();
    return lower == 'yok' || lower == 'yoktur' || lower == '-';
  }

  String _stripBulletPrefix(String value) {
    var text = value.trim();
    if (text.startsWith('-') ||
        text.startsWith('•') ||
        text.startsWith('–') ||
        text.startsWith('*')) {
      text = text.substring(1).trim();
    }
    return text;
  }

  String _stripStepPrefix(String value) {
    return value.replaceFirst(RegExp(r'^\d+[\).\-\s]+'), '').trim();
  }

  void _addToSection(
    String section,
    String value,
    List<String> ingredients,
    List<String> sauce,
    List<String> service,
    List<String> steps,
  ) {
    switch (section) {
      case 'ingredients':
        ingredients.add(value);
        break;
      case 'sauce':
        sauce.add(value);
        break;
      case 'service':
        service.add(value);
        break;
      case 'steps':
        steps.add(value);
        break;
    }
  }
}

class _AiRecipeSections {
  const _AiRecipeSections({
    required this.title,
    required this.servings,
    required this.prepTime,
    required this.cookTime,
    required this.ingredients,
    required this.sauce,
    required this.service,
    required this.steps,
  });

  final String? title;
  final String? servings;
  final String? prepTime;
  final String? cookTime;
  final List<String> ingredients;
  final List<String> sauce;
  final List<String> service;
  final List<String> steps;

  bool get hasContent => ingredients.isNotEmpty || steps.isNotEmpty;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E1F4B),
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '•',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.3,
                      color: Color(0xFF1E1F4B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF3F4059),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAEAF2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6C6D83)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF4A4B67)),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.pinkAccent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEAEAF2)),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF3F4059),
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
