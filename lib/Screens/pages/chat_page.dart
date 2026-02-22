import 'dart:io';
import 'package:aegis/Services/suvi_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPage extends StatefulWidget {
  final File? imageFile;
  final String? initialContext;
  final String patientId;

  const ChatPage({
    super.key,
    this.imageFile,
    this.initialContext,
    this.patientId = "1",
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient supabase = Supabase.instance.client;

  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    if (widget.imageFile != null && widget.initialContext != null) {
      _messages.add({
        'isUser': false,
        'text':
            "I've reviewed the image.\n\n${widget.initialContext}\n\nWhat specific questions do you have about these findings?",
        'image': null,
      });
    } else {
      _messages.add({
        'isUser': false,
        'text': "Hello Doctor. I am Suvi. How can I assist you today?",
        'image': null,
      });
    }
  }

  Future<void> _concludeSession() async {
    if (_messages.length <= 1) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isTyping = true);

    String fullConversation = _messages
        .map((m) {
          String role = m['isUser'] ? "DOCTOR" : "SUVI";
          return "$role: ${m['text']}";
        })
        .join("\n\n");

    try {
      final user = supabase.auth.currentUser;

      await supabase.from('clinical_records').insert({
        'patient_id': int.tryParse(widget.patientId) ?? 1,
        'doctor_id': user?.id,
        'content': "TEXT CONSULTATION:\n\n$fullConversation",
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Chat Saved to Patient Record.")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  void _sendMessage(String text, {File? extraImage}) async {
    if (text.trim().isEmpty && extraImage == null) return;

    setState(() {
      _messages.add({'isUser': true, 'text': text, 'image': extraImage});
      _isTyping = true;
    });

    _textController.clear();
    _scrollToBottom();

    try {
      File? imageToSend = extraImage ?? widget.imageFile;
      String response = await SuviService.chatWithSuvi(
        text: text,
        patientId: widget.patientId,
        imageFile: imageToSend,
      );

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

  Future<void> _pickExtraImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) _showImageConfirmDialog(File(image.path));
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
            TextField(
              controller: captionCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Add a question...",
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

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1B5AF0);
    const Color bgDark = Color(0xFF121212);
    const Color cardDark = Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: primaryBlue.withOpacity(0.2),
              child: const Icon(Icons.auto_awesome, color: Colors.blueAccent),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Suvi",
                  style: TextStyle(
                    fontSize: 18,
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
          IconButton(
            icon: const Icon(Icons.save_alt, color: Colors.white),
            tooltip: "Save Session",
            onPressed: _concludeSession,
          ),
          if (widget.imageFile != null)
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => Dialog(child: Image.file(widget.imageFile!)),
              ),
              child: Container(
                margin: const EdgeInsets.all(8),
                width: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(widget.imageFile!),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: Colors.white24),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _buildMessageBubble(_messages[index], primaryBlue, cardDark),
            ),
          ),
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
                      "Suvi is typing...",
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
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
                  IconButton(
                    onPressed: _pickExtraImage,
                    icon: const Icon(
                      Icons.add_photo_alternate,
                      color: Colors.grey,
                    ),
                  ),
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
                          hintText: "Message Suvi...",
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (val) => _sendMessage(val),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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

  Widget _buildMessageBubble(
    Map<String, dynamic> msg,
    Color primary,
    Color secondary,
  ) {
    bool isUser = msg['isUser'];
    File? attachedImage = msg['image'];
    Widget content = Column(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
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
        if (msg['text'] != null && msg['text'].toString().isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
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
    );

    if (isUser)
      return Align(alignment: Alignment.centerRight, child: content);
    else
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: primary.withOpacity(0.2),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.blueAccent,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Align(alignment: Alignment.centerLeft, child: content),
            ),
          ],
        ),
      );
  }
}
