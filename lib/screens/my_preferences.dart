import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'homepage.dart';
import 'health_dashboard_screen.dart';
import 'reports_screen.dart';
import 'scan_screen.dart';
import 'Setting.dart';
import 'simple_preferences_editor.dart';
import '../config/app_config.dart';




const Color kPrimary = Color(0xFF2D7D6F);
const Color kPrimaryLight = Color(0xFF3A9E8D);
const Color kBgCream = Color(0xFFF5F0E8);
const Color kCardBg = Color(0xFFFFFFFF);
const Color kChipSelected = Color(0xFF2D7D6F);
const Color kChipUnselected = Color(0xFFE6F3F0);
const Color kTextDark = Color(0xFF1A1A1A);
const Color kTextMid = Color(0xFF4A4A4A);
const Color kTextLight = Color(0xFF8A8A8A);

String get kApiBaseUrl => AppConfig.apiBaseUrl;




enum PreferenceCategory {
  allergens,
  additive,
  diet,
  ingredient,
  nutrition,
  advanced
}

const _categoryLabels = {
  PreferenceCategory.allergens: 'Allergens',
  PreferenceCategory.additive: 'Additive',
  PreferenceCategory.diet: 'Diet',
  PreferenceCategory.ingredient: 'Ingredient',
  PreferenceCategory.nutrition: 'Nutrition',
  PreferenceCategory.advanced: 'Advanced',
};

const _categoryIcons = {
  PreferenceCategory.allergens: Icons.no_drinks_outlined,
  PreferenceCategory.additive: Icons.grass_outlined,
  PreferenceCategory.diet: Icons.eco_outlined,
  PreferenceCategory.ingredient: Icons.inventory_2_outlined,
  PreferenceCategory.nutrition: Icons.grid_view_outlined,
  PreferenceCategory.advanced: Icons.manage_search_outlined,
};

const _visiblePreferenceCategories = [
  PreferenceCategory.allergens,
  PreferenceCategory.additive,
  PreferenceCategory.diet,
  PreferenceCategory.ingredient,
  PreferenceCategory.nutrition,
];




class UserPreferences {
  Set<String> allergens;
  List<String> customAllergens;
  String allergenImportance;

  Set<String> additives;
  List<String> customAdditives;
  String additiveImportance;

  Set<String> diets;
  List<String> customDiets;
  String dietImportance;

  Set<String> ingredients;
  List<String> customIngredients;
  String ingredientImportance;

  Set<String> nutritions;
  List<String> customNutritions;
  String nutritionImportance;

  Set<String> healthConditions;
  List<String> customHealthConditions;
  String healthConditionImportance;

  Set<String> avoidedIngredients;
  List<String> customAvoidedIngredients;
  String avoidedIngredientImportance;

  Set<String> preferredIngredients;
  List<String> customPreferredIngredients;
  String preferredIngredientImportance;

  Set<String> productCategories;
  List<String> customProductCategories;
  String productCategoryImportance;

  Set<String> recommendationSettings;
  List<String> customRecommendationSettings;
  String recommendationSettingImportance;

  UserPreferences({
    this.allergens = const {},
    this.customAllergens = const [],
    this.allergenImportance = 'Essential',
    this.additives = const {},
    this.customAdditives = const [],
    this.additiveImportance = 'Essential',
    this.diets = const {},
    this.customDiets = const [],
    this.dietImportance = 'Essential',
    this.ingredients = const {},
    this.customIngredients = const [],
    this.ingredientImportance = 'Essential',
    this.nutritions = const {},
    this.customNutritions = const [],
    this.nutritionImportance = 'Preferred',
    this.healthConditions = const {},
    this.customHealthConditions = const [],
    this.healthConditionImportance = 'Essential',
    this.avoidedIngredients = const {},
    this.customAvoidedIngredients = const [],
    this.avoidedIngredientImportance = 'Essential',
    this.preferredIngredients = const {},
    this.customPreferredIngredients = const [],
    this.preferredIngredientImportance = 'Preferred',
    this.productCategories = const {},
    this.customProductCategories = const [],
    this.productCategoryImportance = 'Preferred',
    this.recommendationSettings = const {},
    this.customRecommendationSettings = const [],
    this.recommendationSettingImportance = 'Preferred',
  });

