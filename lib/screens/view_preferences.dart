import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';

import 'homepage.dart';
import 'my_preferences.dart' as preference_editor;
import 'scan_screen.dart';

// ─────────────────────────────────────────────
//  THEME CONSTANTS
// ─────────────────────────────────────────────
const Color kPrimary = Color(0xFF2D7D6F);
const Color kPrimaryLight = Color(0xFF3A9E8D);
const Color kBgCream = Color(0xFFF5F0E8);
const Color kCardBg = Color(0xFFFFFFFF);
const Color kChipSelected = Color(0xFF2D7D6F);
const Color kChipUnselected = Color(0xFFE6F3F0);
const Color kTextDark = Color(0xFF1A1A1A);
const Color kTextMid = Color(0xFF4A4A4A);
const Color kTextLight = Color(0xFF8A8A8A);

const String kApiBaseUrl = 'http://192.168.0.114:9000';

// ─────────────────────────────────────────────
//  USER PREFERENCES MODEL
// ─────────────────────────────────────────────
class UserPreferences {
  final List<String> allergens;
  final List<String> customAllergens;
  final String allergenImportance;

  final List<String> additives;
  final List<String> customAdditives;
  final String additiveImportance;

  final List<String> diets;
  final List<String> customDiets;
  final String dietImportance;

  final List<String> ingredients;
  final List<String> customIngredients;
  final String ingredientImportance;

  final List<String> nutritions;
  final List<String> customNutritions;
  final String nutritionImportance;
  final List<String> healthConditions;
  final List<String> customHealthConditions;
  final String healthConditionImportance;
  final List<String> avoidedIngredients;
  final List<String> customAvoidedIngredients;
  final String avoidedIngredientImportance;
  final List<String> preferredIngredients;
  final List<String> customPreferredIngredients;
  final String preferredIngredientImportance;
  final List<String> productCategories;
  final List<String> customProductCategories;
  final String productCategoryImportance;
  final List<String> recommendationSettings;
  final List<String> customRecommendationSettings;
  final String recommendationSettingImportance;

