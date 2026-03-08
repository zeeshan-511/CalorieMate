import 'package:flutter/material.dart';

/// STEP INDICATOR
class StepIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const StepIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep - 1;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 28,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF00A082)
                : const Color(0xFFFFE5A0),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}

/// ONBOARDING SCREEN
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 1;

  final List<Map<String, String>> _data = [
    {
      'bg': 'assets/images/screen1.png',
      'image': 'assets/images/health_icon.png',
      'title': 'Discover Healthier Choices',
      'desc':
      'Scan packaged foods and get instant nutrition insights with confidence.',
    },
    {
      'bg': 'assets/images/screen2.png',
      'image': 'assets/images/compare.png',
      'title': 'Scan Products Easily',
      'desc':
      'Use your camera to scan barcodes and understand what you eat.',
    },
    {
      'bg': 'assets/images/screen3.png',
      'image': 'assets/images/History.png',
      'title': 'Detailed Nutrition',
      'desc':
      'See Nutri-Score, NOVA rating, and ingredient breakdown instantly.',
    },
    {
      'bg': 'assets/images/screen4.png',
      'image': 'assets/images/compare.png',
      'title': 'Start Your Healthy Journey',
      'desc':
      'Make smarter food choices and live a healthier lifestyle.',
    },
  ];

  void _next() {
    if (_currentStep < _data.length) {
      setState(() => _currentStep++);
    } else {
      // TODO: Navigate to Login/Home screen
    }
  }

  void _back() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  void _skip() {
    // TODO: Navigate to Login/Home screen
  }

  @override
  Widget build(BuildContext context) {
    final item = _data[_currentStep - 1];
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          /// BACKGROUND IMAGE (TOP 60%)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.6,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(item['bg']!),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
          ),

          /// BACK BUTTON
          if (_currentStep > 1)
            Positioned(
              top: 50,
              left: 16,
              child: IconButton(
                onPressed: _back,
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                ),
              ),
            ),

          /// SKIP BUTTON
          Positioned(
            top: 50,
            right: 16,
            child: TextButton(
              onPressed: _skip,
              child: const Text(
                'Skip >',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),

          /// BOTTOM CONTENT
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    item['image']!,
                    width: 120,
                    height: 120,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    item['title']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00A082),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    item['desc']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      height: 1.5,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 24),

                  StepIndicator(
                    totalSteps: _data.length,
                    currentStep: _currentStep,
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A082),
                        padding:
                        const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _currentStep == _data.length
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