  Map<String, dynamic> toJson(
      {required String userId, required String userName}) {
    return {
      'userId': userId,
      'userName': userName,
      'allergens': allergens.toList(),
      'customAllergens': customAllergens,
      'allergenImportance': allergenImportance,
      'additives': additives.toList(),
      'customAdditives': customAdditives,
      'additiveImportance': additiveImportance,
      'diets': diets.toList(),
      'customDiets': customDiets,
      'dietImportance': dietImportance,
      'ingredients': ingredients.toList(),
      'customIngredients': customIngredients,
      'ingredientImportance': ingredientImportance,
      'nutritions': nutritions.toList(),
      'customNutritions': customNutritions,
      'nutritionImportance': nutritionImportance,
      'healthConditions': healthConditions.toList(),
      'customHealthConditions': customHealthConditions,
      'healthConditionImportance': healthConditionImportance,
      'avoidedIngredients': avoidedIngredients.toList(),
      'customAvoidedIngredients': customAvoidedIngredients,
      'avoidedIngredientImportance': avoidedIngredientImportance,
      'preferredIngredients': preferredIngredients.toList(),
      'customPreferredIngredients': customPreferredIngredients,
      'preferredIngredientImportance': preferredIngredientImportance,
      'productCategories': productCategories.toList(),
      'customProductCategories': customProductCategories,
      'productCategoryImportance': productCategoryImportance,
      'recommendationSettings': recommendationSettings.toList(),
      'customRecommendationSettings': customRecommendationSettings,
      'recommendationSettingImportance': recommendationSettingImportance,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    List<String> listValue(String key) {
      final value = json[key];
      if (value is List) return value.map((e) => e.toString()).toList();
      return <String>[];
    }

    return UserPreferences(
      allergens: listValue('allergens').toSet(),
      customAllergens: listValue('customAllergens'),
      allergenImportance: json['allergenImportance']?.toString() ?? 'Essential',
      additives: listValue('additives').toSet(),
      customAdditives: listValue('customAdditives'),
      additiveImportance: json['additiveImportance']?.toString() ?? 'Essential',
      diets: listValue('diets').toSet(),
      customDiets: listValue('customDiets'),
      dietImportance: json['dietImportance']?.toString() ?? 'Essential',
      ingredients: listValue('ingredients').toSet(),
      customIngredients: listValue('customIngredients'),
      ingredientImportance:
          json['ingredientImportance']?.toString() ?? 'Essential',
      nutritions: listValue('nutritions').toSet(),
      customNutritions: listValue('customNutritions'),
      nutritionImportance:
          json['nutritionImportance']?.toString() ?? 'Preferred',
      healthConditions: listValue('healthConditions').toSet(),
      customHealthConditions: listValue('customHealthConditions'),
      healthConditionImportance:
          json['healthConditionImportance']?.toString() ?? 'Essential',
      avoidedIngredients: listValue('avoidedIngredients').toSet(),
      customAvoidedIngredients: listValue('customAvoidedIngredients'),
      avoidedIngredientImportance:
          json['avoidedIngredientImportance']?.toString() ?? 'Essential',
      preferredIngredients: listValue('preferredIngredients').toSet(),
      customPreferredIngredients: listValue('customPreferredIngredients'),
      preferredIngredientImportance:
          json['preferredIngredientImportance']?.toString() ?? 'Preferred',
      productCategories: listValue('productCategories').toSet(),
      customProductCategories: listValue('customProductCategories'),
      productCategoryImportance:
          json['productCategoryImportance']?.toString() ?? 'Preferred',
      recommendationSettings: listValue('recommendationSettings').toSet(),
      customRecommendationSettings: listValue('customRecommendationSettings'),
      recommendationSettingImportance:
          json['recommendationSettingImportance']?.toString() ?? 'Preferred',
    );
  }
}

class PreferenceApiService {
  static String _tokenForUser(String userId) => 'dummy-token-$userId';

  static Future<bool> savePreferences({
    required String userId,
    required String userName,
    required UserPreferences preferences,
  }) async {
    final uri = Uri.parse('$kApiBaseUrl/api/preferences/save');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_tokenForUser(userId)}',
      },
      body: jsonEncode(preferences.toJson(userId: userId, userName: userName)),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<UserPreferences?> getPreferences({
    required String userId,
  }) async {
    final uri = Uri.parse('$kApiBaseUrl/api/preferences/$userId');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_tokenForUser(userId)}',
      },
    );

    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['preferences'];
    if (data == null || data is! Map<String, dynamic>) return null;

    return UserPreferences.fromJson(data);
  }
}




class _PrefsAppBar extends StatelessWidget {
  final VoidCallback? onBackPressed;
  final bool showBackButton;