  const UserPreferences({
    this.allergens = const [],
    this.customAllergens = const [],
    this.allergenImportance = 'Essential',
    this.additives = const [],
    this.customAdditives = const [],
    this.additiveImportance = 'Essential',
    this.diets = const [],
    this.customDiets = const [],
    this.dietImportance = 'Essential',
    this.ingredients = const [],
    this.customIngredients = const [],
    this.ingredientImportance = 'Essential',
    this.nutritions = const [],
    this.customNutritions = const [],
    this.nutritionImportance = 'Preferred',
    this.healthConditions = const [],
    this.customHealthConditions = const [],
    this.healthConditionImportance = 'Essential',
    this.avoidedIngredients = const [],
    this.customAvoidedIngredients = const [],
    this.avoidedIngredientImportance = 'Essential',
    this.preferredIngredients = const [],
    this.customPreferredIngredients = const [],
    this.preferredIngredientImportance = 'Preferred',
    this.productCategories = const [],
    this.customProductCategories = const [],
    this.productCategoryImportance = 'Preferred',
    this.recommendationSettings = const [],
    this.customRecommendationSettings = const [],
    this.recommendationSettingImportance = 'Preferred',
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    List<String> listValue(String key) {
      final value = json[key];
      if (value is List) return value.map((e) => e.toString()).toList();
      return <String>[];
    }

    return UserPreferences(
      allergens: listValue('allergens'),
      customAllergens: listValue('customAllergens'),
      allergenImportance: json['allergenImportance']?.toString() ?? 'Essential',
      additives: listValue('additives'),
      customAdditives: listValue('customAdditives'),
      additiveImportance: json['additiveImportance']?.toString() ?? 'Essential',
      diets: listValue('diets'),
      customDiets: listValue('customDiets'),
      dietImportance: json['dietImportance']?.toString() ?? 'Essential',
      ingredients: listValue('ingredients'),
      customIngredients: listValue('customIngredients'),
      ingredientImportance:
          json['ingredientImportance']?.toString() ?? 'Essential',
      nutritions: listValue('nutritions'),
      customNutritions: listValue('customNutritions'),
      nutritionImportance:
          json['nutritionImportance']?.toString() ?? 'Preferred',
      healthConditions: listValue('healthConditions'),
      customHealthConditions: listValue('customHealthConditions'),
      healthConditionImportance:
          json['healthConditionImportance']?.toString() ?? 'Essential',
      avoidedIngredients: listValue('avoidedIngredients'),
      customAvoidedIngredients: listValue('customAvoidedIngredients'),
      avoidedIngredientImportance:
          json['avoidedIngredientImportance']?.toString() ?? 'Essential',
      preferredIngredients: listValue('preferredIngredients'),
      customPreferredIngredients: listValue('customPreferredIngredients'),
      preferredIngredientImportance:
          json['preferredIngredientImportance']?.toString() ?? 'Preferred',
      productCategories: listValue('productCategories'),
      customProductCategories: listValue('customProductCategories'),
      productCategoryImportance:
          json['productCategoryImportance']?.toString() ?? 'Preferred',
      recommendationSettings: listValue('recommendationSettings'),
      customRecommendationSettings: listValue('customRecommendationSettings'),
      recommendationSettingImportance:
          json['recommendationSettingImportance']?.toString() ?? 'Preferred',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allergens': allergens,
      'customAllergens': customAllergens,
      'allergenImportance': allergenImportance,
      'additives': additives,
      'customAdditives': customAdditives,
      'additiveImportance': additiveImportance,
      'diets': diets,
      'customDiets': customDiets,
      'dietImportance': dietImportance,
      'ingredients': ingredients,
      'customIngredients': customIngredients,
      'ingredientImportance': ingredientImportance,
      'nutritions': nutritions,
      'customNutritions': customNutritions,
      'nutritionImportance': nutritionImportance,
      'healthConditions': healthConditions,
      'customHealthConditions': customHealthConditions,
      'healthConditionImportance': healthConditionImportance,
      'avoidedIngredients': avoidedIngredients,
      'customAvoidedIngredients': customAvoidedIngredients,
      'avoidedIngredientImportance': avoidedIngredientImportance,
      'preferredIngredients': preferredIngredients,
      'customPreferredIngredients': customPreferredIngredients,
      'preferredIngredientImportance': preferredIngredientImportance,
      'productCategories': productCategories,
      'customProductCategories': customProductCategories,
      'productCategoryImportance': productCategoryImportance,
      'recommendationSettings': recommendationSettings,
      'customRecommendationSettings': customRecommendationSettings,
      'recommendationSettingImportance': recommendationSettingImportance,
    };
  }

  UserPreferences copyWith({
    List<String>? allergens,
    List<String>? customAllergens,
    String? allergenImportance,
    List<String>? additives,
    List<String>? customAdditives,
    String? additiveImportance,
    List<String>? diets,
    List<String>? customDiets,
    String? dietImportance,
    List<String>? ingredients,
    List<String>? customIngredients,
    String? ingredientImportance,
    List<String>? nutritions,
    List<String>? customNutritions,
    String? nutritionImportance,
    List<String>? healthConditions,
    List<String>? customHealthConditions,
    String? healthConditionImportance,
    List<String>? avoidedIngredients,
    List<String>? customAvoidedIngredients,
    String? avoidedIngredientImportance,
    List<String>? preferredIngredients,
    List<String>? customPreferredIngredients,
    String? preferredIngredientImportance,
    List<String>? productCategories,
    List<String>? customProductCategories,
    String? productCategoryImportance,
    List<String>? recommendationSettings,
    List<String>? customRecommendationSettings,
    String? recommendationSettingImportance,
  }) {
    return UserPreferences(
      allergens: allergens ?? this.allergens,
      customAllergens: customAllergens ?? this.customAllergens,
      allergenImportance: allergenImportance ?? this.allergenImportance,
      additives: additives ?? this.additives,
      customAdditives: customAdditives ?? this.customAdditives,
      additiveImportance: additiveImportance ?? this.additiveImportance,
      diets: diets ?? this.diets,
      customDiets: customDiets ?? this.customDiets,
      dietImportance: dietImportance ?? this.dietImportance,
      ingredients: ingredients ?? this.ingredients,
      customIngredients: customIngredients ?? this.customIngredients,
      ingredientImportance: ingredientImportance ?? this.ingredientImportance,
      nutritions: nutritions ?? this.nutritions,
      customNutritions: customNutritions ?? this.customNutritions,
      nutritionImportance: nutritionImportance ?? this.nutritionImportance,
      healthConditions: healthConditions ?? this.healthConditions,
      customHealthConditions:
          customHealthConditions ?? this.customHealthConditions,
      healthConditionImportance:
          healthConditionImportance ?? this.healthConditionImportance,
      avoidedIngredients: avoidedIngredients ?? this.avoidedIngredients,
      customAvoidedIngredients:
          customAvoidedIngredients ?? this.customAvoidedIngredients,
      avoidedIngredientImportance:
          avoidedIngredientImportance ?? this.avoidedIngredientImportance,
      preferredIngredients: preferredIngredients ?? this.preferredIngredients,
      customPreferredIngredients:
          customPreferredIngredients ?? this.customPreferredIngredients,
      preferredIngredientImportance:
          preferredIngredientImportance ?? this.preferredIngredientImportance,
      productCategories: productCategories ?? this.productCategories,
      customProductCategories:
          customProductCategories ?? this.customProductCategories,
      productCategoryImportance:
          productCategoryImportance ?? this.productCategoryImportance,
      recommendationSettings:
          recommendationSettings ?? this.recommendationSettings,
      customRecommendationSettings:
          customRecommendationSettings ?? this.customRecommendationSettings,
      recommendationSettingImportance: recommendationSettingImportance ??
          this.recommendationSettingImportance,
    );
  }
}

// ─────────────────────────────────────────────
//  API SERVICE
// ─────────────────────────────────────────────
class PreferenceApiService {
  static String _tokenForUser(String userId) => 'dummy-token-$userId';

