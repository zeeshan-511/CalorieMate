import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../services/session_service.dart';
import '../utils/validators.dart';
import 'Homepage.dart';
import 'ScanHistory.dart';
import 'family_profile.dart';
import 'health_dashboard_screen.dart';
import 'login_page.dart';
import 'my_preferences.dart' as myprefs;
import 'reports_screen.dart';
import 'view_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userEmail;

  const SettingsScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _dobController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _emailNotifications = true;
  bool _familySharing = true;
  bool _saveScanHistory = true;
  bool _recommendationAlerts = true;
  String _error = '';

  static const Color _teal = Color(0xFF2E8B72);
  static const Color _bg = Color(0xFFF5F9F7);

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userName;
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    if (widget.userId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Please sign in again to manage settings.';
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/users/${widget.userId}/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer dummy-token-${widget.userId}',
        },
      );
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (response.statusCode == 200) {
        final user = Map<String, dynamic>.from(decoded['user'] as Map? ?? {});
        final settings = Map<String, dynamic>.from(decoded['settings'] as Map? ?? {});
        setState(() {
          _nameController.text = user['fullName']?.toString() ?? widget.userName;
          _mobileController.text = user['mobileNumber']?.toString() ?? '';
          _dobController.text = user['dateOfBirth']?.toString() ?? '';
          _emailNotifications = settings['emailNotifications'] != false;
          _familySharing = settings['familySharing'] != false;
          _saveScanHistory = settings['saveScanHistory'] != false;
          _recommendationAlerts = settings['recommendationAlerts'] != false;
          _loading = false;
        });
      } else {
        setState(() {
          _error = decoded['message']?.toString() ?? 'Unable to load settings.';
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to connect to the server.';
        _loading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/api/users/${widget.userId}/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer dummy-token-${widget.userId}',
        },
        body: jsonEncode({
          'fullName': _nameController.text.trim(),
          'mobileNumber': _mobileController.text.trim(),
          'dateOfBirth': _dobController.text.trim(),
          'settings': {
            'emailNotifications': _emailNotifications,
            'familySharing': _familySharing,
            'saveScanHistory': _saveScanHistory,
            'recommendationAlerts': _recommendationAlerts,
          },
        }),
      );
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (response.statusCode == 200) {
        final user = Map<String, dynamic>.from(decoded['user'] as Map? ?? {});
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', user['fullName']?.toString() ?? _nameController.text.trim());
        await prefs.setString('user_email', user['email']?.toString() ?? widget.userEmail);
        if (!mounted) return;
        _showSnack('Settings saved successfully.', false);
      } else {
        _showSnack(decoded['message']?.toString() ?? 'Unable to save settings.', true);
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Unable to connect to the server.', true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await SessionService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _teal,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    _dobController.text =
        '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
  }

  void _showSnack(String message, bool error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : _teal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomePage(
          userData: {
            'id': widget.userId,
            'fullName': _nameController.text.trim().isEmpty
                ? widget.userName
                : _nameController.text.trim(),
            'email': widget.userEmail,
          },
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _goHome,
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _teal))
            : _error.isNotEmpty
                ? _ErrorState(message: _error, onRetry: _loadSettings)
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                      children: [
                        _HeaderCard(
                          userName: _nameController.text.trim().isEmpty
                              ? widget.userName
                              : _nameController.text.trim(),
                          userEmail: widget.userEmail,
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Profile',
                          icon: Icons.person_outline,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              validator: (value) =>
                                  AppValidators.requiredText(value, 'full name'),
                              decoration: _inputDecoration('Full name', Icons.badge_outlined),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              initialValue: widget.userEmail,
                              readOnly: true,
                              decoration: _inputDecoration('Email address', Icons.email_outlined),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              validator: AppValidators.optionalMobile,
                              decoration: _inputDecoration('Mobile number', Icons.phone_outlined),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _dobController,
                              readOnly: true,
                              onTap: _pickDate,
                              decoration: _inputDecoration('Date of birth', Icons.calendar_today_outlined),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'App Settings',
                          icon: Icons.tune_outlined,
                          children: [
                            _SwitchRow(
                              title: 'Email notifications',
                              subtitle: 'Receive reset, invitation, and family request emails.',
                              value: _emailNotifications,
                              onChanged: (value) => setState(() => _emailNotifications = value),
                            ),
                            _SwitchRow(
                              title: 'Family sharing',
                              subtitle: 'Allow family product sharing and recommendation alerts.',
                              value: _familySharing,
                              onChanged: (value) => setState(() => _familySharing = value),
                            ),
                            _SwitchRow(
                              title: 'Save scan history',
                              subtitle: 'Keep OCR, ingredients, reports, and recommendations in MongoDB.',
                              value: _saveScanHistory,
                              onChanged: (value) => setState(() => _saveScanHistory = value),
                            ),
                            _SwitchRow(
                              title: 'Recommendation alerts',
                              subtitle: 'Show warnings when products conflict with your profile.',
                              value: _recommendationAlerts,
                              onChanged: (value) => setState(() => _recommendationAlerts = value),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Quick Actions',
                          icon: Icons.apps_outlined,
                          children: [
                            _ActionTile(
                              icon: Icons.tune,
                              title: 'Set Preferences',
                              subtitle: 'Update diet, health goals, allergies, and restrictions.',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => myprefs.AdditivesPreferencesScreen(
                                    userName: widget.userName,
                                    userEmail: widget.userEmail,
                                    userId: widget.userId,
                                    preferences: myprefs.UserPreferences(),
                                  ),
                                ),
                              ),
                            ),
                            _ActionTile(
                              icon: Icons.visibility_outlined,
                              title: 'View Preferences',
                              subtitle: 'Review your saved personalization profile.',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ViewPreferencesScreen(
                                    userId: widget.userId,
                                    userName: widget.userName,
                                    userEmail: widget.userEmail,
                                  ),
                                ),
                              ),
                            ),
                            _ActionTile(
                              icon: Icons.family_restroom_outlined,
                              title: 'Family Members',
                              subtitle: 'Add family profiles and manage family preferences.',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FamilyProfileSetupScreen(
                                    userId: widget.userId,
                                    userName: widget.userName,
                                  ),
                                ),
                              ),
                            ),
                            _ActionTile(
                              icon: Icons.history,
                              title: 'Scan History',
                              subtitle: 'Open saved OCR and product analysis history.',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ScanHistoryScreen(
                                    userId: widget.userId,
                                    userName: widget.userName,
                                    userEmail: widget.userEmail,
                                  ),
                                ),
                              ),
                            ),
                            _ActionTile(
                              icon: Icons.assignment_outlined,
                              title: 'Reports',
                              subtitle: 'View full health reports and recommendation outcomes.',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReportsScreen(
                                    userId: widget.userId,
                                    userName: widget.userName,
                                    userEmail: widget.userEmail,
                                  ),
                                ),
                              ),
                            ),
                            _ActionTile(
                              icon: Icons.favorite_outline,
                              title: 'Health Dashboard',
                              subtitle: 'See health goals, warnings, and recent insights.',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HealthDashboardScreen(
                                    userId: widget.userId,
                                    userName: widget.userName,
                                    userEmail: widget.userEmail,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Connection',
                          icon: Icons.wifi_tethering,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE1F5EE),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                AppConfig.apiBaseUrl,
                                style: const TextStyle(
                                  color: _teal,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _saveSettings,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(_saving ? 'Saving...' : 'Save Settings'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _teal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 54,
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout),
                            label: const Text('Log Out'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _teal),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _teal, width: 2),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String userName;
  final String userEmail;

  const _HeaderCard({
    required this.userName,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2E8B72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              userName.trim().isEmpty ? 'U' : userName.trim()[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF2E8B72),
                fontWeight: FontWeight.w900,
                fontSize: 22,
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
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: const TextStyle(color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2E8B72)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF2E8B72),
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.black54, height: 1.35),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFE1F5EE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF2E8B72)),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.black54),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

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
            const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B72),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
