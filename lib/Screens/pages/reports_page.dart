import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/report_generator.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key, String? analysisText});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;

  String _doctorName = "Unknown";
  String _specialty = "General";

  @override
  void initState() {
    super.initState();
    _fetchReports();
    _fetchDoctorProfile();
  }

  Future<void> _fetchDoctorProfile() async {
    final user = supabase.auth.currentUser;
    if (user?.userMetadata != null) {
      setState(() {
        _doctorName =
            "${user!.userMetadata?['first_name']} ${user.userMetadata?['last_name']}";
        _specialty = user.userMetadata?['specialty'] ?? "General Medicine";
      });
    }
  }

  Future<void> _fetchReports() async {
    try {
      final response = await supabase
          .from('clinical_records')
          .select('*, patients(full_name)')
          .order('created_at', ascending: false);

      setState(() {
        _reports = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _downloadReport(Map<String, dynamic> report) {
    String patientName = report['patients']?['full_name'] ?? "Unknown Patient";
    String content =
        report['content_markdown'] ?? report['content'] ?? "No content.";
    String date = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.parse(report['created_at']));

    ReportGenerator.generateAndOpenReport(
      doctorName: _doctorName,
      specialty: _specialty,
      patientName: patientName,
      reportContent: content,
      date: date,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Medical Reports",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _reports.length,
              itemBuilder: (context, index) {
                final report = _reports[index];
                return _buildReportCard(report);
              },
            ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    String patientName = report['patients']?['full_name'] ?? "Unknown";
    String date = DateFormat(
      'MMM d, yyyy • h:mm a',
    ).format(DateTime.parse(report['created_at']));
    String snippet = (report['content'] ?? "").toString().replaceAll("\n", " ");
    if (snippet.length > 60) snippet = "${snippet.substring(0, 60)}...";

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                patientName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Finalized",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          const SizedBox(height: 15),
          Text(snippet, style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _downloadReport(report),
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text("Download Word Report"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1B5AF0),
                side: const BorderSide(color: Color(0xFF1B5AF0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text("Download Word Report"),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Generating Report...")),
              );

              try {
                final user = Supabase.instance.client.auth.currentUser;
                String doctorName =
                    user?.userMetadata?['full_name'] ?? "Aegis Doctor";

                await ReportGenerator.generateAndOpenReport(
                  doctorName: doctorName,
                  specialty: "General Practice",
                  patientName: "Rajesh Kumar",
                  reportContent:
                      "Patient reported a persistent cough. Prescribed rest and hydration.",
                  date: DateTime.now().toString().split(" ")[0],
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            "No reports generated yet.",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
