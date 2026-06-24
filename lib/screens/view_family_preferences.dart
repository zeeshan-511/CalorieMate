import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'homepage.dart';
import 'family_members_preferences.dart';
import 'scan_screen.dart';
import 'ScanHistory.dart';

class ViewFamilyMembersPreferencesScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userEmail;

  const ViewFamilyMembersPreferencesScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<ViewFamilyMembersPreferencesScreen> createState() =>
      _ViewFamilyMembersPreferencesScreenState();
}

class _ViewFamilyMembersPreferencesScreenState
    extends State<ViewFamilyMembersPreferencesScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> members = [];
  Map<String, UserPreferences?> memberPreferences = {};
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    loadFamilyMembersWithPreferences();
    _initializeCameras();
  }

  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (_) {}
  }

  Future<void> _openScan() async {
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

  void _openScanHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanHistoryScreen(
          userId: widget.userId,
          userName: widget.userName,
          userEmail: widget.userEmail,
        ),
      ),
    );
  }

  Future<void> loadFamilyMembersWithPreferences() async {
    final data = await FamilyMemberApiService.getFamilyMembers(
      userId: widget.userId,
    );

    final Map<String, UserPreferences?> prefsMap = {};

    for (final member in data) {
      final memberId =
          member['_id']?.toString() ?? member['memberId']?.toString() ?? '';

      if (memberId.isNotEmpty) {
        final prefs = await PreferenceApiService.getPreferences(
          userId: widget.userId,
          memberId: memberId,
        );

        prefsMap[memberId] = prefs;
      }
    }

    if (!mounted) return;

    setState(() {
      members = data;
      memberPreferences = prefsMap;
      isLoading = false;
    });
  }

  Future<void> refreshData() async {
    setState(() => isLoading = true);
    await loadFamilyMembersWithPreferences();
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
              _buildTopHeader(),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: kPrimary),
                      )
                    : members.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: kPrimary,
                            onRefresh: refreshData,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 18, 16, 26),
                              itemCount: members.length,
                              itemBuilder: (context, index) {
                                return _buildMemberCard(members[index]);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Column(
      children: [
        Container(
          color: kBgCream,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: kPrimary,
                    size: 28,
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                      (route) => false,
                    );
                  },
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Family Member Preferences',
                    style: TextStyle(
                      color: kPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 44),
            ],
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
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'View Family Members',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'See all family members added by the primary user and their saved preferences.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.78),
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(18),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_2_outlined, color: kPrimary, size: 42),
            SizedBox(height: 12),
            Text(
              'No family members found.',
              style: TextStyle(
                color: kTextDark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Add family members first, then their preferences will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kTextMid,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final memberId =
        member['_id']?.toString() ?? member['memberId']?.toString() ?? '';

    final memberName = member['name']?.toString() ?? 'Family Member';
    final relation = member['relation']?.toString() ?? '';
    final age = member['age']?.toString() ?? '';
    final gender = member['gender']?.toString() ?? '';

    final prefs = memberPreferences[memberId];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMemberInfo(memberName, relation, age, gender),
          const SizedBox(height: 16),
          if (prefs == null)
            _buildNoPreferencesBox()
          else ...[
            _buildPreferenceSection(
              title: 'Dietary Preferences',
              items: prefs.diets
                  .where((item) => item.toLowerCase() != 'halal')
                  .toSet(),
              customItems: prefs.customDiets,
              importance: '',
            ),
            _buildPreferenceSection(
              title: 'Health Goals',
              items: prefs.nutritions,
              customItems: prefs.customNutritions,
              importance: '',
            ),
            _buildPreferenceSection(
              title: 'Allergies & Restrictions',
              items: {
                ...prefs.allergens,
                ...prefs.additives,
                ...prefs.ingredients,
                ...prefs.avoidedIngredients,
              },
              customItems: [
                ...prefs.customAllergens,
                ...prefs.customAdditives,
                ...prefs.customIngredients,
                ...prefs.customAvoidedIngredients,
              ],
              importance: '',
            ),
            _buildPreferenceSection(
              title: 'Religious Preferences',
              items: prefs.diets
                  .where((item) => item.toLowerCase() == 'halal')
                  .toSet(),
              customItems: const [],
              importance: '',
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: memberId.isEmpty
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PreferencesStartScreen(
                            userName: widget.userName,
                            userEmail: widget.userEmail,
                            userId: widget.userId,
                            memberId: memberId,
                            memberName: memberName,
                            preferences: prefs ?? UserPreferences(),
                          ),
                        ),
                      ).then((_) => refreshData());
                    },
              icon: const Icon(Icons.tune, size: 18),
              label: Text(
                prefs == null ? 'Set Preferences' : 'Edit Preferences',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openScan,
              icon: const Icon(Icons.qr_code_scanner, size: 18),
              label: const Text('Scan'),
              style: _outlineButtonStyle(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openScanHistory,
              icon: const Icon(Icons.history, size: 18),
              label: const Text('Scan History'),
              style: _outlineButtonStyle(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberInfo(
    String memberName,
    String relation,
    String age,
    String gender,
  ) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: kChipUnselected,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_outline, color: kPrimary),
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
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                memberName,
                style: const TextStyle(
                  color: kTextDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$relation  •  Age: $age  •  $gender',
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
    );
  }

  Widget _buildNoPreferencesBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBgCream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kPrimary.withOpacity(0.12)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: kPrimary, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'No preferences saved for this member yet.',
              style: TextStyle(
                color: kPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceSection({
    required String title,
    required Set<String> items,
    required List<String> customItems,
    required String importance,
  }) {
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
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
                    color: kPrimary,
                  ),
                ),
              ),
              if (importance.trim().isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: kChipUnselected,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    importance,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: kPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allItems
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  ButtonStyle _outlineButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: kPrimary,
      side: const BorderSide(color: kPrimary),
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}
