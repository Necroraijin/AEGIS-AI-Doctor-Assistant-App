import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PreviousChatsPage extends StatefulWidget {
  const PreviousChatsPage({super.key});

  @override
  State<PreviousChatsPage> createState() => _PreviousChatsPageState();
}

class _PreviousChatsPageState extends State<PreviousChatsPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> _chatHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChatHistory();
  }

  Future<void> _fetchChatHistory() async {
    try {
      final user = supabase.auth.currentUser;

      
      final response = await supabase
          .from('clinical_records')
          .select('id, created_at, content, patient_id')
          .eq('doctor_id', user?.id ?? '')
          .order('created_at', ascending: false);

      setState(() {
        _chatHistory = response;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching history: $e");
      setState(() => _isLoading = false);
    }
  }

  
  String _formatDate(String isoString) {
    DateTime date = DateTime.parse(isoString).toLocal();
    return "${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  void _showFullChat(String content, String date) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          "Consultation - $date",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Close",
              style: TextStyle(color: Color(0xFF1B5AF0)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Consultation History",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5AF0)),
            )
          : _chatHistory.isEmpty
          ? const Center(
              child: Text(
                "No saved consultations found.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final record = _chatHistory[index];
                final String content = record['content'] ?? "No content";
                final String date = _formatDate(record['created_at']);

                
                String preview = content.length > 80
                    ? "${content.substring(0, 80)}..."
                    : content;

                
                bool isVoice = content.contains("CONSULTATION SUMMARY");

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: isVoice
                          ? Colors.purple.withOpacity(0.1)
                          : Colors.teal.withOpacity(0.1),
                      child: Icon(
                        isVoice ? Icons.mic : Icons.chat_bubble,
                        color: isVoice ? Colors.purple : Colors.teal,
                      ),
                    ),
                    title: Text(
                      date,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        preview,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onTap: () => _showFullChat(content, date),
                  ),
                );
              },
            ),
    );
  }
}
