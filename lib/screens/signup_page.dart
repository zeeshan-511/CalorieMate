import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool hidePassword = true;
  bool isLoading = false;

  final Color mainGreen = const Color(0xff2E8B7D);
  final Color fieldColor = const Color(0xffE6D8B5);

  Future<void> signUpWithEmail() async {

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      final url = Uri.parse("http://192.168.0.105:9000/register");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullName": fullName.text,
          "email": email.text,
          "password": password.text,
          "mobileNumber": mobile.text,
          "dateOfBirth": dob.text,
        }),
      );

      if (response.statusCode == 201) {

        final data = jsonDecode(response.body);

        if (mounted) {

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Sign Up Successful! Welcome ${data['user']['fullName']}"),
              backgroundColor: mainGreen,
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

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      String name = googleUser.displayName ?? "";
      String email = googleUser.email;
      String googleId = googleUser.id;

      await sendUserToServer(name, email, googleId);

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Google Sign In Successful"),
            backgroundColor: Color(0xff2E8B7D),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
      }

    } catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Google Sign In Failed: ${e.toString()}"),
            backgroundColor: Colors.red,
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

  Future<void> sendUserToServer(String name, String email, String googleId) async {

    final url = Uri.parse("http://192.168.0.116:9000/register");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "googleId": googleId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to save user data");
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.white,

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
                        builder: (context) => const OnboardingScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                // GREEN SIGNUP BAR
                Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    color: mainGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Center(
                  child: Image.asset(
                    "assets/images/Logo.png",
                    height: 200,
                  ),
                ),

                const SizedBox(height: 30),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [

                      buildField("Full Name", fullName, Icons.person),

                      buildPasswordField(),

                      buildField("Email", email, Icons.email),

                      buildField("Mobile Number", mobile, Icons.phone),

                      buildDateField(),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        height: 55,

                        child: ElevatedButton(

                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),

                          onPressed: isLoading ? null : signUpWithEmail,

                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text("or sign up with"),

                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: isLoading ? null : signInWithGoogle,
                        child: Container(
                          height: 45,
                          width: 45,
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.g_mobiledata,
                            color: mainGreen,
                            size: 32,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: () {

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );

                        },

                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black),
                            children: [

                              const TextSpan(
                                text: "Already have an account? ",
                              ),

                              TextSpan(
                                text: "Log In",
                                style: TextStyle(
                                  color: mainGreen,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),

                            ],
                          ),
                        ),
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

        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),

        const SizedBox(height: 6),

        TextFormField(

          controller: controller,

          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            if (label == "Email" && !value.contains('@')) {
              return 'Enter a valid email';
            }
            return null;
          },

          decoration: InputDecoration(
            filled: true,
            fillColor: fieldColor,
            prefixIcon: Icon(icon, color: mainGreen),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
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

        const Text("Password", style: TextStyle(fontWeight: FontWeight.bold)),

        const SizedBox(height: 6),

        TextFormField(

          controller: password,
          obscureText: hidePassword,

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
            fillColor: fieldColor,

            prefixIcon: Icon(Icons.lock, color: mainGreen),

            suffixIcon: IconButton(
              icon: Icon(
                hidePassword ? Icons.visibility_off : Icons.visibility,
                color: mainGreen,
              ),
              onPressed: () {
                setState(() {
                  hidePassword = !hidePassword;
                });
              },
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
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

        const Text("Date of Birth", style: TextStyle(fontWeight: FontWeight.bold)),

        const SizedBox(height: 6),

        TextFormField(

          controller: dob,
          readOnly: true,

          decoration: InputDecoration(
            filled: true,
            fillColor: fieldColor,

            prefixIcon: Icon(Icons.calendar_today, color: mainGreen),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),

          onTap: () async {

            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
            );

            if (pickedDate != null) {

              String formatted =
                  "${pickedDate.day.toString().padLeft(2, '0')} / "
                  "${pickedDate.month.toString().padLeft(2, '0')} / "
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