  const _PrefsAppBar({
    this.onBackPressed,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool canShowBack = showBackButton && onBackPressed != null;

    return Container(
      color: kBgCream,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: canShowBack
                ? IconButton(
                    icon: const Icon(Icons.chevron_left,
                        color: kPrimary, size: 28),
                    onPressed: onBackPressed,
                  )
                : const SizedBox.shrink(),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'My Preferences',
                style: TextStyle(
                  color: kPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String title;
  final PreferenceCategory active;

  const _CategoryHeader({required this.title, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: kPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _visiblePreferenceCategories.map((cat) {
              final bool isSelected = cat == active;
              return Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? kBgCream
                            : Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? kBgCream
                              : Colors.white.withOpacity(0.22),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        _categoryIcons[cat]!,
                        color: isSelected ? kPrimary : Colors.white70,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _categoryLabels[cat]!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 9.5,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationHeader extends StatelessWidget {
  const _ConfirmationHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: kPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
      child: Column(
        children: [
          const Text(
            'Confirmation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _visiblePreferenceCategories.map((cat) {
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: kBgCream,
                        shape: BoxShape.circle,
                      ),
                      child:
                          Icon(_categoryIcons[cat]!, color: kPrimary, size: 22),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _categoryLabels[cat]!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PreferenceFormCard extends StatelessWidget {
  final Widget child;

  const _PreferenceFormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PrefChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PrefChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? kChipSelected : kChipUnselected,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: selected ? kChipSelected : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : kTextDark,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _ChipsSection extends StatelessWidget {
  final String sectionLabel;
  final List<String> items;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _ChipsSection({
    required this.sectionLabel,
    required this.items,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionLabel,
          style: const TextStyle(
            color: kTextDark,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map((item) => _PrefChip(
                    label: item,
                    selected: selected.contains(item),
                    onTap: () => onToggle(item),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _CustomInputSection extends StatefulWidget {
  final String title;
  final String hint;
  final List<String> addedItems;
  final Function(String) onAddItem;
  final Function(String) onRemoveItem;

  const _CustomInputSection({
    required this.title,
    required this.hint,
    required this.addedItems,
    required this.onAddItem,
    required this.onRemoveItem,
  });

  @override
  State<_CustomInputSection> createState() => _CustomInputSectionState();
}

class _CustomInputSectionState extends State<_CustomInputSection> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onAddItem(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            color: kTextDark,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Add any extra item you want to include in your preferences.',
          style: TextStyle(color: kTextLight, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: const TextStyle(color: kTextLight, fontSize: 12.5),
                  filled: true,
                  fillColor: kBgCream,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: Colors.black.withOpacity(0.04)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: kPrimary, width: 1.3),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _addItem,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
        if (widget.addedItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.addedItems
                .map((a) => _PrefChip(
                      label: a,
                      selected: true,
                      onTap: () => widget.onRemoveItem(a),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _ImportanceSection extends StatefulWidget {
  final String value;
  final Function(String) onChanged;

  const _ImportanceSection({required this.value, required this.onChanged});

  @override
  State<_ImportanceSection> createState() => _ImportanceSectionState();
}

class _ImportanceSectionState extends State<_ImportanceSection> {
  final List<String> _importanceOptions = [
    'Nice to Have',
    'Preferred',
    'Essential',
    'Severe'
  ];
  late String _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue =
        _importanceOptions.contains(widget.value) ? widget.value : 'Essential';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Importance',
          style: TextStyle(
            color: kTextDark,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: kBgCream,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withOpacity(0.04)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedValue,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: kPrimary),
              items: _importanceOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() => _selectedValue = newValue);
                  widget.onChanged(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _NavigationButtons extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final bool showBack;

  const _NavigationButtons({
    this.onBack,
    required this.onNext,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack)
          Expanded(
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimary,
                side: const BorderSide(color: kPrimary, width: 1.4),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
              ),
              child: const Text('Back',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        if (showBack) const SizedBox(width: 14),
        Expanded(
          child: ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              elevation: 0,
            ),
            child: const Text('Next',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: Colors.grey.shade200);
}




class PreferencePageWrapper extends StatefulWidget {
  final Widget child;
  final String userName;
  final String userEmail;
  final String userId;
  final int currentIndex;

  const PreferencePageWrapper({
    super.key,
    required this.child,
    required this.userName,
    required this.userEmail,
    required this.userId,
    required this.currentIndex,
  });

  @override
  State<PreferencePageWrapper> createState() => _PreferencePageWrapperState();
}

class _PreferencePageWrapperState extends State<PreferencePageWrapper> {
  late int _selectedNav;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _selectedNav = widget.currentIndex;
    _initializeCameras();
  }

  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (_) {}
  }

  Future<void> _navigateToScan() async {
    if (_cameras == null || _cameras!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cameras available')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ScanScreen(camera: _cameras!.first)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgCream,
      drawer: AppDrawer(
        userName: widget.userName,
        userEmail: widget.userEmail,
        userId: widget.userId,
        onScanTap: _navigateToScan,
      ),
      body: widget.child,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final navItems = [
      {'icon': Icons.home_outlined, 'label': 'Home'},
      {'icon': Icons.qr_code_scanner, 'label': 'Scan'},
      {'icon': Icons.bar_chart_outlined, 'label': 'Reports'},
      {'icon': Icons.favorite_outline, 'label': 'Health'},
      {'icon': Icons.settings_outlined, 'label': 'Settings'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2E8B72),
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (i) {
              final selected = i == _selectedNav;
              final isScan = i == 1;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedNav = i);
                  if (isScan) {
                    _navigateToScan();
                  } else if (i == 0) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomePage(
                          userData: {
                            'id': widget.userId,
                            'fullName': widget.userName,
                            'email': widget.userEmail,
                          },
                        ),
                      ),
                      (route) => false,
                    );
                  } else if (i == 2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportsScreen(
                          userId: widget.userId,
                          userName: widget.userName,
                          userEmail: widget.userEmail,
                        ),
                      ),
                    );
                  } else if (i == 3) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HealthDashboardScreen(
                          userId: widget.userId,
                          userName: widget.userName,
                          userEmail: widget.userEmail,
                        ),
                      ),
                    );
                  } else if (i == 4) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                          userId: widget.userId,
                          userName: widget.userName,
                          userEmail: widget.userEmail,
                        ),
                      ),
                    );
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isScan
                        ? Container(
                            width: 46,
                            height: 46,
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.15),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 2),
                            ),
                            child: const Icon(Icons.qr_code_scanner,
                                color: Colors.white, size: 23),
                          )
                        : Container(
                            padding: const EdgeInsets.all(6),
                            decoration: selected
                                ? BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(12))
                                : null,
                            child: Icon(
                              navItems[i]['icon'] as IconData,
                              color: selected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.62),
                              size: 23,
                            ),
                          ),
                    if (!isScan)
                      Text(
                        navItems[i]['label'] as String,
                        style: TextStyle(
                            fontSize: 9.5,
                            color: selected
                                ? Colors.white
                                : Colors.white.withOpacity(0.62)),
                      ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}




class PreferencesStartScreen extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String userId;
  final UserPreferences? preferences;

  const PreferencesStartScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userId,
    this.preferences,
  });

  @override
  Widget build(BuildContext context) {
    final profile = preferences ?? UserPreferences();
    const fixedRestrictions = {
      'No MSG',
      'No Artificial Colors',
      'No Preservatives',
      'No Artificial Sweeteners',
      'No Hydrogenated Oil',
      'No Added Sugar',
    };
    final dietary =
        profile.diets.where((item) => item.toLowerCase() != 'halal').toSet();
    final religious =
        profile.diets.where((item) => item.toLowerCase() == 'halal').toSet();
    final restrictions = <String>{
      ...profile.additives.where(fixedRestrictions.contains),
      ...profile.ingredients.where(fixedRestrictions.contains),
    };
    final customAvoided = <String>{
      ...profile.customIngredients,
      ...profile.customAvoidedIngredients,
      ...profile.ingredients.where((item) => !fixedRestrictions.contains(item)),
      ...profile.avoidedIngredients,
    }.toList();

    return SimplePreferencesEditor(
      title: 'My Preferences',
      subtitle:
          'Choose only what matters to you. These choices guide the score; they do not automatically reject every product with a small mismatch.',
      dietary: dietary,
      healthGoals: profile.nutritions,
      allergens: profile.allergens,
      restrictions: restrictions,
      religious: religious,
      customAvoidedIngredients: customAvoided,
      onBack: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          );
        }
      },
      onSave: (selection) async {
        profile
          ..diets = {...selection.dietary, ...selection.religious}
          ..customDiets = []
          ..dietImportance = 'Preferred'
          ..nutritions = Set.from(selection.healthGoals)
          ..customNutritions = []
          ..nutritionImportance = 'Preferred'
          ..allergens = Set.from(selection.allergens)
          ..customAllergens = []
          ..allergenImportance = 'Severe'
          ..additives = Set.from(selection.restrictions)
          ..customAdditives = []
          ..additiveImportance = 'Preferred'
          ..ingredients = {}
          ..customIngredients = List.from(selection.customAvoidedIngredients)
          ..ingredientImportance = 'Essential'
          ..healthConditions = {}
          ..customHealthConditions = []
          ..avoidedIngredients = {}
          ..customAvoidedIngredients = []
          ..preferredIngredients = {}
          ..customPreferredIngredients = []
          ..productCategories = {}
          ..customProductCategories = []
          ..recommendationSettings = {}
          ..customRecommendationSettings = [];

        return PreferenceApiService.savePreferences(
          userId: userId,
          userName: userName,
          preferences: profile,
        );
      },
    );
  }
}

class _PreferenceStepScaffold extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String userId;
  final PreferenceCategory category;
  final String title;
  final String subtitle;
  final String sectionLabel;
  final List<String> items;
  final Set<String> selectedItems;
  final List<String> customItems;
  final String importance;
  final String customTitle;
  final String customHint;
  final bool showBack;
  final VoidCallback? onBack;
  final VoidCallback Function(UserPreferences preferences)? nextBuilder;
  final UserPreferences preferences;
  final ValueChanged<Set<String>> onSelectedChanged;
  final ValueChanged<List<String>> onCustomChanged;
  final ValueChanged<String> onImportanceChanged;

  const _PreferenceStepScaffold({
    required this.userName,
    required this.userEmail,
    required this.userId,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.sectionLabel,
    required this.items,
    required this.selectedItems,
    required this.customItems,
    required this.importance,
    required this.customTitle,
    required this.customHint,
    required this.showBack,
    required this.onBack,
    required this.nextBuilder,
    required this.preferences,
    required this.onSelectedChanged,
    required this.onCustomChanged,
    required this.onImportanceChanged,
  });

  @override
  State<_PreferenceStepScaffold> createState() =>
      _PreferenceStepScaffoldState();
}

class _PreferenceStepScaffoldState extends State<_PreferenceStepScaffold> {
  late Set<String> _selected;
  late List<String> _custom;
  late String _importance;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedItems);
    _custom = List.from(widget.customItems);
    _importance = widget.importance;
  }

  @override
  Widget build(BuildContext context) {
    return PreferencePageWrapper(
      userName: widget.userName,
      userEmail: widget.userEmail,
      userId: widget.userId,
      currentIndex: 4,
      child: Scaffold(
        backgroundColor: kBgCream,
        body: SafeArea(
          child: Column(
            children: [
              _PrefsAppBar(
                  showBackButton: widget.showBack,
                  onBackPressed: widget.showBack ? widget.onBack : null),
              _CategoryHeader(title: widget.title, active: widget.category),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
                  child: _PreferenceFormCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.subtitle,
                            style: const TextStyle(
                                color: kTextMid, fontSize: 13, height: 1.35)),
                        const SizedBox(height: 18),
                        const _SectionDivider(),
                        const SizedBox(height: 16),
                        _ChipsSection(
                          sectionLabel: widget.sectionLabel,
                          items: widget.items,
                          selected: _selected,
                          onToggle: (v) {
                            setState(() {
                              if (_selected.contains(v)) {
                                _selected.remove(v);
                              } else {
                                _selected.add(v);
                              }
                            });
                            widget.onSelectedChanged(_selected);
                          },
                        ),
                        const SizedBox(height: 22),
                        _CustomInputSection(
                          title: widget.customTitle,
                          hint: widget.customHint,
                          addedItems: _custom,
                          onAddItem: (item) {
                            setState(() => _custom.add(item));
                            widget.onCustomChanged(_custom);
                          },
                          onRemoveItem: (item) {
                            setState(() => _custom.remove(item));
                            widget.onCustomChanged(_custom);
                          },
                        ),
                        const SizedBox(height: 22),
                        _ImportanceSection(
                          value: _importance,
                          onChanged: (value) {
                            setState(() => _importance = value);
                            widget.onImportanceChanged(value);
                          },
                        ),
                        const SizedBox(height: 26),
                        _NavigationButtons(
                          showBack: widget.showBack,
                          onBack: widget.onBack,
                          onNext: () {
                            final next =
                                widget.nextBuilder?.call(widget.preferences);
                            if (next != null) next();
                          },
                        ),
                      ],
                    ),
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




class AllergensPreferencesScreen extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String userId;
  final UserPreferences preferences;

  const AllergensPreferencesScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userId,
    required this.preferences,
  });

  @override
  Widget build(BuildContext context) {
    return _PreferenceStepScaffold(
      userName: userName,
      userEmail: userEmail,
      userId: userId,
      category: PreferenceCategory.allergens,
      title: 'Category- Allergens Preferences',
      subtitle:
          "Select allergens you want to avoid. Example: if you select Milk, scanned biscuits, chocolates, or drinks containing milk/lactose will show a warning.",
      sectionLabel: 'Common Allergens',
      items: const [
        'Peanuts',
        'Tree Nuts',
        'Milk',
        'Eggs',
        'Soy',
        'Wheat',
        'Fish',
        'Shellfish',
        'Sesame',
        'Mustard',
        'Celery',
        'Lupin'
      ],
      selectedItems: preferences.allergens,
      customItems: preferences.customAllergens,
      importance: preferences.allergenImportance,
      customTitle: 'Other Allergens If Any',
      customHint: 'Type to add custom allergens...',
      showBack: true,
      onBack: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      },
      preferences: preferences,
      onSelectedChanged: (v) => preferences.allergens = Set.from(v),
      onCustomChanged: (v) => preferences.customAllergens = List.from(v),
      onImportanceChanged: (v) => preferences.allergenImportance = v,
      nextBuilder: (prefs) => () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdditivesPreferencesScreen(
              userName: userName,
              userEmail: userEmail,
              userId: userId,
              preferences: prefs,
              openedFromAllergens: true,
            ),
          ),
        );
      },
    );
  }
}




