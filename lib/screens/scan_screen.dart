import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'ResultScreen.dart';

class ScanScreen extends StatefulWidget {
  final CameraDescription camera;

  const ScanScreen({Key? key, required this.camera}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  bool _isScanning = false;
  bool _flashOn = false;

  static const Color _teal = Color(0xFF2E8B72);

  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _initializeControllerFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _controller.initialize();

    try {
      await _controller.setFlashMode(FlashMode.off);
      await _controller.setFocusMode(FocusMode.auto);
      await _controller.setExposureMode(ExposureMode.auto);
    } catch (_) {
      // Some devices do not support all focus/exposure modes.
    }

    if (mounted) {
      setState(() {
        _flashOn = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    try {
      await _initializeControllerFuture;

      if (_flashOn) {
        await _controller.setFlashMode(FlashMode.off);
      } else {
        await _controller.setFlashMode(FlashMode.torch);
      }

      if (!mounted) return;
      setState(() {
        _flashOn = !_flashOn;
      });
    } catch (e) {
      debugPrint('Flash toggle error: $e');
    }
  }

  Future<void> _scanIngredientsText() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
    });

    try {
      await _initializeControllerFuture;

      // Keep flash off unless user manually enabled torch.
      if (!_flashOn) {
        await _controller.setFlashMode(FlashMode.off);
      }

      try {
        await _controller.setFocusMode(FocusMode.auto);
        await _controller.setExposureMode(ExposureMode.auto);
      } catch (_) {}

      // Small delay helps the camera focus before capture.
      await Future.delayed(const Duration(milliseconds: 450));

      final image = await _controller.takePicture();

      if (!mounted) return;

      _showLoadingDialog();

      final result = await ApiService.scanLabel(File(image.path));

      if (!mounted) return;
      Navigator.pop(context); // close loading dialog

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => ResultScreen(data: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      try {
        Navigator.pop(context);
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_teal),
                ),
                const SizedBox(height: 16),
                Text(
                  'Reading ingredients text...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScannerFrame() {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.86,
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -2,
              top: -2,
              child: _corner(),
            ),
            Positioned(
              right: -2,
              top: -2,
              child: Transform.rotate(
                angle: 1.5708,
                child: _corner(),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Transform.rotate(
                angle: 3.1416,
                child: _corner(),
              ),
            ),
            Positioned(
              left: -2,
              bottom: -2,
              child: Transform.rotate(
                angle: 4.7124,
                child: _corner(),
              ),
            ),
            const Center(
              child: Text(
                'Place only ingredients text here',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _corner() {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _teal, width: 5),
          left: BorderSide(color: _teal, width: 5),
        ),
      ),
    );
  }

  Widget _buildTopInstruction() {
    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.72),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.text_snippet_outlined, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Scan ingredients section only, not story text or front label',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashButton() {
    return Positioned(
      top: 16,
      right: 16,
      child: SafeArea(
        child: GestureDetector(
          onTap: _toggleFlash,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.62),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(
              _flashOn ? Icons.flash_on : Icons.flash_off,
              color: _flashOn ? Colors.yellow : Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.75),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _isScanning ? null : _scanIngredientsText,
                child: Container(
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    color: _isScanning ? Colors.grey : _teal,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _teal.withOpacity(0.38),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isScanning ? Icons.hourglass_top : Icons.camera_alt,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isScanning ? 'Scanning...' : 'Scan Ingredients',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Use good light, hold steady, fill the frame with ingredients text',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: Colors.red, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'Camera Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.75)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _initializeControllerFuture = _initializeCamera();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartingCamera() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_teal),
          ),
          SizedBox(height: 16),
          Text(
            'Starting camera...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Scan Ingredients',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller),
                Container(color: Colors.black.withOpacity(0.08)),
                _buildTopInstruction(),
                _buildFlashButton(),
                _buildScannerFrame(),
                _buildBottomControls(),
              ],
            );
          }

          if (snapshot.hasError) {
            return _buildCameraError(snapshot.error);
          }

          return _buildStartingCamera();
        },
      ),
    );
  }
}