  static Map<String, String> _headers(String userId) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_tokenForUser(userId)}',
    };
  }

  static Future<UserPreferences?> getPreferences({
    required String userId,
  }) async {
    final uri = Uri.parse('$kApiBaseUrl/api/preferences/$userId');

    final response = await http.get(uri, headers: _headers(userId));

    if (response.statusCode != 200) {
      throw Exception('Failed to load preferences');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['preferences'];

    if (data == null) return null;
    if (data is! Map<String, dynamic>) return null;

    return UserPreferences.fromJson(data);
  }

  static Future<UserPreferences?> updatePreferences({
    required String userId,
    required UserPreferences preferences,
  }) async {
    final uri = Uri.parse('$kApiBaseUrl/api/preferences/$userId');

    final response = await http.put(
      uri,
      headers: _headers(userId),
      body: jsonEncode(preferences.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update preferences');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['preferences'];

    if (data == null || data is! Map<String, dynamic>) return preferences;
    return UserPreferences.fromJson(data);
  }

  static Future<void> deletePreferences({
    required String userId,
  }) async {
    final uri = Uri.parse('$kApiBaseUrl/api/preferences/$userId');

    final response = await http.delete(uri, headers: _headers(userId));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete preferences');
    }
  }
}

// ─────────────────────────────────────────────
//  VIEW PREFERENCES SCREEN
// ─────────────────────────────────────────────
class ViewPreferencesScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String userId;

  const ViewPreferencesScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userId,
  });

  @override
  State<ViewPreferencesScreen> createState() => _ViewPreferencesScreenState();
}

