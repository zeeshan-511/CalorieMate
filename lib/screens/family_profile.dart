import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'Homepage.dart';

// ─────────────────────────────────────────────
// SHARED CONSTANTS
// ─────────────────────────────────────────────
const kPrimary = Color(0xFF2E8B72);
const kPrimaryLight = Color(0xFFE8F5F3);
const kBg = Color(0xFFFFF8EC);
const kText = Color(0xFF1A1A1A);
const kSubText = Color(0xFF6B6B6B);
const kCardBg = Color(0xFFFFFDF7);
const kInputBg = Color(0xFFFFF8EC);

// API Base URL
const String apiBaseUrl = 'http://192.168.0.105:9000';

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

  FamilyMember({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.relation,
    this.weight,
    this.healthConditions = const [],
    this.isPrimary = false,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? 'Male',
      relation: json['relation'] ?? '',
      weight: json['weight'],
      healthConditions: List<String>.from(json['healthConditions'] ?? []),
      isPrimary: json['isPrimary'] ?? false,
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
    };
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }
}

// ─────────────────────────────────────────────
// SHARED BOTTOM NAV
// ─────────────────────────────────────────────
class AppBottomNav extends StatefulWidget {
  const AppBottomNav({super.key});

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  int _selectedNav = 0;

  void _navigateToScan() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scan feature coming soon!'),
        duration: Duration(seconds: 1),
      ),
    );
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
      MaterialPageRoute(
        builder: (context) => HomePage(userData: userData),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.home_outlined,
      Icons.qr_code_scanner,
      Icons.history,
      Icons.directions_run,
      Icons.headset_mic_outlined,
    ];

    return Container(
      height: 64,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(icons.length, (i) {
          final selected = i == _selectedNav;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedNav = i;
              });

              if (i == 0) {
                _navigateToHome();
              } else if (i == 1) {
                _navigateToScan();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${icons[i].toString().split('.').last} feature coming soon!'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: selected
                  ? BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              )
                  : null,
              child: Icon(
                icons[i],
                color: selected ? Colors.white : Colors.white60,
                size: 26,
              ),
            ),
          );
        }),
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
  final _relationCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();

  String _gender = 'Male';
  List<String> _selectedConditions = [];
  bool _isLoading = false;

  final List<String> _allConditions = [
    'Diabetes', 'Hypertension', 'High cholesterol',
    'Kidney disease', 'Heart disease', 'Asthma',
    'Food allergies', 'Lactose intolerance', 'Celiac disease'
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _relationCtrl.dispose();
    _weightCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  void _toggleCondition(String c) {
    setState(() {
      _selectedConditions.contains(c)
          ? _selectedConditions.remove(c)
          : _selectedConditions.add(c);
    });
  }

  Future<void> _addMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication error'), backgroundColor: Colors.red),
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
          'age': int.tryParse(_ageCtrl.text) ?? 0,
          'gender': _gender,
          'relation': _relationCtrl.text.trim().isEmpty ? 'Family' : _relationCtrl.text.trim(),
          'weight': _weightCtrl.text.trim().isEmpty ? null : _weightCtrl.text.trim(),
          'healthConditions': _selectedConditions,
        }),
      );

      if (response.statusCode == 201) {
        final memberData = jsonDecode(response.body);
        final newMember = FamilyMember.fromJson(memberData);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newMember.name} added successfully!'),
            backgroundColor: kPrimary,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FamilyMembersScreen(userId: widget.userId),
          ),
        );
      } else {
        throw Exception('Failed to add member');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      bottomNavigationBar: const AppBottomNav(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Add Family Member',
                    style: TextStyle(
                      color: kPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kCardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Text(
                    'Add family members to receive personalized food safety alerts, health recommendations, and shared grocery planning.',
                    style: TextStyle(color: kSubText, fontSize: 14, height: 1.5),
                  ),
                ),
                const SizedBox(height: 20),

                // Member Details Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kCardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Member details',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPrimary)),
                      const Text('Add a secondary family member',
                          style: TextStyle(color: kSubText, fontSize: 12)),
                      const SizedBox(height: 16),

                      _label('Full name'),
                      _inputField(_nameCtrl, 'Enter full name', validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter name';
                        }
                        return null;
                      }),
                      const SizedBox(height: 12),

                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _label('Age'),
                          _inputField(_ageCtrl, 'Age',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter age';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ])),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _label('Relation'),
                          _inputField(_relationCtrl, 'e.g. Brother',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter relation';
                              }
                              return null;
                            },
                          ),
                        ])),
                      ]),
                      const SizedBox(height: 12),

                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _label('Gender'),
                          _genderDropdown(),
                        ])),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _label('Weight (optional)'),
                          _inputField(_weightCtrl, 'e.g. 70 kg'),
                        ])),
                      ]),
                      const SizedBox(height: 16),

                      _label('Key health conditions (optional)'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _allConditions.map((c) {
                          final selected = _selectedConditions.contains(c);
                          return GestureDetector(
                            onTap: () => _toggleCondition(c),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: selected ? kPrimary : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: selected ? kPrimary : Colors.grey.shade300),
                              ),
                              child: Text(c,
                                  style: TextStyle(
                                      color: selected ? Colors.white : kSubText,
                                      fontSize: 13)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'We use this only to tailor food safety and nutrition recommendations.',
                        style: TextStyle(color: kSubText, fontSize: 12),
                      ),
                      const SizedBox(height: 16),

                      _label('Profile nickname (optional)'),
                      _inputField(_nicknameCtrl, "e.g. Zeeshan's Dad, Kid 1, Grandma"),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addMember,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Add Member',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kText)),
  );

  Widget _inputField(TextEditingController ctrl, String hint,
      {TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
        filled: true,
        fillColor: kInputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kPrimary)),
      ),
    );
  }

  Widget _genderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: kInputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender,
          isExpanded: true,
          items: ['Male', 'Female', 'Other']
              .map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 14))))
              .toList(),
          onChanged: (v) => setState(() => _gender = v!),
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

  const FamilyMembersScreen({super.key, required this.userId});

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  List<FamilyMember> _members = [];
  bool _isLoading = true;
  String? _error;
  String _loggedInUserName = '';

  @override
  void initState() {
    super.initState();
    _getLoggedInUser();
    _loadFamilyMembers();
  }

  Future<void> _getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _loggedInUserName = prefs.getString('user_name') ?? 'User';
      });
    }
  }

  Future<void> _loadFamilyMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        if (mounted) {
          setState(() {
            _error = 'Authentication error';
            _isLoading = false;
          });
        }
        return;
      }

      final response = await http.get(
        Uri.parse('$apiBaseUrl/family-members/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _members = data.map((json) => FamilyMember.fromJson(json)).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load family members';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteMember(String memberId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return;

      final response = await http.delete(
        Uri.parse('$apiBaseUrl/family-members/$memberId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _members.removeWhere((m) => m.id == memberId);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Member deleted successfully'),
              backgroundColor: kPrimary,
            ),
          );
        }
      } else {
        final error = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error['message'] ?? 'Failed to delete member'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting member: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(FamilyMember member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text('Are you sure you want to delete ${member.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteMember(member.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      bottomNavigationBar: const AppBottomNav(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                children: [
                  Text('Family Members',
                      style: TextStyle(
                          color: kPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text(
                    'Manage your family members and their preferences.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kSubText, fontSize: 14),
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: kPrimary),
                ),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFamilyMembers,
                        style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_members.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.family_restroom, size: 80, color: kPrimary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome, $_loggedInUserName!',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimary),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You are the primary member',
                          style: TextStyle(fontSize: 16, color: kSubText),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Add family members to get started',
                          style: TextStyle(color: kSubText),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FamilyProfileSetupScreen(
                                  userId: widget.userId,
                                  userName: '',
                                ),
                              ),
                            ).then((_) => _loadFamilyMembers());
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Add Family Member'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      // Banner
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kPrimaryLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.person, color: kPrimary, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Primary: $_loggedInUserName',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: kText, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'You are the primary member. Secondary members can be added or removed.',
                                      style: TextStyle(color: kSubText, fontSize: 13, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Members count + Add button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Family members',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16, color: kText)),
                                Text('${_members.length} total (${_members.length} secondary)',
                                    style: const TextStyle(color: kSubText, fontSize: 13)),
                              ],
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FamilyProfileSetupScreen(
                                      userId: widget.userId,
                                      userName: '',
                                    ),
                                  ),
                                ).then((_) => _loadFamilyMembers());
                              },
                              icon: const Icon(Icons.add, size: 18, color: Colors.white),
                              label: const Text('Add member',
                                  style: TextStyle(color: Colors.white, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Members list with enhanced 3-dot menu options
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadFamilyMembers,
                          color: kPrimary,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _members.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final m = _members[index];
                              return _MemberCard(
                                member: m,
                                onDelete: () => _showDeleteConfirmation(m),
                              );
                            },
                          ),
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
}

