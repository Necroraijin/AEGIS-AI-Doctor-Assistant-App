import 'dart:io';
import 'dart:math';
import 'package:aegis/Services/suvi_service.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SuviScreen extends StatefulWidget {
  // We can pass a patient ID if we came from a specific patient's page
  final int? patientId;

  const SuviScreen({super.key, this.patientId});

  @override
  State<SuviScreen> createState() => _SuviScreenState();
}

class _SuviScreenState extends State<SuviScreen>
    with SingleTickerProviderStateMixin {
  // --- Logic Variables ---
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient supabase = Supabase.instance.client;

  // State
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  String _liveText = "Tap the mic to start...";
  String _lastAiResponse = "";

  // Chat Transcript (For saving later)
  final List<Map<String, String>> _transcript = [];

  // Animation
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();

    // Wave Animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _initVoice();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 🗣️ VOICE SETUP & GREETING
  // ---------------------------------------------------------------------------
  Future<void> _initVoice() async {
    await _flutterTts.setLanguage("en-IN");
    await _flutterTts.setPitch(1.0);

    // Auto-Greet after a slight delay
    Future.delayed(const Duration(seconds: 1), () {
      _speak("Hello Doctor. I am Suvi. I am ready to assist you.");
    });
  }

  Future<void> _speak(String text) async {
    setState(() => _isSpeaking = true);
    await _flutterTts.speak(text);
    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
  }

  // ---------------------------------------------------------------------------
  // 🎤 MICROPHONE LOGIC
  // ---------------------------------------------------------------------------
  void _toggleListening() async {
    if (_isListening) {
      // Stop Listening
      setState(() => _isListening = false);
      _speech.stop();
    } else {
      // Start Listening
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _liveText = val.recognizedWords;
            });

            // If user stops talking for a bit (final result)
            if (val.finalResult) {
              setState(() => _isListening = false);
              _processRequest(_liveText);
            }
          },
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 🧠 AI PROCESSING (Text + Image)
  // ---------------------------------------------------------------------------
  Future<void> _processRequest(String text, {File? image}) async {
    if (text.isEmpty && image == null) return;

    setState(() {
      _isProcessing = true;
      _transcript.add({"role": "doctor", "content": text});
    });

    try {
      // 1. Call your Kaggle/Ngrok Backend
      // Default to Patient ID 1 if none passed (or handle dynamic ID)
      String patientIdStr = (widget.patientId ?? 1).toString();

      String response = await SuviService.chatWithSuvi(
        text: text,
        patientId: patientIdStr,
        imageFile: image,
      );

      // 2. Update UI & Speak
      setState(() {
        _lastAiResponse = response;
        _liveText = response; // Show AI text in the main view
        _isProcessing = false;
        _transcript.add({"role": "ai", "content": response});
      });

      _speak(response);
    } catch (e) {
      setState(() {
        _liveText = "Connection Error. Please check backend.";
        _isProcessing = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // 📸 IMAGE UPLOAD
  // ---------------------------------------------------------------------------
  Future<void> _uploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File file = File(image.path);

      // Notify user
      setState(() => _liveText = "Analyzing uploaded scan...");
      _speak("I am analyzing the uploaded image.");

      // Send to AI immediately with a prompt
      _processRequest(
        "Analyze this medical image and give me clinical findings.",
        image: file,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 💾 CONCLUDE & SAVE SESSION
  // ---------------------------------------------------------------------------
  Future<void> _concludeSession() async {
    if (_transcript.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isProcessing = true);
    String fullConversation = _transcript
        .map((m) => "${m['role']?.toUpperCase()}: ${m['content']}")
        .join("\n");

    try {
      // 🚨 Get the currently logged-in Doctor
      final user = supabase.auth.currentUser;

      // Save to Supabase
      await supabase.from('clinical_records').insert({
        'patient_id': widget.patientId ?? 1,
        'doctor_id': user?.id, //  THIS LINKS THE DOCTOR TO THE RECORD
        'content': "CONSULTATION SUMMARY:\n$fullConversation",
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session Saved to Database.")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error saving: $e")));
        Navigator.pop(context);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 🎨 UI BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient Background
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [Color(0xFF0F172A), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white70,
                        size: 30,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    if (_isListening)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.fiber_manual_record,
                              color: Colors.red,
                              size: 10,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Listening...",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.save_alt, color: Colors.white70),
                      onPressed: _concludeSession,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 2. Main Content (Live Text / AI Response)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    Text(
                      _isSpeaking
                          ? "Suvi is speaking..."
                          : (_isProcessing ? "Processing..." : "Suvi AI Nurse"),
                      style: TextStyle(
                        color: Colors.blue[200],
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // The Big Text Area
                    SizedBox(
                      height: 200,
                      child: SingleChildScrollView(
                        child: Text(
                          _liveText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _liveText.length > 50
                                ? 18
                                : 26, // Dynamic font size
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 3. Audio Visualizer (Waveform)
              SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(10, (index) => _buildWaveBar(index)),
                ),
              ),

              const Spacer(),

              // 4. Action Buttons (Upload & Type)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(Icons.image, "Upload Scan", _uploadImage),
                  const SizedBox(width: 20),
                  _buildActionButton(Icons.keyboard, "Type", () {
                    // Optional: Show text input dialog
                  }),
                ],
              ),

              const SizedBox(height: 30),

              // 5. Main Mic Button
              GestureDetector(
                onTap: _toggleListening,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening
                        ? Colors.redAccent
                        : const Color(0xFF1B5AF0),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_isListening
                                    ? Colors.redAccent
                                    : const Color(0xFF1B5AF0))
                                .withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                "Tap to Speak",
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildWaveBar(int index) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        double height = (_isListening || _isSpeaking)
            ? 15 + Random().nextInt(40).toDouble()
            : 6.0;

        return Container(
          width: 5,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
