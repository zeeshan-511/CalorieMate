import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'scan_screen.dart';
import 'family_profile.dart';
import 'my_preferences.dart' as myprefs; // Import the preferences page
import 'view_preferences.dart';
import 'view_family_members.dart';
import 'view_family_preferences.dart';
import 'family_requests_screen.dart';
import 'ScanHistory.dart';
import 'reports_screen.dart';
import 'health_dashboard_screen.dart';

// ─────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────
class _FeatureCard {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  const _FeatureCard(this.icon, this.label, this.bgColor, this.iconColor);
}

class _BlogPost {
  final String tag;
  final String title;
  final Color tagColor;
  final Color tagBg;
  final IconData icon;
  const _BlogPost(this.tag, this.title, this.tagColor, this.tagBg, this.icon);
}

// ─────────────────────────────────────────────
//  SIDEBAR DRAWER
// ─────────────────────────────────────────────
class AppDrawer extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String userId;
  final VoidCallback? onScanTap;

  const AppDrawer({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userId,
    this.onScanTap,
  });

  static const Color _teal = Color(0xFF2E8B72);

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
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
                      onTap: onScanTap,
                    ),
                    _divider(),

                    // ✅ Preferences Section FIRST
                    _DrawerItem(
                      icon: Icons.tune,
                      label: 'Set your Preferences',
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

                    _DrawerItem(
                      icon: Icons.visibility,
                      label: 'See your Preferences',
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

                    // ✅ Family Section AFTER
                    _DrawerItem(
                      icon: Icons.people_outline,
                      label: 'Add Family Member',
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
                      icon: Icons.groups_2_outlined,
                      label: 'View Family Members',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ViewFamilyMembersScreen(userId: userId),
                          ),
                        );
                      },
                    ),

                    _divider(),

                    _DrawerItem(
                      icon: Icons.groups_2_outlined,
                      label: 'View Family Preferences',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ViewFamilyMembersPreferencesScreen(
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
                      icon: Icons.notifications_active_outlined,
                      label: 'Family Requests',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FamilyRequestsScreen(
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
                      icon: Icons.history,
                      label: 'Scan History',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScanHistoryScreen(
                              userId: userId,
                              userEmail: userEmail,
                              userName: userName,
                            ),
                          ),
                        );
                      },
                    ),

                    _divider(),

                    _DrawerItem(
                      icon: Icons.assignment_outlined,
                      label: 'Food Reports',
                      onTap: () {
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
                      },
                    ),

                    _divider(),

                    _DrawerItem(
                      icon: Icons.favorite_outline,
                      label: 'My Health',
                      onTap: () {
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
                      },
                    ),

                    _divider(),

                    _DrawerItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                    ),
                    _divider(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                child: GestureDetector(
                  onTap: () => _logout(context),
                  child: const _DrawerItem(
                    icon: Icons.logout,
                    label: 'Log Out',
                  ),
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
              content: Text('$label feature coming soon!'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
    );
  }
}

// ─────────────────────────────────────────────
//  NUTRI SCAN APP
// ─────────────────────────────────────────────
class NutriScanApp extends StatelessWidget {
  const NutriScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CalorieMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFF5F9F7),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E8B72)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ─────────────────────────────────────────────
