import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'scan_screen.dart';
import 'family_profile.dart';

class NutriScanApp extends StatelessWidget {
  const NutriScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriScan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFFFF8EC),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E8B72)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ─────────────────────────────────────────────
//  SIDEBAR DRAWER - Updated with userId and userName
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
    // Clear SharedPreferences on logout
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
              // ── Profile header with dynamic user data ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: ClipOval(
                        child: Container(
                          width: 60,
                          height: 60,
                          color: Colors.white24,
                          child: Center(
                            child: Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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

              // ── Menu items ──
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
                    _DrawerItem(
                      icon: Icons.people_outline,
                      label: 'Family Profile',
                      onTap: () {
                        // Close drawer first
                        Navigator.pop(context);

                        // Navigate to FamilyProfileSetupScreen with user data
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
                    _DrawerItem(icon: Icons.history, label: 'Scan History'),
                    _divider(),
                    _DrawerItem(icon: Icons.tune, label: 'Set Preferences'),
                    _divider(),
                    _DrawerItem(icon: Icons.list_alt_outlined, label: 'My Preferences'),
                    _divider(),
                    _DrawerItem(icon: Icons.compare_arrows, label: 'Compare Products'),
                    _divider(),
                    _DrawerItem(icon: Icons.settings_outlined, label: 'Settings'),
                    _divider(),
                  ],
                ),
              ),

              // ── Log Out ──
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                child: GestureDetector(
                  onTap: () => _logout(context),
                  child: const _DrawerItem(icon: Icons.logout, label: 'Log Out'),
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
        Navigator.pop(context); // Close drawer
        if (onTap != null) {
          onTap!(); // Call the provided callback
        } else {
          // Show coming soon for other menu items
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
//  HOME PAGE - Updated with SharedPreferences backup
// ─────────────────────────────────────────────
class HomePage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const HomePage({super.key, this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedNav = 0;
  late String userName;
  late String userEmail;
  late String userId;
  List<CameraDescription>? _cameras;

  static const Color _teal = Color(0xFF2E8B72);
  static const Color _bg = Color(0xFFFFF8EC);

  final List<_CategoryItem> _categories = [
    _CategoryItem(Icons.lunch_dining, 'Chips'),
    _CategoryItem(Icons.local_drink, 'Soft Drink'),
    _CategoryItem(Icons.cookie, 'Chocolate'),
    _CategoryItem(Icons.local_bar, 'Juice'),
    _CategoryItem(Icons.breakfast_dining, 'Cereal'),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeCameras();
  }

  Future<void> _loadUserData() async {
    // First try to get from widget.userData
    if (widget.userData != null && widget.userData!.isNotEmpty) {
      userName = widget.userData!['fullName'] ?? 'Guest User';
      userEmail = widget.userData!['email'] ?? 'guest@example.com';
      userId = widget.userData!['id'] ?? '';
    } else {
      // If no userData, try to load from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      userName = prefs.getString('user_name') ?? 'Guest User';
      userEmail = prefs.getString('user_email') ?? 'guest@example.com';
      userId = prefs.getString('user_id') ?? '';
    }

    if (mounted) {
      setState(() {});
    }
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
                    _buildGreeting(),
                    _buildCategoryRow(),
                    _buildDiscoverSection(),
                    _buildBannerCard(),
                    _buildSeeMore(),
                    const SizedBox(height: 16),
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

  // ── Top bar with user initial ──
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _teal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.tune, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            children: [
              const Icon(Icons.notifications_none, size: 28, color: Colors.black87),
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
          const SizedBox(width: 10),
          Builder(builder: (ctx) {
            return GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: _teal,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'G',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Greeting with user's name ──
  Widget _buildGreeting() {
    String firstName = userName.split(' ').first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good Morning, $firstName!',
            style: const TextStyle(
              color: Color(0xFF2E8B72),
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            "Rise And Shine! It's Time To Make The Right Choices",
            style: TextStyle(
              color: Color(0xFF2E8B72),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── Category chips row ──
  Widget _buildCategoryRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _categories.map((c) => _CategoryChip(item: c)).toList(),
      ),
    );
  }

  // ── Discover with asset images ──
  Widget _buildDiscoverSection() {
    final products = [
      _ProductCard("Lay's", 'assets/images/lays.png'),
      _ProductCard('Pure Magic', 'assets/images/pure_magic.png'),
      _ProductCard('7UP', 'assets/images/7up.png'),
      _ProductCard('Munch', 'assets/images/munch.png'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Discover',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: const [
                  Text(
                    'View All',
                    style: TextStyle(color: _teal, fontSize: 13),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right, color: _teal, size: 18),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _ProductTile(data: products[i]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner with Nutella asset image ──
  Widget _buildBannerCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 150,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF8C00), Color(0xFFFFB347)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Check out the Nutri-Score of your product for a quick glance at its nutritional quality! Make informed choices with just a scan!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                child: Image.asset(
                  'assets/images/nutella.png',
                  width: 130,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 130,
                    color: Colors.orange.shade300,
                    child: const Icon(Icons.image, color: Colors.white, size: 40),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── See more with asset images ──
  Widget _buildSeeMore() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'See more',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SeeMoreCard(
                  imageUrl: 'assets/images/mccain.png',
                  name: 'McCain\nChilli Garlic\nPotato Bites',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SeeMoreCard(
                  imageUrl: 'assets/images/malas.png',
                  name: "Mala's\nStrawberry\nJam",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bottom Nav with scan navigation ──
  Widget _buildBottomNav() {
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
        color: const Color(0xFF2E8B72),
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

              if (i == 1) { // Scan button
                _navigateToScan();
              } else if (i != 0) { // Show coming soon for other nav items except home
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
//  SMALL WIDGETS (Unchanged)
// ─────────────────────────────────────────────
class _CategoryItem {
  final IconData icon;
  final String label;
  const _CategoryItem(this.icon, this.label);
}

class _CategoryChip extends StatelessWidget {
  final _CategoryItem item;
  const _CategoryChip({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0CC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(item.icon, color: const Color(0xFF2E8B72), size: 26),
        ),
        const SizedBox(height: 6),
        Text(
          item.label,
          style: const TextStyle(fontSize: 11, color: Colors.black87),
        ),
      ],
    );
  }
}

class _ProductCard {
  final String name;
  final String imageUrl;
  const _ProductCard(this.name, this.imageUrl);
}

class _ProductTile extends StatelessWidget {
  final _ProductCard data;
  const _ProductTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          data.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFFFF0CC),
            child: Center(
              child: Text(
                data.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeeMoreCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  const _SeeMoreCard({required this.imageUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFFFF0CC),
                  child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}