class AdditivesPreferencesScreen extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String userId;
  final UserPreferences preferences;
  final bool openedFromAllergens;

  const AdditivesPreferencesScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userId,
    required this.preferences,
    this.openedFromAllergens = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!openedFromAllergens) {
      return AllergensPreferencesScreen(
          userName: userName,
          userEmail: userEmail,
          userId: userId,
          preferences: preferences);
    }

    return _PreferenceStepScaffold(
      userName: userName,
      userEmail: userEmail,
      userId: userId,
      category: PreferenceCategory.additive,
      title: 'Category- Additives Preferences',
      subtitle:
          "Choose additives you want to avoid or limit. Example: selecting Artificial Colors lowers recommendation scores for products with colorants.",
      sectionLabel: 'Additives',
      items: const [
        'No MSG',
        'No Artificial Colors',
        'No Preservatives',
        'No Aspartame',
        'No Nitrates',
        'No Sulphites',
        'No Artificial Sweeteners',
        'No Hydrogenated Oil',
        'No Gluten'
      ],
      selectedItems: preferences.additives,
      customItems: preferences.customAdditives,
      importance: preferences.additiveImportance,
      customTitle: 'Other Additives If Any',
      customHint: 'Type to add custom additives...',
      showBack: true,
      onBack: () => Navigator.pop(context),
      preferences: preferences,
      onSelectedChanged: (v) => preferences.additives = Set.from(v),
      onCustomChanged: (v) => preferences.customAdditives = List.from(v),
      onImportanceChanged: (v) => preferences.additiveImportance = v,
      nextBuilder: (prefs) => () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => DietPreferencesScreen(
                  userName: userName,
                  userEmail: userEmail,
                  userId: userId,
                  preferences: prefs)),
        );
      },
    );
  }
}