// ─────────────────────────────────────────────
// MEMBER CARD WITH ENHANCED 3-DOT MENU
// ─────────────────────────────────────────────
class _MemberCard extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback onDelete;

  const _MemberCard({
    required this.member,
    required this.onDelete,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: kPrimaryLight,
                radius: 22,
                child: Text(
                  member.initials,
                  style: const TextStyle(
                      color: kPrimary, fontWeight: FontWeight.bold, fontSize: 15),
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
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15, color: kText),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Secondary',
                            style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    Text('Age ${member.age}, ${member.gender}',
                        style: const TextStyle(color: kSubText, fontSize: 13)),
                    if (member.healthConditions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Health: ${member.healthConditions.take(2).join(', ')}${member.healthConditions.length > 2 ? '...' : ''}',
                          style: const TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                  ],
                ),
              ),
              // Enhanced 3-dot menu with all options
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: kSubText),
                onSelected: (value) {
                  switch (value) {
                    case 'scan':
                      _showComingSoon(context, 'Scan for ${member.name}');
                      break;
                    case 'preferences':
                      _showComingSoon(context, '${member.name}\'s preferences');
                      break;
                    case 'compare':
                      _showComingSoon(context, 'Compare products for ${member.name}');
                      break;
                    case 'history':
                      _showComingSoon(context, '${member.name}\'s scan history');
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'scan',
                    child: Row(
                      children: [
                        Icon(Icons.qr_code_scanner, size: 18, color: kPrimary),
                        SizedBox(width: 8),
                        Text('Scan for this member'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'preferences',
                    child: Row(
                      children: [
                        Icon(Icons.settings, size: 18, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Set Preferences'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'compare',
                    child: Row(
                      children: [
                        Icon(Icons.compare_arrows, size: 18, color: Colors.purple),
                        SizedBox(width: 8),
                        Text('Compare Products'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'history',
                    child: Row(
                      children: [
                        Icon(Icons.history, size: 18, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('Scan History'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Secondary member - Tap menu to scan, set preferences, compare products, or view history',
            style: const TextStyle(color: kSubText, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}