//  HOME PAGE
// ─────────────────────────────────────────────
class HomePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const HomePage({super.key, this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _selectedNav = 0;
  late String userName = '';
  late String userEmail = '';
  late String userId = '';
  List<CameraDescription>? _cameras;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const Color _teal = Color(0xFF2E8B72);
  static const Color _bg = Color(0xFFF5F9F7);

  final List<_FeatureCard> _features = const [
    _FeatureCard(
      Icons.qr_code_scanner,
      'Scan',
      Color(0xFFE1F5EE),
      Color(0xFF0F6E56),
    ),
    _FeatureCard(
      Icons.family_restroom_outlined,
      'Add Family',
      Color(0xFFE1F5EE),
      Color(0xFF0F6E56),
    ),
    _FeatureCard(
      Icons.notifications_active_outlined,
      'Requests',
      Color(0xFFE6F1FB),
      Color(0xFF185FA5),
    ),
    _FeatureCard(
      Icons.history,
      'History',
      Color(0xFFFAEEDA),
      Color(0xFF854F0B),
    ),
  ];

  final List<_BlogPost> _blogPosts = const [
    _BlogPost(
      'Nutrition',
      'What does the Nutri-Score really mean?',
      Color(0xFF0F6E56),
      Color(0xFFE1F5EE),
      Icons.eco_outlined,
    ),
    _BlogPost(
      'Labels',
      'Top 5 hidden sugars to watch out for',
      Color(0xFF854F0B),
      Color(0xFFFAEEDA),
      Icons.search_outlined,
    ),
    _BlogPost(
      'Lifestyle',
      'How to read food labels like a pro',
      Color(0xFF185FA5),
      Color(0xFFE6F1FB),
      Icons.menu_book_outlined,
    ),
    _BlogPost(
      'Health',
      'Palm oil: what the science actually says',
      Color(0xFFA32D2D),
      Color(0xFFFCEBEB),
      Icons.science_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeCameras();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (widget.userData != null && widget.userData!.isNotEmpty) {
      userName = widget.userData!['fullName'] ?? 'Guest User';
      userEmail = widget.userData!['email'] ?? 'guest@example.com';
      userId = widget.userData!['id'] ?? '';
    } else {
      final prefs = await SharedPreferences.getInstance();
      userName = prefs.getString('user_name') ?? 'Guest User';
      userEmail = prefs.getString('user_email') ?? 'guest@example.com';
      userId = prefs.getString('user_id') ?? '';
    }
    if (mounted) setState(() {});
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      drawer: AppDrawer(
        userName: userName,
        userEmail: userEmail,
        userId: userId,
        onScanTap: _navigateToScan,
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
                    _buildHeroScanSection(),
                    _buildFeatureCards(),
                    _buildHowItWorks(),
                    _buildNutritionTips(),
                    const SizedBox(height: 20),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back',
                  style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
                ),
                Text(
                  userName.split(' ').first,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              const Icon(
                Icons.notifications_none,
                size: 28,
                color: Colors.black87,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => myprefs.AdditivesPreferencesScreen(
                    userName: userName,
                    userEmail: userEmail,
                    userId: userId,
                    preferences: myprefs.UserPreferences(),
                  ),
                ),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: const Icon(Icons.tune, size: 20, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroScanSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: _pulseAnimation.value * 1.3,
                      child: Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _teal.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: _pulseAnimation.value * 1.15,
                      child: Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _teal.withOpacity(0.4),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _navigateToScan,
                      child: Container(
                        width: 86,
                        height: 86,
                        decoration: const BoxDecoration(
                          color: _teal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Scan Your Food. Know What You Eat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Personalized nutrition guidance from your saved preferences',
            style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCards() {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _features.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final f = _features[i];
          return GestureDetector(
            onTap: () {
              if (i == 0) {
                _navigateToScan();
              } else if (i == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FamilyProfileSetupScreen(
                      userId: userId,
                      userName: userName,
                    ),
                  ),
                );
              } else if (i == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FamilyRequestsScreen(
                      userId: userId,
                      userName: userName,
                      userEmail: userEmail,
                    ),
                  ),
                );
              } else {
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
              }
            },
            child: Container(
              width: 82,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.07)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: f.bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(f.icon, color: f.iconColor, size: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    f.label,
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHowItWorks() {
    final steps = [
      {
        'icon': Icons.qr_code_scanner,
        'label': 'Scan\nProduct',
        'color': const Color(0xFFE1F5EE),
        'iconColor': const Color(0xFF0F6E56),
      },
      {
        'icon': Icons.psychology_outlined,
        'label': 'Match Saved\nPreferences',
        'color': const Color(0xFFE6F1FB),
        'iconColor': const Color(0xFF185FA5),
      },
      {
        'icon': Icons.favorite_outline,
        'label': 'Get Health\nInsights',
        'color': const Color(0xFFFCEBEB),
        'iconColor': const Color(0xFFA32D2D),
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How it works',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.07)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Row(
              children: [
                for (int i = 0; i < steps.length; i++) ...[
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: steps[i]['color'] as Color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            steps[i]['icon'] as IconData,
                            color: steps[i]['iconColor'] as Color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          steps[i]['label'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < steps.length - 1)
                    Container(
                      width: 24,
                      height: 1,
                      color: Colors.black.withOpacity(0.15),
                      margin: const EdgeInsets.only(bottom: 24),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionTips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Nutrition tips',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text('See all', style: TextStyle(fontSize: 13, color: _teal)),
            ],
          ),
          const SizedBox(height: 12),
          ..._blogPosts.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BlogCard(post: post),
            ),
          ),
        ],
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
                  setState(() => _selectedNav = i);
                  if (isScan) {
                    _navigateToScan();
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
                    ).then((_) {
                      if (mounted) setState(() => _selectedNav = 0);
                    });
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
                    ).then((_) {
                      if (mounted) setState(() => _selectedNav = 0);
                    });
                  } else if (i != 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${navItems[i]['label']} feature coming soon!',
                        ),
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

class _BlogCard extends StatelessWidget {
  final _BlogPost post;
  const _BlogCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: post.tagBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(post.icon, color: post.tagColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: post.tagBg,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    post.tag,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: post.tagColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: Color(0xFFBBBBBB)),
        ],
      ),
    );
  }
}
