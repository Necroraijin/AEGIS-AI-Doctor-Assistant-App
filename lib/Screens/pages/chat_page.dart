import 'dart:io';
import 'package:aegis/Services/suvi_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatPage extends StatefulWidget {
  final File imageFile; // The main X-Ray/Scan being discussed
  final String initialContext; // The first analysis text
  final String patientId; // To track history

  const ChatPage({
    super.key,
    required this.imageFile,
    required this.initialContext,
    this.patientId = "1", // Default for testing
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  // Chat History
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // 1. Add the initial analysis as the first message from AI
    _messages.add({
      'isUser': false,
      'text':
          "I've reviewed the image.\n\n${widget.initialContext}\n\nWhat specific questions do you have about these findings?",
      'image': null,
    });
  }

  // ---------------------------------------------------------------------------
  // 📤 SEND MESSAGE LOGIC
  // ---------------------------------------------------------------------------
  void _sendMessage(String text, {File? extraImage}) async {
    if (text.trim().isEmpty && extraImage == null) return;

    // 1. Update UI immediately (Optimistic)
    setState(() {
      _messages.add({
        'isUser': true,
        'text': text,
        'image': extraImage, // Show thumbnail if user uploaded new image
      });
      _isTyping = true;
    });

    _textController.clear();
    _scrollToBottom();

    try {
      // 2. Send to Suvi Service
      // We pass the ORIGINAL image context if no new image is provided
      File imageToSend = extraImage ?? widget.imageFile;

      String response = await SuviService.chatWithSuvi(
        text: text,
        patientId: widget.patientId,
        imageFile: imageToSend,
      );

      // 3. Update UI with Response
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({'isUser': false, 'text': response, 'image': null});
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'isUser': false,
          'text': "Connection Error. Please try again.",
          'image': null,
        });
      });
    }
  }

  // ---------------------------------------------------------------------------
  // 📸 PICK EXTRA IMAGE
  // ---------------------------------------------------------------------------
  Future<void> _pickExtraImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // Confirm before sending
      _showImageConfirmDialog(File(image.path));
    }
  }

  void _showImageConfirmDialog(File image) {
    TextEditingController captionCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Send Image?", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(image, height: 150),
            const SizedBox(height: 10),
            TextField(
              controller: captionCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Add a question... (optional)",
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text(
              "Send",
              style: TextStyle(
                color: Color(0xFF1B5AF0),
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _sendMessage(captionCtrl.text, extraImage: image);
            },
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // 🎨 UI BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1B5AF0);
    const Color bgDark = Color(0xFF121212);
    const Color cardDark = Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: bgDark,

      // --- AppBar ---
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        title: Row(
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  backgroundImage: NetworkImage(
                    "https://i.imgur.com/BoN9kdC.png",
                  ), // Suvi Avatar
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: bgDark, width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Med-Gemma AI",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Context Active",
                  style: TextStyle(fontSize: 12, color: primaryBlue),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Show the image being discussed
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => Dialog(child: Image.file(widget.imageFile)),
            ),
            child: Container(
              margin: const EdgeInsets.all(8),
              width: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(widget.imageFile),
                  fit: BoxFit.cover,
                ),
                border: Border.all(color: Colors.white24),
              ),
            ),
          ),
        ],
      ),

      // --- Body ---
      body: Column(
        children: [
          // Chat List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg, primaryBlue, cardDark);
              },
            ),
          ),

          // Typing Indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Med-Gemma is analyzing...",
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: cardDark,
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Attach Button
                  IconButton(
                    onPressed: _pickExtraImage,
                    icon: const Icon(
                      Icons.add_photo_alternate,
                      color: Colors.grey,
                    ),
                  ),

                  // Text Field
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Ask follow-up questions...",
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (val) => _sendMessage(val),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send Button
                  GestureDetector(
                    onTap: () => _sendMessage(_textController.text),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
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

  // --- Helper: Bubble UI ---
  Widget _buildMessageBubble(
    Map<String, dynamic> msg,
    Color primary,
    Color secondary,
  ) {
    bool isUser = msg['isUser'];
    File? attachedImage = msg['image'];

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Image Attachment (if any)
          if (attachedImage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 5),
              height: 150,
              width: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: FileImage(attachedImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // Text Bubble
          if (msg['text'] != null && msg['text'].toString().isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.80,
              ),
              decoration: BoxDecoration(
                color: isUser ? primary : secondary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(20),
                ),
              ),
              child: Text(
                msg['text'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