class DietPreferencesScreen extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String userId;
  final UserPreferences preferences;

  const DietPreferencesScreen(
      {super.key,
      required this.userName,
      required this.userEmail,
      required this.userId,
      required this.preferences});

  @override
  Widget build(BuildContext context) {
    return _PreferenceStepScaffold(
      userName: userName,
      userEmail: userEmail,
      userId: userId,
      category: PreferenceCategory.diet,
      title: 'Category- Diet Preferences',
      subtitle:
          'Select dietary rules used during product analysis. Example: Halal makes halal status essential before a product is recommended.',
      sectionLabel: 'Diet',
      items: const [
        'Halal',
        'Vegetarian',
        'Vegan',
        'Gluten Free',
        'Keto',
        'Low Sodium',
        'Diabetic Friendly',
        'Heart Friendly',
        'Weight Loss',
        'Low Fat',
        'High Protein'
      ],
      selectedItems: preferences.diets,
      customItems: preferences.customDiets,
      importance: preferences.dietImportance,
      customTitle: 'Other Diet If Any',
      customHint: 'Type to add custom diet...',
      showBack: true,
      onBack: () => Navigator.pop(context),
      preferences: preferences,
      onSelectedChanged: (v) => preferences.diets = Set.from(v),
      onCustomChanged: (v) => preferences.customDiets = List.from(v),
      onImportanceChanged: (v) => preferences.dietImportance = v,
      nextBuilder: (prefs) => () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => IngredientsPreferencesScreen(
                    userName: userName,
                    userEmail: userEmail,
                    userId: userId,
                    preferences: prefs)));
      },
    );
  }
}




