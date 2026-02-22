import 'dart:io';
import 'dart:math';
import 'package:aegis/Services/suvi_service.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SuviScreen extends StatefulWidget {
  final int? patientId;

  const SuviScreen({super.key, this.patientId});

  @override
  State<SuviScreen> createState() => _SuviScreenState();
}

class _SuviScreenState extends State<SuviScreen>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient supabase = Supabase.instance.client;

  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  String _liveText = "Tap the mic to start...";
  String _lastAiResponse = "";

  final List<Map<String, String>> _transcript = [];

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();

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

  Future<void> _initVoice() async {
    await _flutterTts.setLanguage("en-IN");
    await _flutterTts.setPitch(1.0);

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

            if (val.finalResult) {
              setState(() => _isListening = false);
              _processRequest(_liveText);
            }
          },
        );
      }
    }
  }

  Future<void> _processRequest(String text, {File? image}) async {
    if (text.isEmpty && image == null) return;

    setState(() {
      _isProcessing = true;
      _transcript.add({"role": "doctor", "content": text});
    });

    try {
      String patientIdStr = (widget.patientId ?? 1).toString();

      String response = await SuviService.chatWithSuvi(
        text: text,
        patientId: patientIdStr,
        imageFile: image,
      );

      setState(() {
        _lastAiResponse = response;
        _liveText = response;
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

  Future<void> _uploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File file = File(image.path);

      setState(() => _liveText = "Analyzing uploaded scan...");
      _speak("I am analyzing the uploaded image.");

      _processRequest(
        "Analyze this medical image and give me clinical findings.",
        image: file,
      );
    }
  }

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
      final user = supabase.auth.currentUser;

      await supabase.from('clinical_records').insert({
        'patient_id': widget.patientId ?? 1,
        'doctor_id': user?.id,
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

              SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(10, (index) => _buildWaveBar(index)),
                ),
              ),

              const Spacer(),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(Icons.image, "Upload Scan", _uploadImage),
                  const SizedBox(width: 20),
                  _buildActionButton(Icons.keyboard, "Type", () {
                    TextEditingController textController =
                        TextEditingController();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1E1E1E),
                        title: const Text(
                          "Type to Suvi",
                          style: TextStyle(color: Colors.white),
                        ),
                        content: TextField(
                          controller: textController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Enter your message...",
                            hintStyle: TextStyle(color: Colors.white54),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF1B5AF0)),
                            ),
                          ),
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
                              if (textController.text.isNotEmpty) {
                                _processRequest(textController.text);
                              }
                            },
                            child: const Text(
                              "Send",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),

              const SizedBox(height: 30),

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
