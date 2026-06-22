import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';

import 'Homepage.dart';
import 'scan_screen.dart';
import 'family_members_preferences.dart';

// ─────────────────────────────────────────────
// THEME CONSTANTS - SAME STYLE AS VIEW PREFERENCES PAGE
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
const Color kDanger = Color(0xFFE74C3C);

const String apiBaseUrl = 'http://192.168.0.114:9000';

// ─────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────
class FamilyMember {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String relation;
  final String? weight;
  final List<String> healthConditions;
  final bool isPrimary;
  final String invitationEmail;
  final String invitationStatus;
  final String connectionStatus;
  final Map<String, dynamic> permissions;
  final String lastActiveAt;

  FamilyMember({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.relation,
    this.weight,
    this.healthConditions = const [],
    this.isPrimary = false,
    this.invitationEmail = '',
    this.invitationStatus = 'local_profile',
    this.connectionStatus = 'local_profile',
    this.permissions = const {},
    this.lastActiveAt = '',
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      age: json['age'] is int
          ? json['age']
          : int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      gender: json['gender']?.toString() ?? 'Male',
      relation: json['relation']?.toString() ?? '',
      weight: json['weight']?.toString(),
      healthConditions: (json['healthConditions'] is List)
          ? (json['healthConditions'] as List).map((e) => e.toString()).toList()
          : <String>[],
      isPrimary: json['isPrimary'] == true,
      invitationEmail: json['invitationEmail']?.toString() ?? '',
      invitationStatus: json['invitationStatus']?.toString() ?? 'local_profile',
      connectionStatus: json['connectionStatus']?.toString() ??
          json['invitationStatus']?.toString() ??
          'local_profile',
      permissions: json['permissions'] is Map
          ? Map<String, dynamic>.from(json['permissions'] as Map)
          : <String, dynamic>{},
      lastActiveAt: json['lastActiveAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'relation': relation,
      'weight': weight,
      'healthConditions': healthConditions,
      'invitationEmail': invitationEmail,
    };
  }

  String get initials {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return '?';
    final parts = cleanName.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return cleanName[0].toUpperCase();
  }
}

// ─────────────────────────────────────────────
// SAME BOTTOM NAVIGATION BAR AS VIEW PREFERENCES PAGE
// ─────────────────────────────────────────────
class AppBottomNav extends StatefulWidget {
  final int selectedIndex;

  const AppBottomNav({
    super.key,
    this.selectedIndex = 4,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  late int _selectedNav;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _selectedNav = widget.selectedIndex;
    _initializeCameras();
  }

  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      debugPrint('Error initializing cameras: $e');
    }
  }

