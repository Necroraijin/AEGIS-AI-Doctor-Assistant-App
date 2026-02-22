import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../main.dart'; // To access 'cameras'
import 'chat_page.dart'; // To send the captured image for analysis
import 'suvi_screen.dart'; // To open Suvi if Face ID matches
import '../../services/suvi_service.dart'; // The Agentic backend

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  bool _isTakingPicture = false;

  // Colors
  final Color primaryBlue = const Color(0xFF1B5AF0);
  final Color darkBg = const Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _initCamera();

    // Scanning Animation
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(
      begin: 0.1,
      end: 0.9,
    ).animate(_scanController);
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) return;
    // Default to back camera
    _controller = CameraController(
      cameras[0],
      ResolutionPreset.max,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scanController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 📸 ROUTE 1: SCAN DOCUMENT (Sends to Chat/Analysis)
  // ---------------------------------------------------------------------------
  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isTakingPicture) {
      return;
    }

    setState(() => _isTakingPicture = true);

    try {
      final XFile image = await _controller!.takePicture();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              imageFile: File(image.path),
              initialContext:
                  "I have captured a medical document/scan. Please analyze it.",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error taking picture: $e");
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  // ---------------------------------------------------------------------------
  // 👁️ ROUTE 2: FACE ID (Sends to Aegis-Vision Agent)
  // ---------------------------------------------------------------------------
  Future<void> _scanPatientFace() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    // 1. Show Loading UI
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1B5AF0)),
      ),
    );

    try {
      // 2. Capture Image
      final XFile image = await _controller!.takePicture();

      // 3. Send to Vision Agent
      final result = await SuviService.identifyPatientFace(File(image.path));

      // 4. Close Loading Dialog
      if (mounted) Navigator.pop(context);

      // 5. Handle Result
      if (result['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ Match Found: ${result['name']}"),
              backgroundColor: Colors.green,
            ),
          );
          // Launch SUVI Pre-loaded with this Patient's ID!
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SuviScreen(patientId: result['patient_id']),
            ),
          );
        }
      } else {
        // 🚨 PATIENT NOT FOUND: Ask to create new record
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text(
                "Unknown Patient",
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                "This face does not match any existing patient records. Would you like to create a new patient profile?",
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5AF0),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Navigate to AddPatientScreen passing the captured image
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Routing to New Patient Form..."),
                      ),
                    );
                  },
                  child: const Text(
                    "Create Profile",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog on error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error capturing face. Check connection."),
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 🎨 UI BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Feed
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: double.infinity,
            child: CameraPreview(_controller!),
          ),

          // 2. Dark Overlay
          Container(color: Colors.black.withOpacity(0.3)),

          // 3. UI Layer
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCircleBtn(
                        Icons.close,
                        () => Navigator.pop(context),
                      ),
                      const Column(
                        children: [
                          Text(
                            "Aegis Scanner",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.lock,
                                color: Colors.greenAccent,
                                size: 10,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "HIPAA Secure",
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      _buildCircleBtn(Icons.flash_on, () {}),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // Scanner Frame
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 320,
                        height: 220,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24, width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildCorner(true, true),
                                _buildCorner(true, false),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildCorner(false, true),
                                _buildCorner(false, false),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Laser Animation
                      AnimatedBuilder(
                        animation: _scanAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: 220 * _scanAnimation.value,
                            child: Container(
                              width: 300,
                              height: 2,
                              decoration: BoxDecoration(
                                color: primaryBlue,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryBlue,
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  "Align document or face within the frame",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const Spacer(flex: 2),

                // Bottom Controls - UPDATED FOR DUAL AGENTS
                Container(
                  padding: const EdgeInsets.only(
                    top: 30,
                    bottom: 40,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    color: darkBg,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Action 1: Scan Document
                      _buildBottomAction(
                        icon: Icons.document_scanner,
                        label: "Scan Doc",
                        color: Colors.white,
                        onTap: _takePicture,
                      ),

                      // Action 2: Face ID (Agentic Vision)
                      _buildBottomAction(
                        icon: Icons.face_retouching_natural,
                        label: "Face ID",
                        color: primaryBlue,
                        isPrimary: true,
                        onTap: _scanPatientFace,
                      ),

                      // Action 3: Import
                      _buildBottomAction(
                        icon: Icons.image,
                        label: "Gallery",
                        color: Colors.white,
                        onTap: () {}, // Can wire up ImagePicker here later
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---
  Widget _buildCircleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildBottomAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isPrimary ? 20 : 16),
            decoration: BoxDecoration(
              color: isPrimary
                  ? color.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: isPrimary ? Border.all(color: color, width: 2) : null,
            ),
            child:
                _isTakingPicture &&
                    !isPrimary // Just a quick way to show loading on doc scan
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, color: color, size: isPrimary ? 32 : 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: isPrimary ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(bool isTop, bool isLeft) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? BorderSide(color: primaryBlue, width: 3)
              : BorderSide.none,
          bottom: !isTop
              ? BorderSide(color: primaryBlue, width: 3)
              : BorderSide.none,
          left: isLeft
              ? BorderSide(color: primaryBlue, width: 3)
              : BorderSide.none,
          right: !isLeft
              ? BorderSide(color: primaryBlue, width: 3)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: isTop && isLeft ? const Radius.circular(10) : Radius.zero,
          topRight: isTop && !isLeft ? const Radius.circular(10) : Radius.zero,
          bottomLeft: !isTop && isLeft
              ? const Radius.circular(10)
              : Radius.zero,
          bottomRight: !isTop && !isLeft
              ? const Radius.circular(10)
              : Radius.zero,
        ),
      ),
    );
  }
}
