import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../services/session_service.dart';
import '../utils/validators.dart';
import 'Homepage.dart';
import 'login_page.dart';
import 'onboarding_screens.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {

  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullName = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController mobile = TextEditingController();
  final TextEditingController dob = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  bool hidePassword = true;
  bool isLoading = false;

  static const Color _teal = Color(0xFF2E8B72);
  static const Color _bg = Color(0xFFF5F9F7);

  Future<void> signUpWithEmail() async {

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      final url = Uri.parse("${AppConfig.apiBaseUrl}/register");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullName": fullName.text.trim(),
          "email": email.text.trim(),
          "password": password.text,
          "mobileNumber": mobile.text.trim(),
          "dateOfBirth": dob.text.trim(),
        }),
      );

      if (response.statusCode == 201) {

        final data = jsonDecode(response.body);

        if (mounted) {

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Sign Up Successful! Welcome ${data['user']['fullName']}"),
              backgroundColor: _teal,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
          );

          _formKey.currentState?.reset();
          fullName.clear();
          password.clear();
          email.clear();
          mobile.clear();
          dob.clear();
        }

      } else {

        final error = jsonDecode(response.body);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error['error'] ?? "Sign up failed"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

      }

    } catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }

    } finally {

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

    }
  }

  Future<void> signInWithGoogle() async {

    setState(() {
      isLoading = true;
    });

    try {

      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      String name = googleUser.displayName ?? "";
      String email = googleUser.email;
      String googleId = googleUser.id;

      await sendUserToServer(name, email, googleId, googleAuth.idToken);

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Google Sign In Successful"),
            backgroundColor: _teal,
            behavior: SnackBarBehavior.floating,
          ),
        );

        final userData = await SessionService.currentUserData();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(userData: userData),
          ),
        );
      }

    } catch (e) {

      if (mounted) {
        String errorMessage = "Google Sign In Failed. ";
        if (e.toString().contains("10")) {
          errorMessage += "Please check configuration.";
        } else {
          errorMessage += "Please try again later.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }

    } finally {

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

    }
  }

  Future<void> sendUserToServer(String name, String email, String googleId, String? idToken) async {

    final url = Uri.parse("${AppConfig.apiBaseUrl}/api/google-login");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "fullName": name,
        "email": email,
        "googleId": googleId,
        "idToken": idToken,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Failed to save user data");
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    await SessionService.saveUserSession(data);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 10),

                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OnboardingScreen(),
                      ),
                    );
                  },
                  color: Colors.black54,
                ),

                const SizedBox(height: 20),

                Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Create Account",
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
                        "Join NutriScan to start your healthy journey",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

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

                const SizedBox(height: 30),

                Center(
                  child: Image.asset(
                    "assets/images/Logo.png",
                    height: 120,
                    width: 120,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.restaurant_menu,
                        size: 80,
                        color: _teal.withOpacity(0.5),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [

                      buildField("Full Name", fullName, Icons.person_outline),

                      buildPasswordField(),

                      buildField("Email Address", email, Icons.email_outlined),

                      buildField("Mobile Number", mobile, Icons.phone_outlined),

                      buildDateField(),

                      const SizedBox(height: 24),

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
                          onPressed: isLoading ? null : signUpWithEmail,
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
                            "Create Account",
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
                              "or sign up with",
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
                              Text(
                                "G",
                                style: TextStyle(
                                  color: _teal,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Sign up with Google",
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

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            child: Text(
                              "Log In",
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

                      const SizedBox(height: 30),

                    ],
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

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
          keyboardType: label == "Email Address" ? TextInputType.emailAddress :
          label == "Mobile Number" ? TextInputType.phone :
          TextInputType.text,

          validator: (value) {
            if (label == "Email Address") return AppValidators.email(value);
            if (label == "Mobile Number") return AppValidators.mobile(value);
            return AppValidators.requiredText(value, label);
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
            return AppValidators.strongPassword(value);
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

  Widget buildDateField() {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Date of Birth",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: dob,
          readOnly: true,
          style: const TextStyle(fontSize: 15),

          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: "Select your date of birth",
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(Icons.calendar_today, color: _teal, size: 20),
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

          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
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

            if (pickedDate != null) {
              String formatted =
                  "${pickedDate.day.toString().padLeft(2, '0')}/"
                  "${pickedDate.month.toString().padLeft(2, '0')}/"
                  "${pickedDate.year}";

              setState(() {
                dob.text = formatted;
              });
            }
          },

          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select date of birth';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