  Future<void> _navigateToHome() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = {
      'id': prefs.getString('user_id') ?? '',
      'fullName': prefs.getString('user_name') ?? 'User',
      'email': prefs.getString('user_email') ?? '',
    };

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => HomePage(userData: userData)),
      (route) => false,
    );
  }

  Future<void> _navigateToScan() async {
    if (_cameras == null || _cameras!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No cameras available'),
          backgroundColor: kDanger,
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ScanScreen(camera: _cameras!.first)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navItems = [
      {'icon': Icons.home_outlined, 'label': 'Home'},
      {'icon': Icons.qr_code_scanner, 'label': 'Scan'},
      {'icon': Icons.bar_chart_outlined, 'label': 'Reports'},
      {'icon': Icons.favorite_outline, 'label': 'Health'},
      {'icon': Icons.settings_outlined, 'label': 'Settings'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: kPrimary,
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
                    _navigateToHome();
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
// FAMILY PROFILE SETUP SCREEN
// ─────────────────────────────────────────────
class FamilyProfileSetupScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const FamilyProfileSetupScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<FamilyProfileSetupScreen> createState() =>
      _FamilyProfileSetupScreenState();
}

class _FamilyProfileSetupScreenState extends State<FamilyProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _relationCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();

  String _gender = 'Male';
  final List<String> _selectedConditions = [];
  bool _isLoading = false;

  final List<String> _allConditions = [
    'Diabetes',
    'Hypertension',
    'High cholesterol',
    'Kidney disease',
    'Heart disease',
    'Asthma',
    'Food allergies',
    'Lactose intolerance',
    'Celiac disease',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _emailCtrl.dispose();
    _relationCtrl.dispose();
    _weightCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  void _toggleCondition(String condition) {
    setState(() {
      if (_selectedConditions.contains(condition)) {
        _selectedConditions.remove(condition);
      } else {
        _selectedConditions.add(condition);
      }
    });
  }

  Future<void> _goHome() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = {
      'id': prefs.getString('user_id') ?? widget.userId,
      'fullName': prefs.getString('user_name') ?? widget.userName,
      'email': prefs.getString('user_email') ?? '',
    };

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => HomePage(userData: userData)),
      (route) => false,
    );
  }

  Future<void> _addMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Authentication error'), backgroundColor: kDanger),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('$apiBaseUrl/family-members'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': widget.userId,
          'name': _nameCtrl.text.trim(),
          'invitationEmail': _emailCtrl.text.trim(),
          'age': int.tryParse(_ageCtrl.text.trim()) ?? 0,
          'gender': _gender,
          'relation': _relationCtrl.text.trim(),
          'weight':
              _weightCtrl.text.trim().isEmpty ? null : _weightCtrl.text.trim(),
          'healthConditions': _selectedConditions,
        }),
      );

      if (response.statusCode == 201) {
        final memberData = jsonDecode(response.body) as Map<String, dynamic>;
        final memberJson = memberData['member'] is Map
            ? Map<String, dynamic>.from(memberData['member'] as Map)
            : memberData;
        final newMember = FamilyMember.fromJson(memberJson);
        final inviteEmail = newMember.invitationEmail.trim();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(inviteEmail.isEmpty
                ? '${newMember.name} added successfully!'
                : '${newMember.name} added. Invitation saved for $inviteEmail.'),
            backgroundColor: kPrimary,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => FamilyMembersScreen(userId: widget.userId)),
        );
      } else {
        String message = 'Failed to add member';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['message'] != null)
            message = decoded['message'].toString();
        } catch (_) {}
        throw Exception(message);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: kDanger),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgCream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FamilyAppBar(
                        title: 'Add Family Member',
                        onBackPressed: _goHome,
                      ),
                      const _AddMemberHeader(),
                      const SizedBox(height: 18),
                      _FormCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionTitle(
                              icon: Icons.person_add_alt_1_outlined,
                              title: 'Member Details',
                              subtitle:
                                  'Create a food safety profile for a family member.',
                            ),
                            const SizedBox(height: 18),
                            _label('Full name'),
                            _inputField(
                              _nameCtrl,
                              'Enter full name',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty)
                                  return 'Please enter name';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _label('Invitation email'),
                            _inputField(
                              _emailCtrl,
                              'Optional email for request',
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) return null;
                                final valid =
                                    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                        .hasMatch(text);
                                return valid ? null : 'Enter a valid email';
                              },
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _label('Age'),
                                      _inputField(
                                        _ageCtrl,
                                        'Age',
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty)
                                            return 'Please enter age';
                                          if (int.tryParse(value.trim()) ==
                                              null) return 'Enter valid age';
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _label('Relation'),
                                      _inputField(
                                        _relationCtrl,
                                        'e.g. Brother',
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty)
                                            return 'Enter relation';
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _label('Gender'),
                                      _genderDropdown(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _label('Weight'),
                                      _inputField(_weightCtrl, 'Optional'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _label('Health conditions'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _allConditions.map((condition) {
                                final selected =
                                    _selectedConditions.contains(condition);
                                return GestureDetector(
                                  onTap: () => _toggleCondition(condition),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 13, vertical: 9),
                                    decoration: BoxDecoration(
                                      color:
                                          selected ? kPrimary : kChipUnselected,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: selected
                                            ? kPrimary
                                            : kPrimary.withOpacity(0.08),
                                      ),
                                    ),
                                    child: Text(
                                      condition,
                                      style: TextStyle(
                                        color:
                                            selected ? Colors.white : kTextDark,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kBgCream,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'We use this only to tailor food safety and nutrition recommendations.',
                                style: TextStyle(
                                    color: kTextMid,
                                    fontSize: 12.5,
                                    height: 1.35),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _label('Profile nickname'),
                            _inputField(
                                _nicknameCtrl, "Optional e.g. Kid 1, Grandma"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _addMember,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: kPrimary.withOpacity(0.55),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  'Add Member',
                                  style: TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w900),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const AppBottomNav(selectedIndex: 4),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: kTextDark,
        ),
      ),
    );
  }

  Widget _inputField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kTextLight, fontSize: 13.5),
        filled: true,
        fillColor: kBgCream,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kPrimary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kDanger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kDanger, width: 1.4),
        ),
      ),
    );
  }

  Widget _genderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: kBgCream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kPrimary),
          dropdownColor: kCardBg,
          items: ['Male', 'Female', 'Other']
              .map(
                (gender) => DropdownMenuItem(
                  value: gender,
                  child: Text(
                    gender,
                    style: const TextStyle(
                        fontSize: 14,
                        color: kTextDark,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _gender = value);
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FAMILY MEMBERS LIST SCREEN
// ─────────────────────────────────────────────
class FamilyMembersScreen extends StatefulWidget {
  final String userId;

  const FamilyMembersScreen({
    super.key,
    required this.userId,
  });

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  List<FamilyMember> _members = [];
  bool _isLoading = true;
  String? _error;
  String _loggedInUserName = 'User';

  @override
  void initState() {
    super.initState();
    _getLoggedInUser();
    _loadFamilyMembers();
  }

  Future<void> _getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _loggedInUserName = prefs.getString('user_name') ?? 'User';
    });
  }

  Future<void> _goHome() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = {
      'id': prefs.getString('user_id') ?? widget.userId,
      'fullName': prefs.getString('user_name') ?? _loggedInUserName,
      'email': prefs.getString('user_email') ?? '',
    };

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => HomePage(userData: userData)),
      (route) => false,
    );
  }

  Future<void> _loadFamilyMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _error = 'Authentication error';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$apiBaseUrl/family-members/${widget.userId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        if (!mounted) return;
        setState(() {
          _members = data
              .map(
                  (json) => FamilyMember.fromJson(json as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      } else {
        String message = 'Failed to load family members';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['message'] != null)
            message = decoded['message'].toString();
        } catch (_) {}
        if (!mounted) return;
        setState(() {
          _error = message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMember(String memberId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Authentication error'), backgroundColor: kDanger),
        );
        return;
      }

      final response = await http.delete(
        Uri.parse('$apiBaseUrl/family-members/$memberId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _members.removeWhere((member) => member.id == memberId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Member deleted successfully'),
              backgroundColor: kPrimary),
        );
      } else {
        String message = 'Failed to delete member';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['message'] != null)
            message = decoded['message'].toString();
        } catch (_) {}
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: kDanger),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error deleting member: $e'),
            backgroundColor: kDanger),
      );
    }
  }

  void _showDeleteConfirmation(FamilyMember member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Delete Member',
          style: TextStyle(color: kTextDark, fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Are you sure you want to delete ${member.name}?',
          style: const TextStyle(color: kTextMid, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: kTextMid, fontWeight: FontWeight.w800)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteMember(member.id);
            },
            child: const Text('Delete',
                style: TextStyle(color: kDanger, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _openAddMember() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FamilyProfileSetupScreen(
          userId: widget.userId,
          userName: _loggedInUserName,
        ),
      ),
    ).then((_) => _loadFamilyMembers());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgCream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FamilyAppBar(
                    title: 'Family Members',
                    onBackPressed: _goHome,
                    trailing: IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          color: kPrimary, size: 24),
                      onPressed: _loadFamilyMembers,
                    ),
                  ),
                  const _FamilyHeader(),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
            const AppBottomNav(selectedIndex: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kPrimary));
    }

    if (_error != null) {
      return _ErrorState(
        message: _error!,
        onRetry: _loadFamilyMembers,
      );
    }

    if (_members.isEmpty) {
      return _EmptyFamilyState(
        userName: _loggedInUserName,
        onAdd: _openAddMember,
        onRefresh: _loadFamilyMembers,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFamilyMembers,
      color: kPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.black.withOpacity(0.04)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: kChipUnselected,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.verified_user_outlined,
                        color: kPrimary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Primary: $_loggedInUserName',
                          style: const TextStyle(
                            color: kTextDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'You are the primary member. Secondary members can be added or removed.',
                          style: TextStyle(
                              color: kTextMid, fontSize: 12.5, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Family profiles',
                        style: TextStyle(
                            color: kTextDark,
                            fontSize: 17,
                            fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_members.length} secondary member${_members.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                            color: kTextMid,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _openAddMember,
                  icon: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 18),
                  label: const Text(
                    'Add',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final member = _members[index];
                return _MemberCard(
                  member: member,
                  onDelete: () => _showDeleteConfirmation(member),
                  userId: widget.userId,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// VIEW FAMILY MEMBER PREFERENCES SCREEN
// ─────────────────────────────────────────────
class FamilyMemberPreferencesViewScreen extends StatefulWidget {
  final String userId;
  final String memberId;
  final String memberName;

  const FamilyMemberPreferencesViewScreen({
    super.key,
    required this.userId,
    required this.memberId,
    required this.memberName,
  });

  @override
  State<FamilyMemberPreferencesViewScreen> createState() =>
      _FamilyMemberPreferencesViewScreenState();
}

class _FamilyMemberPreferencesViewScreenState
    extends State<FamilyMemberPreferencesViewScreen> {
  Map<String, dynamic>? _preferences;
  bool _isLoading = true;
  String? _error;
  String _loggedInUserName = 'User';

  @override
  void initState() {
    super.initState();
    _getLoggedInUser();
    _loadPreferences();
  }

  Future<void> _getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _loggedInUserName = prefs.getString('user_name') ?? 'User';
    });
  }

  Future<void> _goBack() async {
    if (!mounted) return;
    Navigator.pop(context);
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _error = 'Authentication error';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(
            '$apiBaseUrl/api/preferences/${widget.userId}?memberId=${widget.memberId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('View preferences status: ${response.statusCode}');
      debugPrint('View preferences body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (!mounted) return;
        setState(() {
          if (decoded is Map<String, dynamic> &&
              decoded['preferences'] is Map<String, dynamic>) {
            _preferences = decoded['preferences'] as Map<String, dynamic>;
          } else {
            _preferences = null;
          }
          _isLoading = false;
        });
      } else {
        String message = 'Failed to load preferences';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['message'] != null) {
            message = decoded['message'].toString();
          }
        } catch (_) {}

        if (!mounted) return;
        setState(() {
          _error = message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _openEditPreferences() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreferencesStartScreen(
          userName: _loggedInUserName,
          userEmail: '',
          userId: widget.userId,
          memberId: widget.memberId,
          memberName: widget.memberName,
          preferences: _preferences == null
              ? null
              : UserPreferences.fromJson(_preferences!),
        ),
      ),
    ).then((_) => _loadPreferences());
  }

  Future<void> _deletePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Authentication error'), backgroundColor: kDanger),
        );
        return;
      }

      final response = await http.delete(
        Uri.parse(
            '$apiBaseUrl/api/preferences/${widget.userId}?memberId=${widget.memberId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() => _preferences = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Preferences deleted successfully'),
              backgroundColor: kPrimary),
        );
      } else {
        String message = 'Failed to delete preferences';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['message'] != null)
            message = decoded['message'].toString();
        } catch (_) {}
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: kDanger),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error deleting preferences: $e'),
            backgroundColor: kDanger),
      );
    }
  }

  void _showDeletePreferencesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Delete Preferences',
          style: TextStyle(color: kTextDark, fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Are you sure you want to delete preferences for ${widget.memberName}?',
          style: const TextStyle(color: kTextMid, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: kTextMid, fontWeight: FontWeight.w800)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deletePreferences();
            },
            child: const Text('Delete',
                style: TextStyle(color: kDanger, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceChips(List<String> values) {
    if (values.isEmpty) {
      return const Text(
        'No items selected',
        style: TextStyle(
            color: kTextLight, fontSize: 12.5, fontWeight: FontWeight.w600),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: kChipUnselected,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kPrimary.withOpacity(0.10)),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: kTextDark,
              fontSize: 11.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _preferenceCard({
    required IconData icon,
    required String title,
    required List<String> selected,
    required List<String> custom,
    required String importance,
  }) {
    final allItems = [...selected, ...custom];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: kChipUnselected,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: kPrimary, size: 22),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: kTextDark,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (importance.trim().isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    importance,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 13),
          _buildPreferenceChips(allItems),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kPrimary));
    }

    if (_error != null) {
      return _ErrorState(
        message: _error!,
        onRetry: _loadPreferences,
      );
    }

    if (_preferences == null) {
      return RefreshIndicator(
        color: kPrimary,
        onRefresh: _loadPreferences,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(22),
          children: [
            const SizedBox(height: 60),
            Icon(Icons.tune_rounded,
                color: kPrimary.withOpacity(0.75), size: 72),
            const SizedBox(height: 18),
            Text(
              'No preferences found for ${widget.memberName}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: kTextDark, fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Set preferences first to view allergens, diet, additives, ingredients, and nutrition goals here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextMid, fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _openEditPreferences,
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                label: const Text(
                  'Set Preferences',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final p = _preferences!;

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: _loadPreferences,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.black.withOpacity(0.04)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: kChipUnselected,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.person_outline_rounded,
                        color: kPrimary, size: 25),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preferences For',
                          style: TextStyle(
                              color: kTextLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          p['memberName']?.toString() ?? widget.memberName,
                          style: const TextStyle(
                              color: kTextDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            _preferenceCard(
              icon: Icons.restaurant_menu_outlined,
              title: 'Dietary Preferences',
              selected: _stringList(p['diets'])
                  .where((item) => item.toLowerCase() != 'halal')
                  .toList(),
              custom: _stringList(p['customDiets']),
              importance: '',
            ),
            _preferenceCard(
              icon: Icons.monitor_heart_outlined,
              title: 'Health Goals',
              selected: _stringList(p['nutritions']),
              custom: _stringList(p['customNutritions']),
              importance: '',
            ),
            _preferenceCard(
              icon: Icons.health_and_safety_outlined,
              title: 'Allergies & Restrictions',
              selected: [
                ..._stringList(p['allergens']),
                ..._stringList(p['additives']),
                ..._stringList(p['ingredients']),
                ..._stringList(p['avoidedIngredients']),
              ],
              custom: [
                ..._stringList(p['customAllergens']),
                ..._stringList(p['customAdditives']),
                ..._stringList(p['customIngredients']),
                ..._stringList(p['customAvoidedIngredients']),
              ],
              importance: '',
            ),
            _preferenceCard(
              icon: Icons.verified_user_outlined,
              title: 'Religious Preferences',
              selected: _stringList(p['diets'])
                  .where((item) => item.toLowerCase() == 'halal')
                  .toList(),
              custom: const [],
              importance: '',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openEditPreferences,
                    icon: const Icon(Icons.edit_outlined,
                        color: kPrimary, size: 18),
                    label: const Text(
                      'Edit',
                      style: TextStyle(
                          color: kPrimary, fontWeight: FontWeight.w900),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kPrimary, width: 1.3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showDeletePreferencesDialog,
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: kDanger, size: 18),
                    label: const Text(
                      'Delete',
                      style: TextStyle(
                          color: kDanger, fontWeight: FontWeight.w900),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kDanger, width: 1.3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgCream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  _FamilyAppBar(
                    title: 'View Preferences',
                    onBackPressed: _goBack,
                    trailing: IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          color: kPrimary, size: 24),
                      onPressed: _loadPreferences,
                    ),
                  ),
                  Container(
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
                          child: const Icon(Icons.tune_rounded,
                              color: kPrimary, size: 29),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.memberName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Saved food safety and nutrition preferences for this family member.',
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
                  ),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
            const AppBottomNav(selectedIndex: 4),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHARED UI WIDGETS
// ─────────────────────────────────────────────
class _FamilyAppBar extends StatelessWidget {
  final String title;
  final VoidCallback onBackPressed;
  final Widget? trailing;

  const _FamilyAppBar({
    required this.title,
    required this.onBackPressed,
    this.trailing,
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
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: kPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 44,
            height: 44,
            child: trailing ?? const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _FamilyHeader extends StatelessWidget {
  const _FamilyHeader();

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
            child: const Icon(Icons.family_restroom_outlined,
                color: kPrimary, size: 29),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Family Profiles',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Manage family members for food safety alerts and nutrition recommendations.',
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

class _AddMemberHeader extends StatelessWidget {
  const _AddMemberHeader();

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
            child: const Icon(Icons.person_add_alt_1_outlined,
                color: kPrimary, size: 29),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Family Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Add details to personalize food safety alerts for this member.',
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

class _FormCard extends StatelessWidget {
  final Widget child;

  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                    color: kTextDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                    color: kTextMid, fontSize: 12.5, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback onDelete;
  final String userId;

  const _MemberCard({
    required this.member,
    required this.onDelete,
    required this.userId,
  });

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        duration: const Duration(seconds: 1),
        backgroundColor: kPrimary,
      ),
    );
  }

  Future<void> _showPermissionsDialog(BuildContext context) async {
    bool canViewScans = member.permissions['canViewScans'] != false;
    bool canShareRecommendations =
        member.permissions['canShareRecommendations'] != false;
    bool canManageOwnPreferences =
        member.permissions['canManageOwnPreferences'] != false;
    bool primaryCanManagePreferences =
        member.permissions['primaryCanManagePreferences'] != false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              final response = await http.put(
                Uri.parse(
                    '$apiBaseUrl/api/family-members/${member.id}/permissions'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer dummy-token-$userId',
                },
                body: jsonEncode({
                  'userId': userId,
                  'permissions': {
                    'canViewScans': canViewScans,
                    'canShareRecommendations': canShareRecommendations,
                    'canManageOwnPreferences': canManageOwnPreferences,
                    'primaryCanManagePreferences': primaryCanManagePreferences,
                  },
                }),
              );
              if (!context.mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(response.statusCode == 200
                      ? 'Permissions updated.'
                      : 'Unable to update permissions.'),
                  backgroundColor:
                      response.statusCode == 200 ? kPrimary : kDanger,
                ),
              );
            }

            return AlertDialog(
              title: Text('${member.name} permissions'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    value: canViewScans,
                    title: const Text('Can view shared scans'),
                    onChanged: (v) => setDialogState(() => canViewScans = v),
                  ),
                  SwitchListTile(
                    value: canShareRecommendations,
                    title: const Text('Can share recommendations'),
                    onChanged: (v) =>
                        setDialogState(() => canShareRecommendations = v),
                  ),
                  SwitchListTile(
                    value: canManageOwnPreferences,
                    title: const Text('Can manage own preferences'),
                    onChanged: (v) =>
                        setDialogState(() => canManageOwnPreferences = v),
                  ),
                  SwitchListTile(
                    value: primaryCanManagePreferences,
                    title: const Text('Primary can manage preferences'),
                    onChanged: (v) =>
                        setDialogState(() => primaryCanManagePreferences = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kChipUnselected,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    member.initials,
                    style: const TextStyle(
                      color: kPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: kTextDark,
                              fontWeight: FontWeight.w900,
                              fontSize: 15.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color:
                                member.isPrimary ? kPrimary : kChipUnselected,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            member.isPrimary ? 'Primary' : 'Secondary',
                            style: TextStyle(
                              color: member.isPrimary ? Colors.white : kPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${member.relation.isEmpty ? 'Family' : member.relation} • Age ${member.age} • ${member.gender}',
                      style: const TextStyle(
                          color: kTextMid,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600),
                    ),
                    if (member.weight != null &&
                        member.weight!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Weight: ${member.weight}',
                        style: const TextStyle(color: kTextMid, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      'Status: ${member.connectionStatus.replaceAll('_', ' ')}${member.lastActiveAt.isNotEmpty ? ' • active' : ''}',
                      style: const TextStyle(color: kPrimary, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: kCardBg,
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                icon: const Icon(Icons.more_vert_rounded, color: kTextMid),
                onSelected: (value) {
                  switch (value) {
                    case 'scan':
                      _showComingSoon(context, 'Scan for ${member.name}');
                      break;
                    case 'preferences':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PreferencesStartScreen(
                            userName: member.name,
                            userEmail: '',
                            userId: userId,
                            memberId: member.id,
                            memberName: member.name,
                          ),
                        ),
                      );
                      break;
                    case 'view_preferences':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FamilyMemberPreferencesViewScreen(
                            userId: userId,
                            memberId: member.id,
                            memberName: member.name,
                          ),
                        ),
                      );
                      break;
                    case 'history':
                      _showComingSoon(
                          context, '${member.name}\'s scan history');
                      break;
                    case 'permissions':
                      _showPermissionsDialog(context);
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'scan',
                    child: Row(
                      children: [
                        Icon(Icons.qr_code_scanner, size: 18, color: kPrimary),
                        SizedBox(width: 8),
                        Text('Scan for this member'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'preferences',
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined,
                            size: 18, color: kPrimary),
                        SizedBox(width: 8),
                        Text('Set Preferences'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'view_preferences',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined,
                            size: 18, color: kPrimary),
                        SizedBox(width: 8),
                        Text('View Preferences'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'history',
                    child: Row(
                      children: [
                        Icon(Icons.history_rounded, size: 18, color: kPrimary),
                        SizedBox(width: 8),
                        Text('Scan History'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'permissions',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings_outlined,
                            size: 18, color: kPrimary),
                        SizedBox(width: 8),
                        Text('Permissions'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: kDanger),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: kDanger)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (member.healthConditions.isNotEmpty) ...[
            const SizedBox(height: 13),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: member.healthConditions.map((condition) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: kChipUnselected,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimary.withOpacity(0.08)),
                  ),
                  child: Text(
                    condition,
                    style: const TextStyle(
                      color: kTextDark,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBgCream,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Use the menu to scan, set preferences, compare products, view history, or delete this profile.',
              style: TextStyle(color: kTextMid, fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFamilyState extends StatelessWidget {
  final String userName;
  final VoidCallback onAdd;
  final Future<void> Function() onRefresh;

  const _EmptyFamilyState({
    required this.userName,
    required this.onAdd,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(22),
        children: [
          const SizedBox(height: 70),
          Icon(Icons.family_restroom_outlined,
              color: kPrimary.withOpacity(0.75), size: 74),
          const SizedBox(height: 18),
          Text(
            'Welcome, $userName!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kTextDark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You are the primary member. Add family members to create personalized food safety profiles.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kTextMid, fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Add Family Member',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

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
