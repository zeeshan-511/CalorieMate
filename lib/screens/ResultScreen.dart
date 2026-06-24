import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'login_page.dart';
import 'family_profile.dart';
import 'api_service.dart';
import 'analysis_report_screen.dart';
import 'reports_screen.dart';
import 'health_dashboard_screen.dart';
import '../config/app_config.dart';
import '../services/session_service.dart';
import 'ScanHistory.dart';
import 'Setting.dart';
import 'my_preferences.dart' as myprefs;
import 'view_preferences.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const ResultScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int _selectedNav = 2;
  String userName = '';
  String userEmail = '';
  String userId = '';

  bool _historySaved = false;
  bool _isCleaningOcr = true;
  String _ocrError = '';
  List<String> _cleanedIngredients = [];
  String _scanHistoryId = '';
  bool _isLoadingIntelligence = false;
  String _intelligenceError = '';
  Map<String, dynamic>? _intelligence;

  static String get apiBaseUrl => AppConfig.apiBaseUrl;

  static const Color _teal = Color(0xFF2E8B72);
  static const Color _bg = Color(0xFFF5F9F7);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedUserName = prefs.getString('user_name') ?? 'Guest User';
    final savedUserEmail = prefs.getString('user_email') ?? 'guest@example.com';
    final savedUserId = prefs.getString('user_id') ?? '';

    if (!mounted) return;

    setState(() {
      userName = savedUserName;
      userEmail = savedUserEmail;
      userId = savedUserId;
    });

    if (savedUserId.isNotEmpty) {
      await _saveScanHistory(savedUserId);
    } else {
      debugPrint(
        'Scan history not saved: user_id not found in SharedPreferences',
      );
    }
  }

  Future<void> _saveScanHistory(String currentUserId) async {
    if (_historySaved) return;

    _historySaved = true;

    try {
      final rawIngredients = _extractIngredients(widget.data['ingredients']);
      final rawOcrText = _getRawOcrText(widget.data);

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/scan-history'),
        headers: const {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer dummy-token',
        },
        body: jsonEncode({
          'userId': currentUserId,
          'userName': userName,
          'userEmail': userEmail,
          'ingredients': rawIngredients,
          'ocrText': rawOcrText,
          'scannedText': rawOcrText,
          'scanResult': {
            ...widget.data,
            'text': rawOcrText,
            'ocrText': rawOcrText,
          },
        }),
      );

      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode == 200 || response.statusCode == 201) {
        final history = decoded['history'] as Map<String, dynamic>?;
        final cleaned = _extractIngredients(history?['ingredients']);
        final savedHistoryId = history?['_id']?.toString() ?? '';

        if (!mounted) return;
        setState(() {
          _cleanedIngredients = cleaned;
          _scanHistoryId = savedHistoryId;
          _ocrError = '';
          _isCleaningOcr = false;
        });

        if (cleaned.isNotEmpty) {
          await _loadProductIntelligence(
            currentUserId: currentUserId,
            ingredients: cleaned,
            scanHistoryId: savedHistoryId,
            rawOcrText: rawOcrText,
          );
        }

        debugPrint('Scan history saved successfully with cleaned ingredients');
      } else if (response.statusCode == 422) {
        _historySaved = false;

        if (!mounted) return;
        setState(() {
          _cleanedIngredients = [];
          _ocrError = decoded['message']?.toString() ??
              'This does not look like a food ingredients label. Please scan the product ingredients section only.';
          _isCleaningOcr = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_ocrError), backgroundColor: Colors.red),
        );

        debugPrint(
          'OCR validation failed: ${response.statusCode} ${response.body}',
        );
      } else {
        _historySaved = false;

        if (!mounted) return;
        setState(() {
          _cleanedIngredients = [];
          _ocrError = decoded['message']?.toString() ??
              'Failed to process scan. Please try again.';
          _isCleaningOcr = false;
        });

        debugPrint(
          'Scan history save failed: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      _historySaved = false;

      if (!mounted) return;
      setState(() {
        _cleanedIngredients = [];
        _ocrError =
            'Server connection failed. Please check backend and WiFi IP.';
        _isCleaningOcr = false;
      });

      debugPrint('Scan history save error: $e');
    }
  }

  String _getRawOcrText(Map<String, dynamic> data) {
    final possibleFields = [
      data['ocrText'],
      data['scannedText'],
      data['text'],
      data['rawText'],
      data['recognizedText'],
      data['fullText'],
      data['ingredients'],
    ];

    for (final value in possibleFields) {
      if (value == null) continue;

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }

      if (value is List && value.isNotEmpty) {
        return value.map((e) => e.toString()).join(', ');
      }
    }

    return '';
  }

  List<String> _extractIngredients(dynamic rawIngredients) {
    if (rawIngredients == null) return [];

    if (rawIngredients is List) {
      return rawIngredients
          .map((item) {
            if (item == null) return '';
            if (item is String) return item;
            if (item is Map) {
              return (item['name'] ??
                      item['text'] ??
                      item['ingredient'] ??
                      item['value'] ??
                      '')
                  .toString();
            }
            return item.toString();
          })
          .where((e) => e.trim().isNotEmpty)
          .map((e) => e.trim())
          .toList();
    }

    if (rawIngredients is String) {
      return rawIngredients
          .split(RegExp(r'[,;\n]'))
          .where((e) => e.trim().isNotEmpty)
          .map((e) => e.trim())
          .toList();
    }

    return [];
  }

  Future<void> _loadProductIntelligence({
    required String currentUserId,
    required List<String> ingredients,
    String scanHistoryId = '',
    String rawOcrText = '',
  }) async {
    if (currentUserId.isEmpty || ingredients.isEmpty) return;

    if (mounted) {
      setState(() {
        _isLoadingIntelligence = true;
        _intelligenceError = '';
      });
    }

    try {
      final result = await ApiService.analyzeScannedProduct(
        userId: currentUserId,
        ingredients: ingredients,
        scanHistoryId:
            scanHistoryId.isNotEmpty ? scanHistoryId : _scanHistoryId,
        rawOcrText:
            rawOcrText.isNotEmpty ? rawOcrText : _getRawOcrText(widget.data),
      );
      if (!mounted) return;
      setState(() {
        _intelligence = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _intelligenceError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingIntelligence = false;
        });
      }
    }
  }

  Future<void> _shareCurrentAnalysis() async {
    if (userId.isEmpty || _intelligence == null) return;

    try {
      final membersResponse = await http.get(
        Uri.parse(
          '$apiBaseUrl/api/family-members/$userId/connected',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer dummy-token-$userId',
        },
      );
      final decoded = membersResponse.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(membersResponse.body) as Map<String, dynamic>;
      if (membersResponse.statusCode != 200) {
        throw Exception(decoded['message'] ?? 'Unable to load family members');
      }
      final rawMembers =
          decoded['members'] is List ? decoded['members'] as List : <dynamic>[];
      final members = rawMembers
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where(
            (member) =>
                member['connectionStatus'] == 'connected' ||
                member['invitationStatus'] == 'accepted' ||
                (member['invitationEmail']?.toString().isNotEmpty ?? false),
          )
          .toList();

      if (!mounted) return;
      if (members.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add or invite a family member first.')),
        );
        return;
      }

      final selectedMember = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        builder: (context) => SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Share with family',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              ...members.map((member) {
                return ListTile(
                  leading: const Icon(Icons.family_restroom_outlined),
                  title: Text(member['name']?.toString() ?? 'Family member'),
                  subtitle: Text(
                    member['invitationEmail']?.toString().isNotEmpty == true
                        ? member['invitationEmail'].toString()
                        : member['connectionStatus']?.toString() ?? '',
                  ),
                  onTap: () => Navigator.pop(context, member),
                );
              }),
            ],
          ),
        ),
      );

      if (selectedMember == null) return;

      final product = _map(_intelligence!['productIdentification']);
      final suitability = _map(_intelligence!['suitability']);
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/shared-content'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer dummy-token-$userId',
        },
        body: jsonEncode({
          'senderUserId': userId,
          'memberId': selectedMember['_id']?.toString() ?? '',
          'type': 'recommendation',
          'title': 'Shared product recommendation',
          'message':
              '$userName shared ${_text(product['productName'], 'a scanned product')} with recommendation: ${_text(suitability['status'], 'Review product')}.',
          'payload': {
            'scanHistoryId': _scanHistoryId,
            'analysis': _intelligence,
          },
        }),
      );
      final shareDecoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shared with family member.')),
        );
      } else {
        throw Exception(shareDecoded['message'] ?? 'Unable to share result');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _sendProductFeedback(String feedbackType) async {
    if (userId.isEmpty || _intelligence == null) return;
    try {
      final product = _map(_intelligence!['productIdentification']);
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/product-feedback'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer dummy-token-$userId',
        },
        body: jsonEncode({
          'userId': userId,
          'scanHistoryId': _scanHistoryId,
          'productAnalysisId': _intelligence!['analysisId']?.toString() ?? '',
          'productName': _text(product['productName'], 'Scanned Product'),
          'feedbackType': feedbackType,
          'message': feedbackType == 'helpful'
              ? 'Recommendation was helpful.'
              : 'Recommendation needs review.',
          'payload': {'analysis': _intelligence},
        }),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.statusCode == 200 || response.statusCode == 201
                ? 'Feedback saved.'
                : 'Unable to save feedback.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = _cleanedIngredients;
    final ingredientCount = ingredients.length;

    return Scaffold(
      backgroundColor: _bg,
      drawer: AppDrawer(
        userName: userName,
        userEmail: userEmail,
        userId: userId,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(context),
                    _buildResultHeader(ingredientCount),
                    const SizedBox(height: 20),
                    if (_isCleaningOcr) _buildLoadingState(),
                    if (!_isCleaningOcr) _buildAutomaticIntelligenceSection(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan Results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Personal Food Analysis',
                  style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
                ),
              ],
            ),
          ),
          Builder(
            builder: (ctx) {
              return GestureDetector(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: _teal,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'G',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultHeader(int ingredientCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _teal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _teal.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _teal,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.health_and_safety,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analysis Complete',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_getIngredientCountText(ingredientCount)} • WHO guidance applied',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Success',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getIngredientCountText(int count) {
    if (count == 0) return 'No ingredients found';
    if (count == 1) return '1 ingredient found';
    return '$count ingredients found';
  }

  Widget _buildAutomaticIntelligenceSection() {
    if (_isLoadingIntelligence) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: _IntelligenceStatusCard(
          icon: Icons.psychology_outlined,
          title: 'Preparing your food report',
          message:
              'Checking the product, your saved preferences, halal status, calories, nutrition quality, and suitable alternatives.',
          loading: true,
        ),
      );
    }
    if (_intelligenceError.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: _IntelligenceStatusCard(
          icon: Icons.cloud_off_outlined,
          title: 'Detailed analysis unavailable',
          message: _intelligenceError,
          color: Colors.red,
        ),
      );
    }
    if (_intelligence == null) return const SizedBox.shrink();

    final product = _map(_intelligence!['productIdentification']);
    final suitability = _map(_intelligence!['suitability']);
    final halal = _map(_intelligence!['halal']);
    final calories = _map(_intelligence!['calories']);
    final nutritionAnalysis = _map(_intelligence!['nutritionAnalysis']);
    final safety = _map(_intelligence!['safetySummary']);
    final allergens = _map(_intelligence!['allergens']);
    final preferences = _list(_intelligence!['selectedPreferences']);
    final details = _list(_intelligence!['ingredientDetails']);
    final alternatives = _list(_intelligence!['alternatives']);
    final preferenceMatches = _list(suitability['preferenceMatches']);
    final preferenceConflicts = _list(suitability['preferenceConflicts']);
    final recommended = suitability['isRecommended'] == true;
    final decisionColor = recommended ? _teal : const Color(0xFFB33A3A);
    final halalStatus = _text(halal['status'], 'Doubtful');
    final halalColor = _halalColor(halalStatus);
    final halalValue = halalStatus;
    final harmfulNames = _stringList(safety['harmfulIngredients']);
    final detectedAllergenNames = _list(allergens['detected'])
        .map((rawAllergen) {
          final item = _map(rawAllergen);
          return _text(item['allergen'], rawAllergen.toString());
        })
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList();
    final preferenceAllergenNames = _list(allergens['preferenceMatches'])
        .map((rawMatch) {
          final item = _map(rawMatch);
          return _text(item['preference'], _text(item['ingredient'], ''));
        })
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList();
    final doubtfulIngredientNames = details
        .map((rawDetail) => _map(rawDetail))
        .where(
          (detail) =>
              _text(detail['halalStatus'], '').toLowerCase() == 'doubtful',
        )
        .map((detail) => _text(detail['name'], 'Ingredient'))
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _analysisPanel(
            color: decisionColor.withOpacity(0.06),
            borderColor: decisionColor.withOpacity(0.28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      recommended
                          ? Icons.verified_outlined
                          : Icons.cancel_outlined,
                      color: decisionColor,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _text(suitability['status'], 'Food recommendation'),
                            style: TextStyle(
                              color: decisionColor,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _text(
                              product['productName'],
                              'Unknown scanned product',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product['identified'] == true
                                ? '${_text(product['subCategory'], _text(product['category'], 'Food product'))} | ${_text(product['confidenceLevel'], 'Moderate')} confidence'
                                : product['categoryInferred'] == true
                                    ? 'Category identified as ${_text(product['subCategory'], _text(product['category'], 'Food product'))}; product name was not guessed.'
                                    : 'No reliable product match. The ingredient report is still available.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ReportChip(
                      text: '${_number(suitability['score']).round()}/100',
                      color: decisionColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _text(
                    suitability['recommendation'],
                    'Recommendation unavailable.',
                  ),
                  style: const TextStyle(height: 1.4, color: Colors.black87),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: _teal, size: 19),
                    SizedBox(width: 7),
                    Text(
                      'Matches',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                if (preferenceMatches.isEmpty)
                  const Text(
                    'No selected preference could be confirmed from the available label data.',
                    style: TextStyle(color: Colors.black54, fontSize: 12.5),
                  )
                else
                  ...preferenceMatches.map((rawMatch) {
                    final match = _map(rawMatch);
                    return _SmallReportNote(
                      icon: Icons.check,
                      text:
                          '${_text(match['preference'], 'Preference')}: ${_text(match['reason'], 'Matches this product.')}',
                      color: _teal,
                    );
                  }),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(Icons.cancel, color: Color(0xFFB33A3A), size: 19),
                    SizedBox(width: 7),
                    Text(
                      'Conflicts',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                if (preferenceConflicts.isEmpty)
                  const Text(
                    'No selected preference conflicts were found.',
                    style: TextStyle(color: Colors.black54, fontSize: 12.5),
                  )
                else
                  ...preferenceConflicts.map((rawConflict) {
                    final conflict = _map(rawConflict);
                    return _SmallReportNote(
                      icon: Icons.priority_high,
                      text:
                          '${_text(conflict['preference'], 'Preference')}: ${_text(conflict['reason'], 'Conflicts with this product.')}',
                      color: const Color(0xFFB33A3A),
                    );
                  }),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnalysisReportScreen(
                                reportData: _intelligence!,
                                userName: userName,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.assignment_outlined, size: 18),
                        label: const Text('Complete report'),
                        style: FilledButton.styleFrom(
                          backgroundColor: decisionColor,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _shareCurrentAnalysis,
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: decisionColor,
                          side: BorderSide(
                            color: decisionColor.withOpacity(0.35),
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _sendProductFeedback('helpful'),
                        icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
                        label: const Text('Helpful'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _teal,
                          side: BorderSide(color: _teal.withOpacity(0.35)),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _sendProductFeedback('needs_review'),
                        icon: const Icon(Icons.flag_outlined, size: 18),
                        label: const Text('Review'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD99A23),
                          side: BorderSide(
                            color: const Color(0xFFD99A23).withOpacity(0.35),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _analysisPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ReportHeader(
                  icon: Icons.tune_outlined,
                  title: 'Your selected preferences',
                  color: _teal,
                ),
                const SizedBox(height: 10),
                if (preferences.isEmpty)
                  const Text(
                    'No preferences are saved yet.',
                    style: TextStyle(color: Colors.black54),
                  )
                else
                  ...preferences.map((rawPreference) {
                    final preference = _map(rawPreference);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _text(preference['category'], 'Preference'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _stringList(preference['items'])
                                .map(
                                  (item) =>
                                      _ReportChip(text: item, color: _teal),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _analysisPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ReportHeader(
                  icon: Icons.health_and_safety_outlined,
                  title: 'Ingredient safety',
                  color: _teal,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ReportChip(
                      text:
                          'Green: ${_number(safety['safeCount']).round()} Safe',
                      color: _teal,
                    ),
                    _ReportChip(
                      text:
                          'Yellow: ${_number(safety['moderateCount']).round()} Moderate',
                      color: const Color(0xFFD99A23),
                    ),
                    _ReportChip(
                      text:
                          'Red: ${_number(safety['harmfulCount']).round()} Harmful',
                      color: const Color(0xFFB33A3A),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (harmfulNames.isNotEmpty ||
              detectedAllergenNames.isNotEmpty ||
              preferenceAllergenNames.isNotEmpty ||
              doubtfulIngredientNames.isNotEmpty) ...[
            _analysisPanel(
              color: const Color(0xFFFFF7E8),
              borderColor: const Color(0xFFD99A23).withOpacity(0.32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ReportHeader(
                    icon: Icons.report_problem_outlined,
                    title: 'Ingredient alerts',
                    color: Color(0xFFD99A23),
                  ),
                  const SizedBox(height: 10),
                  if (harmfulNames.isNotEmpty)
                    _SmallReportNote(
                      icon: Icons.dangerous_outlined,
                      text:
                          'Harmful or not recommended: ${harmfulNames.join(', ')}',
                      color: const Color(0xFFB33A3A),
                    ),
                  if (detectedAllergenNames.isNotEmpty)
                    _SmallReportNote(
                      icon: Icons.warning_amber_outlined,
                      text:
                          'Allergens detected: ${detectedAllergenNames.join(', ')}',
                      color: const Color(0xFFD99A23),
                    ),
                  if (preferenceAllergenNames.isNotEmpty)
                    _SmallReportNote(
                      icon: Icons.personal_injury_outlined,
                      text:
                          'Matches your allergy preferences: ${preferenceAllergenNames.join(', ')}',
                      color: const Color(0xFFB33A3A),
                    ),
                  if (doubtfulIngredientNames.isNotEmpty)
                    _SmallReportNote(
                      icon: Icons.help_outline,
                      text:
                          'Halal source needs verification: ${doubtfulIngredientNames.join(', ')}',
                      color: const Color(0xFFD99A23),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          _analysisPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ReportHeader(
                  icon: Icons.list_alt_outlined,
                  title: 'Ingredients information',
                  color: _teal,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Clear details from the scanned label and ingredient knowledge base.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                if (details.isEmpty)
                  const Text(
                    'No ingredient details were found for this scan.',
                    style: TextStyle(color: Colors.black54),
                  )
                else
                  ...details.map((rawDetail) {
                    final detail = _map(rawDetail);
                    return _buildIngredientInsightCard(detail);
                  }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  icon: Icons.mosque_outlined,
                  title: 'Halal status',
                  value: halalValue,
                  color: halalColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  icon: Icons.local_fire_department_outlined,
                  title: 'Calories',
                  value: calories['caloriesPer100'] == null
                      ? 'Unavailable'
                      : '${_number(calories['caloriesPer100']).round()} kcal / 100',
                  color: _teal,
                ),
              ),
            ],
          ),
          if (_stringList(halal['reasons']).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _SmallReportNote(
                icon: Icons.info_outline,
                text: _stringList(halal['reasons']).join(' '),
                color: halalColor,
              ),
            ),
          if (_text(halal['evidenceLevel'], '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _SmallReportNote(
                icon: Icons.fact_check_outlined,
                text: _text(halal['evidenceLevel'], ''),
                color: halalColor,
              ),
            ),
          if (_text(halal['classificationMethod'], '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _SmallReportNote(
                icon: Icons.manage_search_outlined,
                text: _text(halal['classificationMethod'], ''),
                color: halalColor,
              ),
            ),
          const SizedBox(height: 12),
          _analysisPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ReportHeader(
                  icon: Icons.restaurant_menu_outlined,
                  title: 'Nutrition fit',
                  color: Color(0xFF185FA5),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ReportChip(
                      text:
                          'Nutrition score ${_number(nutritionAnalysis['score']).round()}/100',
                      color: const Color(0xFF185FA5),
                    ),
                    if (_text(calories['source'], '').isNotEmpty)
                      _ReportChip(
                        text: _text(calories['source'], 'Nutrition data'),
                        color: _teal,
                      ),
                  ],
                ),
                ..._stringList(nutritionAnalysis['positiveNotes']).map(
                  (note) => _SmallReportNote(
                    icon: Icons.check_circle_outline,
                    text: note,
                    color: _teal,
                  ),
                ),
                ..._stringList(nutritionAnalysis['reasons']).map(
                  (reason) => _SmallReportNote(
                    icon: Icons.info_outline,
                    text: reason,
                    color: const Color(0xFFD99A23),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _analysisPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ReportHeader(
                  icon: Icons.swap_horiz_outlined,
                  title: 'Better alternatives',
                  color: _teal,
                ),
                const SizedBox(height: 8),
                Text(
                  _text(
                    _intelligence!['alternativesMessage'],
                    'Alternatives are ranked by category and your preferences.',
                  ),
                  style: const TextStyle(color: Colors.black54, fontSize: 12.5),
                ),
                if (alternatives.isNotEmpty) const SizedBox(height: 10),
                ...alternatives.map((rawAlternative) {
                  final alternative = _map(rawAlternative);
                  final altSuitability = _map(alternative['suitability']);
                  final altHalal = _map(alternative['halal']);
                  final fullySuitable = alternative['fullySuitable'] == true;
                  final alternativeColor =
                      fullySuitable ? _teal : const Color(0xFFD99A23);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: alternativeColor.withOpacity(0.05),
                      border: Border.all(
                        color: alternativeColor.withOpacity(0.22),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              fullySuitable
                                  ? Icons.check_circle_outline
                                  : Icons.info_outline,
                              color: alternativeColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _text(
                                  alternative['productName'],
                                  'Alternative product',
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            _ReportChip(
                              text:
                                  '${_number(altSuitability['score']).round()}/100',
                              color: alternativeColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_text(alternative['categoryMatch'], 'Same category')} | ${_text(alternative['subCategory'], 'Food product')} | ${_text(altHalal['status'], 'Doubtful')}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Colors.black54,
                          ),
                        ),
                        _SmallReportNote(
                          icon: fullySuitable
                              ? Icons.verified_outlined
                              : Icons.warning_amber_outlined,
                          text: fullySuitable
                              ? 'Suitable for your saved preferences.'
                              : 'Closest category alternative; review the listed preference conflicts.',
                          color: alternativeColor,
                        ),
                        ..._stringList(alternative['whySuggested']).map(
                          (reason) => _SmallReportNote(
                            icon: Icons.check,
                            text: reason,
                            color: alternativeColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _analysisPanel({
    required Widget child,
    Color color = Colors.white,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor ?? Colors.black.withOpacity(0.07),
        ),
      ),
      child: child,
    );
  }

  Widget _buildIngredientInsightCard(Map<String, dynamic> detail) {
    final name = _text(detail['name'], 'Ingredient');
    final scannedName = _text(detail['scannedName'], '');
    final category = _text(detail['category'], 'Food ingredient');
    final status = _text(detail['safetyStatus'], 'Moderate');
    final safetyColor = _safetyColor(status);
    final halalStatus = _text(detail['halalStatus'], 'Doubtful');
    final halalColor = _halalColor(halalStatus);
    final explanation = _text(
      detail['simpleExplanation'],
      _text(detail['purpose'], 'Used as part of the product recipe.'),
    );
    final healthEffects = _stringList(detail['healthEffects']);
    final additiveCodes = _stringList(detail['eCodes']);
    final halalMarkers = _stringList(detail['halalTriggers']);
    final showScannedName = scannedName.isNotEmpty &&
        scannedName.toLowerCase() != name.toLowerCase();
    var expanded = false;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFCFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black.withOpacity(0.07)),
        ),
        child: IntrinsicHeight(
          child: StatefulBuilder(
            builder: (context, setCardState) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 5, color: safetyColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setCardState(
                              () => expanded = !expanded,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: safetyColor.withOpacity(0.11),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.spa_outlined,
                                    color: safetyColor,
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        explanation,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildIngredientChipScroller(
                                        status: status,
                                        safetyColor: safetyColor,
                                        halalStatus: halalStatus,
                                        halalColor: halalColor,
                                        category: category,
                                        additiveCodes: additiveCodes,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  expanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.black54,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                          if (expanded) ...[
                            const SizedBox(height: 12),
                            Divider(
                              height: 1,
                              color: Colors.black.withOpacity(0.08),
                            ),
                            const SizedBox(height: 12),
                            if (showScannedName)
                              _DetailText(
                                label: 'Scanned as',
                                value: scannedName,
                              ),
                            _DetailText(label: 'Category', value: category),
                            _DetailText(
                              label: 'What it does',
                              value: explanation,
                            ),
                            _DetailText(
                              label: 'Safety analysis',
                              value: _text(
                                detail['safetyReason'],
                                'Use normal dietary caution.',
                              ),
                            ),
                            if (healthEffects.isNotEmpty)
                              _DetailText(
                                label: 'Health impact',
                                value: healthEffects.join(' '),
                              ),
                            _DetailText(
                              label: 'Halal status',
                              value: halalStatus,
                            ),
                            if (_text(detail['halalReason'], '').isNotEmpty)
                              _DetailText(
                                label: 'Halal analysis',
                                value: _text(detail['halalReason'], ''),
                              ),
                            if (halalMarkers.isNotEmpty)
                              _DetailText(
                                label: 'Halal markers',
                                value: halalMarkers.join(', '),
                              ),
                            if (additiveCodes.isNotEmpty)
                              _DetailText(
                                label: 'Additive codes',
                                value: additiveCodes.join(', '),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientChipScroller({
    required String status,
    required Color safetyColor,
    required String halalStatus,
    required Color halalColor,
    required String category,
    required List<String> additiveCodes,
  }) {
    return SizedBox(
      height: 27,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ReportChip(text: status, color: safetyColor),
            const SizedBox(width: 6),
            _ReportChip(text: halalStatus, color: halalColor),
            const SizedBox(width: 6),
            _ReportChip(text: category, color: _teal),
            ...additiveCodes.take(2).expand<Widget>(
                  (code) => [
                    const SizedBox(width: 6),
                    _ReportChip(
                      text: code,
                      color: const Color(0xFF185FA5),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<dynamic> _list(dynamic value) => value is List ? value : <dynamic>[];

  List<String> _stringList(dynamic value) => value is List
      ? value.map((item) => item.toString()).toList()
      : <String>[];

  String _text(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Color _safetyColor(String safety) {
    final clean = safety.toLowerCase();
    if (clean == 'safe') return _teal;
    if (clean == 'harmful' || clean == 'restricted') {
      return const Color(0xFFB33A3A);
    }
    return const Color(0xFFD99A23);
  }

  Color _halalColor(String status) {
    final clean = status.toLowerCase();
    if (clean == 'halal') return _teal;
    if (clean == 'haram') return const Color(0xFFB33A3A);
    return const Color(0xFFD99A23);
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: _teal),
            SizedBox(height: 14),
            Text(
              'Cleaning OCR and validating ingredients...',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
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
                  if (isScan) {
                    Navigator.pop(context);
                  } else if (i == 0) {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  } else if (i == 2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportsScreen(
                          userId: userId,
                          userName: userName,
                          userEmail: userEmail,
                        ),
                      ),
                    );
                  } else if (i == 3) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HealthDashboardScreen(
                          userId: userId,
                          userName: userName,
                          userEmail: userEmail,
                        ),
                      ),
                    );
                  } else if (i == 4) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsScreen(
                          userId: userId,
                          userName: userName,
                          userEmail: userEmail,
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

class _IntelligenceStatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool loading;
  final Color color;

  const _IntelligenceStatusCard({
    required this.icon,
    required this.title,
    required this.message,
    this.loading = false,
    this.color = const Color(0xFF2E8B72),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          loading
              ? const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : Icon(icon, color: color, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.black54,
                    height: 1.35,
                    fontSize: 12.5,
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

class _ReportHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _ReportHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _SummaryTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 9),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportChip extends StatelessWidget {
  final String text;
  final Color color;

  const _ReportChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SmallReportNote extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _SmallReportNote({
    required this.icon,
    required this.text,
    this.color = Colors.black54,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailText extends StatelessWidget {
  final String label;
  final String value;

  const _DetailText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String userId;

  const AppDrawer({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userId,
  });

  static const Color _teal = Color(0xFF2E8B72);

  Future<void> _logout(BuildContext context) async {
    await SessionService.clearSession();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.80,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: _teal,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userEmail,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _DrawerItem(
                      icon: Icons.qr_code_scanner,
                      label: 'Scan',
                      onTap: () => Navigator.pop(context),
                    ),
                    _divider(),
                    _DrawerItem(
                      icon: Icons.people_outline,
                      label: 'Family Profile',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FamilyProfileSetupScreen(
                              userId: userId,
                              userName: userName,
                            ),
                          ),
                        );
                      },
                    ),
                    _divider(),
                    _DrawerItem(
                      icon: Icons.history,
                      label: 'Scan History',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScanHistoryScreen(
                              userId: userId,
                              userName: userName,
                              userEmail: userEmail,
                            ),
                          ),
                        );
                      },
                    ),
                    _divider(),
                    _DrawerItem(
                      icon: Icons.tune,
                      label: 'Set Preferences',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                myprefs.AdditivesPreferencesScreen(
                              userName: userName,
                              userEmail: userEmail,
                              userId: userId,
                              preferences: myprefs.UserPreferences(),
                            ),
                          ),
                        );
                      },
                    ),
                    _divider(),
                    _DrawerItem(
                      icon: Icons.list_alt_outlined,
                      label: 'My Preferences',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewPreferencesScreen(
                              userId: userId,
                              userName: userName,
                              userEmail: userEmail,
                            ),
                          ),
                        );
                      },
                    ),
                    _divider(),
                    _DrawerItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsScreen(
                              userId: userId,
                              userName: userName,
                              userEmail: userEmail,
                            ),
                          ),
                        );
                      },
                    ),
                    _divider(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                child: _DrawerItem(
                  icon: Icons.logout,
                  label: 'Log Out',
                  onTap: () => _logout(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() => Divider(
        color: Colors.white.withOpacity(0.25),
        height: 1,
        indent: 24,
        endIndent: 24,
      );
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _DrawerItem({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white54, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        if (onTap != null) {
          onTap!();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label is unavailable right now.'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
    );
  }
}
