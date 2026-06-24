import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';

import 'scan_screen.dart';
import 'reports_screen.dart';
import 'health_dashboard_screen.dart';
import 'Homepage.dart';
import '../config/app_config.dart';
import 'Setting.dart';

class ScanHistoryScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userEmail;

  const ScanHistoryScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  int _selectedNav = 2;
  bool _loading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _history = [];
  List<CameraDescription>? _cameras;

  static String get apiBaseUrl => AppConfig.apiBaseUrl;
  static const Color _teal = Color(0xFF2E8B72);
  static const Color _bg = Color(0xFFF5F9F7);

  @override
  void initState() {
    super.initState();
    _fetchScanHistory();
    _initializeCameras();
  }

  void _goToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(
          userData: {
            'id': widget.userId,
            'fullName': widget.userName,
            'email': widget.userEmail,
          },
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      debugPrint('Camera init error: $e');
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

  Future<void> _fetchScanHistory() async {
    if (widget.userId.trim().isEmpty) {
      setState(() {
        _loading = false;
        _errorMessage = 'User ID not found. Please login again.';
      });
      return;
    }

    try {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });

      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/scan-history/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final List rawHistory = decoded is Map && decoded['history'] is List
            ? decoded['history']
            : decoded is List
            ? decoded
            : [];

        setState(() {
          _history = rawHistory
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _loading = false;
        });
      } else {
        final decoded = _safeDecode(response.body);

        setState(() {
          _loading = false;
          _errorMessage = decoded['message'] ?? 'Failed to load scan history.';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Unable to connect to server. Please try again.';
      });
      debugPrint('Fetch scan history error: $e');
    }
  }

  Future<void> _deleteScan(String scanId) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/api/scan-history/item/$scanId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _history.removeWhere((item) => item['_id'] == scanId);
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scan deleted successfully')),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete scan')));
      }
    } catch (e) {
      debugPrint('Delete scan error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Server connection error')));
    }
  }

  Map<String, dynamic> _safeDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }

  List<String> _ingredientsFromItem(Map<String, dynamic> item) {
    final raw = item['ingredients'];

    if (raw is List) {
      return raw
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    return [];
  }

  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return 'Unknown date';

    try {
      final date = DateTime.parse(rawDate.toString()).toLocal();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day/$month/$year • $hour:$minute';
    } catch (_) {
      return rawDate.toString();
    }
  }

  int _totalIngredients() {
    int total = 0;

    for (final item in _history) {
      final count = item['ingredientCount'];

      if (count is int) {
        total += count;
      } else {
        total += _ingredientsFromItem(item).length;
      }
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goToHome();
        return false;
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: _teal,
                  onRefresh: _fetchScanHistory,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(context),
                        _buildSummaryCard(),
                        const SizedBox(height: 18),
                        _buildContent(),
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                ),
              ),
              _buildBottomNav(),
            ],
          ),
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
            onTap: _goToHome,
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
                  'Scan History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Your saved ingredient scans',
                  style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: _teal,
            child: Text(
              widget.userName.isNotEmpty
                  ? widget.userName[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _teal,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _teal.withOpacity(0.18),
              blurRadius: 16,
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.28)),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saved Scans',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Review your previous food label checks',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _summaryMiniCard(
                    'Total Scans',
                    _history.length.toString(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryMiniCard(
                    'Ingredients',
                    _totalIngredients().toString(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryMiniCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator(color: _teal)),
      );
    }

    if (_errorMessage != null) {
      return _buildMessageState(
        icon: Icons.error_outline,
        title: 'Unable to Load History',
        message: _errorMessage!,
        buttonText: 'Try Again',
        onTap: _fetchScanHistory,
      );
    }

    if (_history.isEmpty) {
      return _buildMessageState(
        icon: Icons.history_toggle_off,
        title: 'No Scan History Yet',
        message:
            'Your scanned product ingredients will appear here after your first scan.',
        buttonText: 'Start Scanning',
        onTap: _navigateToScan,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _teal,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.list_alt,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Recent Scans',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _history.length,
            itemBuilder: (context, index) {
              return _buildHistoryCard(_history[index], index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item, int index) {
    final ingredients = _ingredientsFromItem(item);
    final count = item['ingredientCount'] ?? ingredients.length;
    final date = _formatDate(item['createdAt']);
    final id = item['_id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: _teal,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan #${_history.length - index}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      date,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black54),
                onSelected: (value) {
                  if (value == 'delete' && id.isNotEmpty) {
                    _confirmDelete(id);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$count ingredients detected',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _teal,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            ingredients.isEmpty
                ? 'No ingredients stored for this scan.'
                : ingredients.take(8).join(', '),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(String scanId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scan?'),
        content: const Text(
          'This scan history record will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteScan(scanId);
    }
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 36, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withOpacity(0.07)),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _teal.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _teal, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _teal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
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
                  if (i == 0) {
                    _goToHome();
                  } else if (isScan) {
                    setState(() => _selectedNav = i);
                    _navigateToScan();
                  } else if (i == 2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportsScreen(
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
                        builder: (context) => HealthDashboardScreen(
                          userId: widget.userId,
                          userName: widget.userName,
                          userEmail: widget.userEmail,
                        ),
                      ),
                    );
                  } else if (i == 4) {
                    setState(() => _selectedNav = i);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsScreen(
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
