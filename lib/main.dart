import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (error) {
    debugPrint('Environment load skipped: $error');
  }

  CameraDescription? firstCamera;
  try {
    if (!kIsWeb) {
      await Permission.camera.request();
      await Permission.storage.request();
    }
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) firstCamera = cameras.first;
  } catch (error) {
    debugPrint('Camera initialization deferred: $error');
  }

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription? camera;
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

class SplashScreenWrapper extends StatefulWidget {
  final CameraDescription? camera;
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