class _ViewPreferencesScreenState extends State<ViewPreferencesScreen> {
  late Future<UserPreferences?> _preferencesFuture;

  int _selectedNav = 4;
  List<CameraDescription>? _cameras;
  bool _actionLoading = false;

  static const Color _teal = Color(0xFF2E8B72);

  @override
  void initState() {
    super.initState();
    _preferencesFuture =
        PreferenceApiService.getPreferences(userId: widget.userId);
    _initializeCameras();
  }

  Future<void> _refreshPreferences() async {
    setState(() {
      _preferencesFuture =
          PreferenceApiService.getPreferences(userId: widget.userId);
    });
    await _preferencesFuture;
  }

  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      debugPrint('Error initializing cameras: $e');
    }
  }

  Future<void> _navigateToScan() async {
    if (_cameras == null || _cameras!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No cameras available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanScreen(camera: _cameras!.first),
      ),
    );
  }

  Future<void> _openEditSheet(UserPreferences prefs) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => preference_editor.PreferencesStartScreen(
          userName: widget.userName,
          userEmail: widget.userEmail,
          userId: widget.userId,
          preferences:
              preference_editor.UserPreferences.fromJson(prefs.toJson()),
        ),
      ),
    );

    if (updated == true) {
      await _refreshPreferences();
    }
  }

  Future<void> _confirmDeletePreferences() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Preferences?'),
        content: const Text(
          'This will delete your saved preferences. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _actionLoading = true);

    try {
      await PreferenceApiService.deletePreferences(userId: widget.userId);
      await _refreshPreferences();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences deleted successfully.'),
          backgroundColor: kPrimary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgCream,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _ViewPrefsAppBar(
                        onBackPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const HomePage()),
                            (route) => false,
                          );
                        },
                        onRefreshPressed: _refreshPreferences,
                      ),
                      const _ViewHeader(),
                      Expanded(
                        child: FutureBuilder<UserPreferences?>(
                          future: _preferencesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child:
                                    CircularProgressIndicator(color: kPrimary),
                              );
                            }

                            if (snapshot.hasError) {
                              return _ErrorState(
                                message:
                                    'Unable to load your preferences. Please check server connection.',
                                onRetry: _refreshPreferences,
                              );
                            }

                            final prefs = snapshot.data;

                            if (prefs == null || _isPreferenceEmpty(prefs)) {
                              return _EmptyState(
                                  onRefresh: _refreshPreferences);
                            }

                            return RefreshIndicator(
                              color: kPrimary,
                              onRefresh: _refreshPreferences,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 18, 16, 28),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello ${widget.userName}, here are your saved preferences.',
                                      style: const TextStyle(
                                        color: kTextMid,
                                        fontSize: 13.5,
                                        height: 1.35,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _actionLoading
                                                ? null
                                                : () => _openEditSheet(prefs),
                                            icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 18),
                                            label:
                                                const Text('Edit Preferences'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: kPrimary,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 13),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _actionLoading
                                                ? null
                                                : _confirmDeletePreferences,
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                size: 18),
                                            label: const Text('Delete'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              side: BorderSide(
                                                  color: Colors.red
                                                      .withOpacity(0.45)),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 13),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    _PreferenceViewCard(
                                      icon: Icons.restaurant_menu_outlined,
                                      title: 'Dietary Preferences',
                                      importance: '',
                                      items: [
                                        ...prefs.diets.where((item) =>
                                            item.toLowerCase() != 'halal'),
                                        ...prefs.customDiets
                                      ],
                                    ),
                                    _PreferenceViewCard(
                                      icon: Icons.monitor_heart_outlined,
                                      title: 'Health Goals',
                                      importance: '',
                                      items: [
                                        ...prefs.nutritions,
                                        ...prefs.customNutritions
                                      ],
                                    ),
                                    _PreferenceViewCard(
                                      icon: Icons.health_and_safety_outlined,
                                      title: 'Allergies & Restrictions',
                                      importance: prefs.allergenImportance,
                                      items: [
                                        ...prefs.allergens,
                                        ...prefs.customAllergens,
                                        ...prefs.additives,
                                        ...prefs.customAdditives,
                                        ...prefs.ingredients,
                                        ...prefs.customIngredients,
                                        ...prefs.avoidedIngredients,
                                        ...prefs.customAvoidedIngredients
                                      ],
                                    ),
                                    _PreferenceViewCard(
                                      icon: Icons.verified_user_outlined,
                                      title: 'Religious Preferences',
                                      importance: '',
                                      items: [
                                        ...prefs.diets.where((item) =>
                                            item.toLowerCase() == 'halal'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                _buildBottomNav(),
              ],
            ),
            if (_actionLoading)
              Container(
                color: Colors.black.withOpacity(0.18),
                child: const Center(
                  child: CircularProgressIndicator(color: kPrimary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isPreferenceEmpty(UserPreferences p) {
    return p.allergens.isEmpty &&
        p.customAllergens.isEmpty &&
        p.additives.isEmpty &&
        p.customAdditives.isEmpty &&
        p.diets.isEmpty &&
        p.customDiets.isEmpty &&
        p.ingredients.isEmpty &&
        p.customIngredients.isEmpty &&
        p.nutritions.isEmpty &&
        p.customNutritions.isEmpty;
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
        color: _teal,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (i) {
              final selected = i == _selectedNav;
              final isScan = i == 1;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedNav = i);

                  if (i == 0) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                      (route) => false,
                    );
                  } else if (isScan) {
                    _navigateToScan();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${navItems[i]['label']} feature coming soon!'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isScan
                        ? Container(
                            width: 48,
                            height: 48,
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner,
                              color: Colors.white,
                              size: 24,
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.all(6),
                            decoration: selected
                                ? BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  )
                                : null,
                            child: Icon(
                              navItems[i]['icon'] as IconData,
                              color: selected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.6),
                              size: 24,
                            ),
                          ),
                    if (!isScan)
                      Text(
                        navItems[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: selected
                              ? Colors.white
                              : Colors.white.withOpacity(0.6),
                        ),
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

// ─────────────────────────────────────────────
//  WIDGETS
// ─────────────────────────────────────────────
class _ViewPrefsAppBar extends StatelessWidget {
  final VoidCallback onBackPressed;
  final Future<void> Function() onRefreshPressed;

  const _ViewPrefsAppBar({
    required this.onBackPressed,
    required this.onRefreshPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBgCream,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: kPrimary, size: 28),
              onPressed: onBackPressed,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'My Saved Preferences',
                style: TextStyle(
                  color: kPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              icon:
                  const Icon(Icons.refresh_rounded, color: kPrimary, size: 24),
              onPressed: onRefreshPressed,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewHeader extends StatelessWidget {
  const _ViewHeader();

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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: kBgCream,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.verified_user_outlined,
                color: kPrimary, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Food Safety Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'View, edit, or delete your saved preferences.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceViewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String importance;
  final List<String> items;

  const _PreferenceViewCard({
    required this.icon,
    required this.title,
    required this.importance,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final cleanItems = items.where((e) => e.trim().isNotEmpty).toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kChipUnselected,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: kPrimary, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: kTextDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (importance.trim().isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    importance,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (cleanItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: kBgCream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'No preferences selected in this category.',
                style: TextStyle(
                  color: kTextLight,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cleanItems.map((item) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(
                    color: kChipUnselected,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimary.withOpacity(0.08)),
                  ),
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: kTextDark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _EditPreferencesSheet extends StatefulWidget {
  final UserPreferences preferences;

  const _EditPreferencesSheet({required this.preferences});

  @override
  State<_EditPreferencesSheet> createState() => _EditPreferencesSheetState();
}

class _EditPreferencesSheetState extends State<_EditPreferencesSheet> {
  final List<String> _importanceOptions = const [
    'Essential',
    'Preferred',
    'Avoid'
  ];

  late List<String> allergens;
  late List<String> customAllergens;
  late String allergenImportance;

  late List<String> additives;
  late List<String> customAdditives;
  late String additiveImportance;

  late List<String> diets;
  late List<String> customDiets;
  late String dietImportance;

  late List<String> ingredients;
  late List<String> customIngredients;
  late String ingredientImportance;

  late List<String> nutritions;
  late List<String> customNutritions;
  late String nutritionImportance;
  late List<String> healthConditions;
  late List<String> customHealthConditions;
  late String healthConditionImportance;
  late List<String> avoidedIngredients;
  late List<String> customAvoidedIngredients;
  late String avoidedIngredientImportance;
  late List<String> preferredIngredients;
  late List<String> customPreferredIngredients;
  late String preferredIngredientImportance;
  late List<String> productCategories;
  late List<String> customProductCategories;
  late String productCategoryImportance;
  late List<String> recommendationSettings;
  late List<String> customRecommendationSettings;
  late String recommendationSettingImportance;

  @override
  void initState() {
    super.initState();
    allergens = List<String>.from(widget.preferences.allergens);
    customAllergens = List<String>.from(widget.preferences.customAllergens);
    allergenImportance = _safeImportance(widget.preferences.allergenImportance);

    additives = List<String>.from(widget.preferences.additives);
    customAdditives = List<String>.from(widget.preferences.customAdditives);
    additiveImportance = _safeImportance(widget.preferences.additiveImportance);

    diets = List<String>.from(widget.preferences.diets);
    customDiets = List<String>.from(widget.preferences.customDiets);
    dietImportance = _safeImportance(widget.preferences.dietImportance);

    ingredients = List<String>.from(widget.preferences.ingredients);
    customIngredients = List<String>.from(widget.preferences.customIngredients);
    ingredientImportance =
        _safeImportance(widget.preferences.ingredientImportance);

    nutritions = List<String>.from(widget.preferences.nutritions);
    customNutritions = List<String>.from(widget.preferences.customNutritions);
    nutritionImportance =
        _safeImportance(widget.preferences.nutritionImportance);
    healthConditions = List<String>.from(widget.preferences.healthConditions);
    customHealthConditions =
        List<String>.from(widget.preferences.customHealthConditions);
    healthConditionImportance =
        _safeImportance(widget.preferences.healthConditionImportance);
    avoidedIngredients =
        List<String>.from(widget.preferences.avoidedIngredients);
    customAvoidedIngredients =
        List<String>.from(widget.preferences.customAvoidedIngredients);
    avoidedIngredientImportance =
        _safeImportance(widget.preferences.avoidedIngredientImportance);
    preferredIngredients =
        List<String>.from(widget.preferences.preferredIngredients);
    customPreferredIngredients =
        List<String>.from(widget.preferences.customPreferredIngredients);
    preferredIngredientImportance =
        _safeImportance(widget.preferences.preferredIngredientImportance);
    productCategories = List<String>.from(widget.preferences.productCategories);
    customProductCategories =
        List<String>.from(widget.preferences.customProductCategories);
    productCategoryImportance =
        _safeImportance(widget.preferences.productCategoryImportance);
    recommendationSettings =
        List<String>.from(widget.preferences.recommendationSettings);
    customRecommendationSettings =
        List<String>.from(widget.preferences.customRecommendationSettings);
    recommendationSettingImportance =
        _safeImportance(widget.preferences.recommendationSettingImportance);
  }

  String _safeImportance(String value) {
    return _importanceOptions.contains(value) ? value : 'Preferred';
  }

  UserPreferences _buildUpdatedPreferences() {
    return UserPreferences(
      allergens: allergens,
      customAllergens: customAllergens,
      allergenImportance: allergenImportance,
      additives: additives,
      customAdditives: customAdditives,
      additiveImportance: additiveImportance,
      diets: diets,
      customDiets: customDiets,
      dietImportance: dietImportance,
      ingredients: ingredients,
      customIngredients: customIngredients,
      ingredientImportance: ingredientImportance,
      nutritions: nutritions,
      customNutritions: customNutritions,
      nutritionImportance: nutritionImportance,
      healthConditions: healthConditions,
      customHealthConditions: customHealthConditions,
      healthConditionImportance: healthConditionImportance,
      avoidedIngredients: avoidedIngredients,
      customAvoidedIngredients: customAvoidedIngredients,
      avoidedIngredientImportance: avoidedIngredientImportance,
      preferredIngredients: preferredIngredients,
      customPreferredIngredients: customPreferredIngredients,
      preferredIngredientImportance: preferredIngredientImportance,
      productCategories: productCategories,
      customProductCategories: customProductCategories,
      productCategoryImportance: productCategoryImportance,
      recommendationSettings: recommendationSettings,
      customRecommendationSettings: customRecommendationSettings,
      recommendationSettingImportance: recommendationSettingImportance,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: kBgCream,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: kTextLight.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: kTextDark),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Edit Preferences',
                    style: TextStyle(
                      color: kTextDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                  children: [
                    _EditablePreferenceSection(
                      title: 'Allergens',
                      icon: Icons.no_drinks_outlined,
                      items: allergens,
                      customItems: customAllergens,
                      importance: allergenImportance,
                      importanceOptions: _importanceOptions,
                      onImportanceChanged: (v) =>
                          setState(() => allergenImportance = v),
                      onChanged: () => setState(() {}),
                    ),
                    _EditablePreferenceSection(
                      title: 'Additives',
                      icon: Icons.grass_outlined,
                      items: additives,
                      customItems: customAdditives,
                      importance: additiveImportance,
                      importanceOptions: _importanceOptions,
                      onImportanceChanged: (v) =>
                          setState(() => additiveImportance = v),
                      onChanged: () => setState(() {}),
                    ),
                    _EditablePreferenceSection(
                      title: 'Diet',
                      icon: Icons.eco_outlined,
                      items: diets,
                      customItems: customDiets,
                      importance: dietImportance,
                      importanceOptions: _importanceOptions,
                      onImportanceChanged: (v) =>
                          setState(() => dietImportance = v),
                      onChanged: () => setState(() {}),
                    ),
                    _EditablePreferenceSection(
                      title: 'Ingredients',
                      icon: Icons.inventory_2_outlined,
                      items: ingredients,
                      customItems: customIngredients,
                      importance: ingredientImportance,
                      importanceOptions: _importanceOptions,
                      onImportanceChanged: (v) =>
                          setState(() => ingredientImportance = v),
                      onChanged: () => setState(() {}),
                    ),
                    _EditablePreferenceSection(
                      title: 'Nutrition',
                      icon: Icons.grid_view_outlined,
                      items: nutritions,
                      customItems: customNutritions,
                      importance: nutritionImportance,
                      importanceOptions: _importanceOptions,
                      onImportanceChanged: (v) =>
                          setState(() => nutritionImportance = v),
                      onChanged: () => setState(() {}),
                    ),
                    _EditablePreferenceSection(
                      title: 'Health Conditions',
                      icon: Icons.medical_information_outlined,
                      items: healthConditions,
                      customItems: customHealthConditions,
                      importance: healthConditionImportance,
                      importanceOptions: _importanceOptions,
                      onImportanceChanged: (v) =>
                          setState(() => healthConditionImportance = v),
                      onChanged: () => setState(() {}),
                    ),
                    _EditablePreferenceSection(
                      title: 'Avoided Ingredients',
                      icon: Icons.block_outlined,
                      items: avoidedIngredients,
                      customItems: customAvoidedIngredients,
                      importance: avoidedIngredientImportance,
                      importanceOptions: _importanceOptions,
                      onImportanceChanged: (v) =>
                          setState(() => avoidedIngredientImportance = v),
                      onChanged: () => setState(() {}),
                    ),
                    _EditablePreferenceSection(
                      title: 'Preferred Ingredients',
                      icon: Icons.check_circle_outline,
                      items: preferredIngredients,
                      customItems: customPreferredIngredients,
                      importance: preferredIngredientImportance,
                      importanceOptions: _importanceOptions,
                      onImportanceChanged: (v) =>
                          setState(() => preferredIngredientImportance = v),
                      onChanged: () => setState(() {}),
                    ),
                    _EditablePreferenceSection(
                      title: 'Product Categories',
                      icon: Icons.category_outlined,
                      items: productCategories,
                      customItems: customProductCategories,
                      importance: productCategoryImportance,
                      importanceOptions: _importanceOptions,
                      onImportanceChanged: (v) =>
                          setState(() => productCategoryImportance = v),
                      onChanged: () => setState(() {}),
                    ),
                    _EditablePreferenceSection(
                      title: 'Recommendation Settings',
                      icon: Icons.tune_outlined,
                      items: recommendationSettings,
                      customItems: customRecommendationSettings,
                      importance: recommendationSettingImportance,
                      importanceOptions: _importanceOptions,
                      onImportanceChanged: (v) =>
                          setState(() => recommendationSettingImportance = v),
                      onChanged: () => setState(() {}),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                decoration: BoxDecoration(
                  color: kBgCream,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kTextDark,
                          side: BorderSide(color: kTextLight.withOpacity(0.35)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context, _buildUpdatedPreferences()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EditablePreferenceSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final List<String> customItems;
  final String importance;
  final List<String> importanceOptions;
  final ValueChanged<String> onImportanceChanged;
  final VoidCallback onChanged;

  const _EditablePreferenceSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.customItems,
    required this.importance,
    required this.importanceOptions,
    required this.onImportanceChanged,
    required this.onChanged,
  });

  Future<void> _addCustomItem(BuildContext context) async {
    final controller = TextEditingController();

    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add $title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter item name',
            filled: true,
            fillColor: kBgCream,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (value == null || value.trim().isEmpty) return;
    if (!customItems.contains(value.trim()) && !items.contains(value.trim())) {
      customItems.add(value.trim());
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final allItems = [
      ...items.map((e) => _EditableItem(value: e, isCustom: false)),
      ...customItems.map((e) => _EditableItem(value: e, isCustom: true)),
    ].where((e) => e.value.trim().isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kChipUnselected,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: kPrimary, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: kTextDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(
                width: 128,
                child: DropdownButtonFormField<String>(
                  value: importance,
                  isDense: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: kBgCream,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: importanceOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(
                        option,
                        style: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) onImportanceChanged(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (allItems.isEmpty)
            const Text(
              'No items added.',
              style: TextStyle(color: kTextLight, fontWeight: FontWeight.w600),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allItems.map((item) {
                return InputChip(
                  label: Text(item.value),
                  labelStyle: const TextStyle(
                    color: kTextDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                  backgroundColor: kChipUnselected,
                  deleteIcon: const Icon(Icons.close_rounded, size: 17),
                  onDeleted: () {
                    if (item.isCustom) {
                      customItems.remove(item.value);
                    } else {
                      items.remove(item.value);
                    }
                    onChanged();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                    side: BorderSide(color: kPrimary.withOpacity(0.08)),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _addCustomItem(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('Add $title'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimary,
                side: BorderSide(color: kPrimary.withOpacity(0.25)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableItem {
  final String value;
  final bool isCustom;

  const _EditableItem({required this.value, required this.isCustom});
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(22),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.folder_off_outlined,
              color: kPrimary.withOpacity(0.75), size: 70),
          const SizedBox(height: 18),
          const Text(
            'No Preferences Found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kTextDark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You have not saved any preferences yet. Please set your preferences first.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kTextMid, fontSize: 13.5, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.red.shade400, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: kTextDark,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: kTextMid, fontSize: 13.5, height: 1.35),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              child: const Text('Retry',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
