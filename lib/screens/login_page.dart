import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'signup_page.dart';
import 'Homepage.dart';
import 'onboarding_screens.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  bool hidePassword = true;
  bool isLoading = false;

  static const Color _teal = Color(0xFF2E8B72);
  static const Color _bg = Color(0xFFF5F9F7);

  // Base URL
  final String baseUrl = "http://192.168.0.114:9000";

  /// LOGIN WITH EMAIL
  Future<void> loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final url = Uri.parse("$baseUrl/login");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email.text.trim(),
          "password": password.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save token and user data in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token'] ?? '');
        await prefs.setString('user_id', data['user']['_id']);
        await prefs.setString('user_name', data['user']['fullName']);
        await prefs.setString('user_email', data['user']['email']);
        await prefs.setBool('is_logged_in', true);

        // Create userData map with all required fields including id
        final userData = {
          'id': data['user']['_id'],
          'fullName': data['user']['fullName'],
          'email': data['user']['email'],
        };

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Welcome ${data['user']['fullName']}"),
            backgroundColor: _teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // Navigate to HomePage with user data
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(userData: userData),
          ),
        );
      } else {
        final error = jsonDecode(response.body);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error['message'] ?? "Login failed"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connection error: Please check your internet"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    setState(() => isLoading = false);
  }

  /// GOOGLE LOGIN - FIXED VERSION
  Future<void> signInWithGoogle() async {
    setState(() => isLoading = true);

    try {
      // Disconnect any existing connection first
      await _googleSignIn.disconnect();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Here you would typically send the token to your backend
      // For now, we'll create a mock response or send to your API
      final response = await http.post(
        Uri.parse("$baseUrl/api/google-login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": googleUser.displayName,
          "email": googleUser.email,
          "googleId": googleUser.id,
          "idToken": googleAuth.idToken,
          "accessToken": googleAuth.accessToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save token and user data in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token'] ?? '');
        await prefs.setString('user_id', data['user']['_id']);
        await prefs.setString('user_name', data['user']['fullName'] ?? googleUser.displayName ?? '');
        await prefs.setString('user_email', data['user']['email'] ?? googleUser.email);
        await prefs.setBool('is_logged_in', true);

        // Create userData map with all required fields including id
        final userData = {
          'id': data['user']['_id'],
          'fullName': data['user']['fullName'] ?? googleUser.displayName ?? 'Google User',
          'email': data['user']['email'] ?? googleUser.email,
        };

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Google Sign In Successful"),
            backgroundColor: _teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // Navigate to HomePage with user data
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(userData: userData),
          ),
        );
      } else {
        final error = jsonDecode(response.body);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error['message'] ?? "Google login failed"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      print("Google Sign-In Error: $e");

      if (!mounted) return;

      // More user-friendly error message
      String errorMessage = "Google Sign In Failed. ";
      if (e.toString().contains("10")) {
        errorMessage += "Please check your SHA-1 fingerprint in Firebase Console.";
      } else if (e.toString().contains("NETWORK_ERROR")) {
        errorMessage += "Please check your internet connection.";
      } else {
        errorMessage += "Please try again later.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            /// BACK BUTTON - Now navigates to onboarding
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {
                  // Navigate back to onboarding screens
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                        (route) => false,
                  );
                },
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 20),

            /// ATTRACTIVE HEADER SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  /// Welcome Text
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Sign in to continue your healthy journey",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  /// Decorative Line
                  Container(
                    height: 4,
                    width: 60,
                    decoration: BoxDecoration(
                      color: _teal,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// MAIN FORM
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        /// LOGO (Smaller, more elegant)
                        Container(
                          height: 100,
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Image.asset(
                            "assets/images/Logo.png",
                            height: 100,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: _teal.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.restaurant_menu,
                                  size: 50,
                                  color: _teal.withOpacity(0.5),
                                ),
                              );
                            },
                          ),
                        ),

                        buildField("Email Address", email, Icons.email_outlined),

                        buildPasswordField(),

                        /// Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Forgot Password feature coming soon!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: _teal,
                            ),
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        /// LOGIN BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _teal,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: isLoading ? null : loginWithEmail,
                            child: isLoading
                                ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              "Sign In",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[300])),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "or continue with",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[300])),
                          ],
                        ),

                        const SizedBox(height: 24),

                        /// GOOGLE LOGIN - Improved button
                        GestureDetector(
                          onTap: isLoading ? null : signInWithGoogle,
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey[300]!, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Google G Logo
                                Image.network(
                                  'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                  height: 24,
                                  width: 24,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Text(
                                      "G",
                                      style: TextStyle(
                                        color: _teal,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Sign in with Google",
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        /// SIGNUP NAVIGATION
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "New to NutriScan? ",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignUpPage(),
                                  ),
                                );
                              },
                              child: Text(
                                "Create Account",
                                style: TextStyle(
                                  color: _teal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                  decorationColor: _teal,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// EMAIL FIELD
  Widget buildField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(fontSize: 15),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            if (label == "Email Address" && !value.contains('@')) {
              return 'Enter a valid email address';
            }
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, color: _teal, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _teal, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// PASSWORD FIELD
  Widget buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Password",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: password,
          obscureText: hidePassword,
          style: const TextStyle(fontSize: 15),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(Icons.lock_outline, color: _teal, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: _teal,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  hidePassword = !hidePassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _teal, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}