class IngredientsPreferencesScreen extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String userId;
  final UserPreferences preferences;

  const IngredientsPreferencesScreen(
      {super.key,
      required this.userName,
      required this.userEmail,
      required this.userId,
      required this.preferences});

  @override
  Widget build(BuildContext context) {
    return _PreferenceStepScaffold(
      userName: userName,
      userEmail: userEmail,
      userId: userId,
      category: PreferenceCategory.ingredient,
      title: 'Category- Ingredients Preferences',
      subtitle:
          'Select ingredients you want to avoid or monitor. Example: Palm Oil or Added Sugar will be highlighted in ingredient breakdowns.',
      sectionLabel: 'Ingredients',
      items: const [
        'Added Sugar',
        'Corn Syrup',
        'Palm Oil',
        'Hydrogenated Oil',
        'Artificial Sweeteners',
        'Artificial Colors',
        'High Sodium',
        'Trans Fat',
        'Whole Grains Only'
      ],
      selectedItems: preferences.ingredients,
      customItems: preferences.customIngredients,
      importance: preferences.ingredientImportance,
      customTitle: 'Other Ingredients If Any',
      customHint: 'Type to add custom ingredients...',
      showBack: true,
      onBack: () => Navigator.pop(context),
      preferences: preferences,
      onSelectedChanged: (v) => preferences.ingredients = Set.from(v),
      onCustomChanged: (v) => preferences.customIngredients = List.from(v),
      onImportanceChanged: (v) => preferences.ingredientImportance = v,
      nextBuilder: (prefs) => () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => NutritionalPreferencesScreen(
                    userName: userName,
                    userEmail: userEmail,
                    userId: userId,
                    preferences: prefs)));
      },
    );
  }
}




class NutritionalPreferencesScreen extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String userId;
  final UserPreferences preferences;

  const NutritionalPreferencesScreen(
      {super.key,
      required this.userName,
      required this.userEmail,
      required this.userId,
      required this.preferences});

  @override
  Widget build(BuildContext context) {
    return _PreferenceStepScaffold(
      userName: userName,
      userEmail: userEmail,
      userId: userId,
      category: PreferenceCategory.nutrition,
      title: 'Category- Nutritional Preferences',
      subtitle:
          'Choose nutrition goals used to score products. Example: Low Sugar and Diabetic Friendly penalize high-sugar products.',
      sectionLabel: 'Nutrition goals',
      items: const [
        'Low Sugar',
        'No Added Sugar',
        'Low Sodium',
        'Low Calorie',
        'Low Fat',
        'Low Carb',
        'High Protein',
        'High Fiber',
        'Diabetic Friendly',
        'Heart Friendly',
        'Weight Loss',
        'Low Cholesterol',
        'Whole Grain'
      ],
      selectedItems: preferences.nutritions,
      customItems: preferences.customNutritions,
      importance: preferences.nutritionImportance,
      customTitle: 'Other Nutrition If Any',
      customHint: 'Type to add custom nutrients...',
      showBack: true,
      onBack: () => Navigator.pop(context),
      preferences: preferences,
      onSelectedChanged: (v) => preferences.nutritions = Set.from(v),
      onCustomChanged: (v) => preferences.customNutritions = List.from(v),
      onImportanceChanged: (v) => preferences.nutritionImportance = v,
      nextBuilder: (prefs) => () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ConfirmationScreen(
                    userName: userName,
                    userEmail: userEmail,
                    userId: userId,
                    preferences: prefs)));
      },
    );
  }
}




class AdvancedPreferencesScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String userId;
  final UserPreferences preferences;

  const AdvancedPreferencesScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userId,
    required this.preferences,
  });

  @override
  State<AdvancedPreferencesScreen> createState() =>
      _AdvancedPreferencesScreenState();
}

