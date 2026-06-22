import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'Homepage.dart';

const Color kPrimary = Color(0xFF2D7D6F);
const Color kPrimaryLight = Color(0xFF3A9E8D);
const Color kBgCream = Color(0xFFF5F0E8);
const Color kCardBg = Color(0xFFFFFFFF);
const Color kChipUnselected = Color(0xFFE6F3F0);
const Color kTextDark = Color(0xFF1A1A1A);
const Color kTextMid = Color(0xFF4A4A4A);
const Color kDanger = Color(0xFFE74C3C);

const String apiBaseUrl = 'http://192.168.0.114:9000';

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
    );
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

class ViewFamilyMembersScreen extends StatefulWidget {
  final String userId;

  const ViewFamilyMembersScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ViewFamilyMembersScreen> createState() =>
      _ViewFamilyMembersScreenState();
}

class _ViewFamilyMembersScreenState extends State<ViewFamilyMembersScreen> {
  List<FamilyMember> _members = [];
  bool _isLoading = true;
  String? _error;
  String _userName = 'User';
  int _selectedNav = 0;

  @override
  void initState() {
    super.initState();
    _getUserName();
    _loadFamilyMembers();
  }

  Future<void> _getUserName() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _userName = prefs.getString('user_name') ?? 'User';
    });
  }

  Future<void> _goHome() async {
    final prefs = await SharedPreferences.getInstance();

    final userData = {
      'id': prefs.getString('user_id') ?? widget.userId,
      'fullName': prefs.getString('user_name') ?? _userName,
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
          _error = 'Please sign in again to continue.';
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
              .map((json) => FamilyMember.fromJson(json as Map<String, dynamic>))
              .where((member) => member.isPrimary == false)
              .toList();
          _isLoading = false;
        });
      } else {
        String message = 'Unable to load your family members.';

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
        _error = 'Unable to connect. Please try again.';
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
            content: Text('Please sign in again to continue.'),
            backgroundColor: kDanger,
          ),
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
            content: Text('Family member deleted successfully.'),
            backgroundColor: kPrimary,
          ),
        );
      } else {
        String message = 'Unable to delete this family member.';

        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['message'] != null) {
            message = decoded['message'].toString();
          }
        } catch (_) {}

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: kDanger),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete this family member. Please try again.'),
          backgroundColor: kDanger,
        ),
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
          'Are you sure you want to delete ${member.name} from your family list?',
          style: const TextStyle(color: kTextMid, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: kTextMid, fontWeight: FontWeight.w800),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteMember(member.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: kDanger, fontWeight: FontWeight.w900),
            ),
          ),
        ],
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FamilyAppBar(
                    title: 'Family Members',
                    onBackPressed: _goHome,
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: kPrimary,
                        size: 24,
                      ),
                      onPressed: _loadFamilyMembers,
                    ),
                  ),
                  const _FamilyHeader(),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
            _buildBottomNav(),
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
                    _goHome();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${navItems[i]['label']} feature coming soon!'),
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kPrimary),
      );
    }

    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _loadFamilyMembers);
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
            _PrimaryUserCard(userName: _userName),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Family Profiles',
                        style: TextStyle(
                          color: kTextDark,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_members.length} family member${_members.length == 1 ? '' : 's'} added',
                        style: const TextStyle(
                          color: kTextMid,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_members.isEmpty)
              _EmptyMemberList(onRefresh: _loadFamilyMembers)
            else
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
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

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
            child: const Icon(
              Icons.family_restroom_outlined,
              color: kPrimary,
              size: 29,
            ),
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
                  'View and manage your family members in one place.',
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

class _PrimaryUserCard extends StatelessWidget {
  final String userName;

  const _PrimaryUserCard({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: const Icon(
              Icons.verified_user_outlined,
              color: kPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Profile: $userName',
                  style: const TextStyle(
                    color: kTextDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'This is your main profile. Your family members are listed below.',
                  style: TextStyle(
                    color: kTextMid,
                    fontSize: 12.5,
                    height: 1.35,
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

class _MemberCard extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback onDelete;

  const _MemberCard({
    required this.member,
    required this.onDelete,
  });

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
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: kChipUnselected,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Text(
                            'Family',
                            style: TextStyle(
                              color: kPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${member.relation.isEmpty ? 'Family Member' : member.relation} • Age ${member.age} • ${member.gender}',
                      style: const TextStyle(
                        color: kTextMid,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (member.weight != null &&
                        member.weight!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Weight: ${member.weight}',
                        style: const TextStyle(
                          color: kTextMid,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
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
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: kDanger,
                size: 18,
              ),
              label: const Text(
                'Delete Member',
                style: TextStyle(
                  color: kDanger,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: kDanger.withOpacity(0.35)),
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

class _EmptyMemberList extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyMemberList({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.family_restroom_outlined,
            color: kPrimary.withOpacity(0.75),
            size: 60,
          ),
          const SizedBox(height: 14),
          const Text(
            'No family members found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kTextDark,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'You haven’t added any family members yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kTextMid,
              fontSize: 13,
              height: 1.35,
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
                color: kTextMid,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}