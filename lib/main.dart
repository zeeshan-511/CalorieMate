import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screens.dart'; // Import onboarding screens
// Remove scan_screen import from here

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request permissions
  await Permission.camera.request();
  await Permission.storage.request();

  // Get available cameras (you'll need this later for scan screen)
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  const MyApp({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriScan',
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFFFF8EC),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E8B72)),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreenWrapper(camera: camera),
    );
  }
}

// Wrapper to navigate from SplashScreen to OnboardingScreen
class SplashScreenWrapper extends StatefulWidget {
  final CameraDescription camera;
  const SplashScreenWrapper({Key? key, required this.camera}) : super(key: key);

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  @override
  void initState() {
    super.initState();
    _navigateToOnboarding();
  }

  Future<void> _navigateToOnboarding() async {
    // Wait 2.5 seconds on splash screen
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const OnboardingScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}