class _AdvancedPreferencesScreenState extends State<AdvancedPreferencesScreen> {
  void _toggle(
      Set<String> values, String item, ValueChanged<Set<String>> save) {
    setState(() {
      if (values.contains(item)) {
        values.remove(item);
      } else {
        values.add(item);
      }
      save(Set<String>.from(values));
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = widget.preferences;
    return PreferencePageWrapper(
      userName: widget.userName,
      userEmail: widget.userEmail,
      userId: widget.userId,
      currentIndex: 4,
      child: Scaffold(
        backgroundColor: kBgCream,
        body: SafeArea(
          child: Column(
            children: [
              _PrefsAppBar(onBackPressed: () => Navigator.pop(context)),
              const _CategoryHeader(
                title: 'Advanced Personalization',
                active: PreferenceCategory.advanced,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
                  child: _PreferenceFormCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'These settings explain your health profile, preferred product types, and how strict recommendations should be.',
                          style: TextStyle(
                              color: kTextMid, fontSize: 13, height: 1.35),
                        ),
                        const SizedBox(height: 18),
                        _AdvancedGroup(
                          title: 'Health conditions',
                          description:
                              'Examples: diabetes, hypertension, cholesterol, celiac disease. These increase caution for sugar, sodium, gluten, and fats.',
                          items: const [
                            'Diabetes',
                            'Hypertension',
                            'High Cholesterol',
                            'Heart Friendly',
                            'Kidney Care',
                            'Celiac Disease',
                            'Lactose Intolerance',
                            'Weight Loss'
                          ],
                          selected: prefs.healthConditions,
                          customItems: prefs.customHealthConditions,
                          importance: prefs.healthConditionImportance,
                          onToggle: (item) => _toggle(prefs.healthConditions,
                              item, (v) => prefs.healthConditions = v),
                          onCustomChanged: (v) =>
                              setState(() => prefs.customHealthConditions = v),
                          onImportanceChanged: (v) =>
                              prefs.healthConditionImportance = v,
                        ),
                        _AdvancedGroup(
                          title: 'Avoided ingredients',
                          description:
                              'These ingredients lower product scores and appear in warnings.',
                          items: const [
                            'Added Sugar',
                            'Palm Oil',
                            'Hydrogenated Oil',
                            'Artificial Sweeteners',
                            'Artificial Colors',
                            'High Sodium',
                            'Gelatin',
                            'Carmine'
                          ],
                          selected: prefs.avoidedIngredients,
                          customItems: prefs.customAvoidedIngredients,
                          importance: prefs.avoidedIngredientImportance,
                          onToggle: (item) => _toggle(prefs.avoidedIngredients,
                              item, (v) => prefs.avoidedIngredients = v),
                          onCustomChanged: (v) => setState(
                              () => prefs.customAvoidedIngredients = v),
                          onImportanceChanged: (v) =>
                              prefs.avoidedIngredientImportance = v,
                        ),
                        _AdvancedGroup(
                          title: 'Preferred ingredients',
                          description:
                              'Products with these ingredients receive positive notes and ranking boosts.',
                          items: const [
                            'Whole Grain',
                            'Oats',
                            'Almonds',
                            'Protein',
                            'Fiber',
                            'Low Fat Milk',
                            'Natural Flavors'
                          ],
                          selected: prefs.preferredIngredients,
                          customItems: prefs.customPreferredIngredients,
                          importance: prefs.preferredIngredientImportance,
                          onToggle: (item) => _toggle(
                              prefs.preferredIngredients,
                              item,
                              (v) => prefs.preferredIngredients = v),
                          onCustomChanged: (v) => setState(
                              () => prefs.customPreferredIngredients = v),
                          onImportanceChanged: (v) =>
                              prefs.preferredIngredientImportance = v,
                        ),
                        _AdvancedGroup(
                          title: 'Product categories',
                          description:
                              'Alternatives are ranked inside matching categories first.',
                          items: const [
                            'Biscuits & Cookies',
                            'Snacks',
                            'Dairy',
                            'Beverages',
                            'Cereals',
                            'Rice',
                            'Frozen Food',
                            'Staples'
                          ],
                          selected: prefs.productCategories,
                          customItems: prefs.customProductCategories,
                          importance: prefs.productCategoryImportance,
                          onToggle: (item) => _toggle(prefs.productCategories,
                              item, (v) => prefs.productCategories = v),
                          onCustomChanged: (v) =>
                              setState(() => prefs.customProductCategories = v),
                          onImportanceChanged: (v) =>
                              prefs.productCategoryImportance = v,
                        ),
                        _AdvancedGroup(
                          title: 'Recommendation settings',
                          description:
                              'Control how strict the AI should be when ranking products.',
                          items: const [
                            'Strict Mode',
                            'Prefer Halal Products',
                            'Prefer Low Calorie',
                            'Prefer High Protein',
                            'Prefer Same Category',
                            'Show Doubtful Halal Warnings',
                            'Family Safe Recommendations'
                          ],
                          selected: prefs.recommendationSettings,
                          customItems: prefs.customRecommendationSettings,
                          importance: prefs.recommendationSettingImportance,
                          onToggle: (item) => _toggle(
                              prefs.recommendationSettings,
                              item,
                              (v) => prefs.recommendationSettings = v),
                          onCustomChanged: (v) => setState(
                              () => prefs.customRecommendationSettings = v),
                          onImportanceChanged: (v) =>
                              prefs.recommendationSettingImportance = v,
                        ),
                        _NavigationButtons(
                          showBack: true,
                          onBack: () => Navigator.pop(context),
                          onNext: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ConfirmationScreen(
                                  userName: widget.userName,
                                  userEmail: widget.userEmail,
                                  userId: widget.userId,
                                  preferences: prefs,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
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

class _AdvancedGroup extends StatelessWidget {
  final String title;
  final String description;
  final List<String> items;
  final Set<String> selected;
  final List<String> customItems;
  final String importance;
  final ValueChanged<String> onToggle;
  final ValueChanged<List<String>> onCustomChanged;
  final ValueChanged<String> onImportanceChanged;

  const _AdvancedGroup({
    required this.title,
    required this.description,
    required this.items,
    required this.selected,
    required this.customItems,
    required this.importance,
    required this.onToggle,
    required this.onCustomChanged,
    required this.onImportanceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                color: kPrimary, fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style:
                const TextStyle(color: kTextMid, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          _ChipsSection(
            sectionLabel: 'Choose options',
            items: items,
            selected: selected,
            onToggle: onToggle,
          ),
          const SizedBox(height: 16),
          _CustomInputSection(
            title: 'Custom $title',
            hint: 'Add your own option...',
            addedItems: customItems,
            onAddItem: (item) => onCustomChanged([...customItems, item]),
            onRemoveItem: (item) {
              final next = List<String>.from(customItems)..remove(item);
              onCustomChanged(next);
            },
          ),
          const SizedBox(height: 16),
          _ImportanceSection(value: importance, onChanged: onImportanceChanged),
          const SizedBox(height: 8),
          const _SectionDivider(),
        ],
      ),
    );
  }
}

class ConfirmationScreen extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String userId;
  final UserPreferences preferences;

  const ConfirmationScreen(
      {super.key,
      required this.userName,
      required this.userEmail,
      required this.userId,
      required this.preferences});

  @override
  Widget build(BuildContext context) {
    return PreferencePageWrapper(
      userName: userName,
      userEmail: userEmail,
      userId: userId,
      currentIndex: 4,
      child: Scaffold(
        backgroundColor: kBgCream,
        body: SafeArea(
          child: Column(
            children: [
              _PrefsAppBar(onBackPressed: () => Navigator.pop(context)),
              const _ConfirmationHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
                  child: Column(
                    children: [
                      _buildSummarySection(
                          'Allergens',
                          preferences.allergens,
                          preferences.customAllergens,
                          preferences.allergenImportance),
                      _buildSummarySection(
                          'Additives',
                          preferences.additives,
                          preferences.customAdditives,
                          preferences.additiveImportance),
                      _buildSummarySection('Diet', preferences.diets,
                          preferences.customDiets, preferences.dietImportance),
                      _buildSummarySection(
                          'Ingredients',
                          preferences.ingredients,
                          preferences.customIngredients,
                          preferences.ingredientImportance),
                      _buildSummarySection(
                          'Nutrition',
                          preferences.nutritions,
                          preferences.customNutritions,
                          preferences.nutritionImportance),
                      _buildPreviewSection(),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);

                            final success =
                                await PreferenceApiService.savePreferences(
                              userId: userId,
                              userName: userName,
                              preferences: preferences,
                            );

                            if (!context.mounted) return;

                            if (success) {
                              messenger.showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Preferences saved. Future scans will use this profile.')),
                              );
                              await showDialog<void>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text(
                                      'Recommendation profile ready'),
                                  content: Text(_feedbackText()),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              navigator.pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (_) => const HomePage()),
                                (route) => false,
                              );
                            } else {
                              messenger.showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Failed to save preferences. Please try again.')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28)),
                            elevation: 0,
                          ),
                          child: const Text('Save & Start Scanning',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kPrimary,
                            side: const BorderSide(color: kPrimary, width: 1.4),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28)),
                          ),
                          child: const Text('Go Back to Edit',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w800)),
                        ),
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

  Widget _buildSummarySection(String title, Set<String> items,
      List<String> customItems, String importance) {
    final allItems = [...items, ...customItems];
    if (allItems.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 18,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: kPrimary),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: kChipUnselected,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  importance,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: kPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allItems
                .map((item) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: kPrimary,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        item,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    final avoid = [
      ...preferences.allergens,
      ...preferences.customAllergens,
      ...preferences.ingredients,
      ...preferences.customIngredients,
      ...preferences.avoidedIngredients,
      ...preferences.customAvoidedIngredients,
    ];
    final goals = [
      ...preferences.diets,
      ...preferences.customDiets,
      ...preferences.nutritions,
      ...preferences.customNutritions,
      ...preferences.preferredIngredients,
      ...preferences.customPreferredIngredients,
    ];
    final categories = [
      ...preferences.productCategories,
      ...preferences.customProductCategories,
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kChipUnselected,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommendation preview',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w900, color: kPrimary),
          ),
          const SizedBox(height: 10),
          _PreviewLine(
            label: 'Recommended products',
            value: categories.isEmpty
                ? 'Products with safe ingredients, matching nutrition, and no allergy conflicts.'
                : 'Best matches from ${categories.take(4).join(', ')}.',
          ),
          _PreviewLine(
            label: 'Products to avoid',
            value: avoid.isEmpty
                ? 'No avoid list yet.'
                : 'Products containing ${avoid.take(6).join(', ')}.',
          ),
          _PreviewLine(
            label: 'Ingredients matching goals',
            value: goals.isEmpty
                ? 'No positive goals selected yet.'
                : goals.take(6).join(', '),
          ),
        ],
      ),
    );
  }

  String _feedbackText() {
    final strict = preferences.recommendationSettings
        .any((item) => item.toLowerCase().contains('strict'));
    return strict
        ? 'The analyzer will apply your preferences strictly, check OCR ingredients, halal status, nutrition values, allergens, and category match before recommending products.'
        : 'The analyzer will balance your preferences with ingredient safety, nutrition values, halal status, and similar product category alternatives.';
  }
}

class _PreviewLine extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: kTextMid, fontSize: 12.5, height: 1.35),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                  color: kTextDark, fontWeight: FontWeight.w900),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
