import 'package:aegis/Screens/pages/patient_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _allPatients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Colors
  final Color primaryBlue = const Color(0xFF1B5AF0);
  final Color bgGrey = const Color(0xFFF5F7FA);
  final Color textDark = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  // ---------------------------------------------------------------------------
  // 🔗 FETCH PATIENTS FROM SUPABASE
  // ---------------------------------------------------------------------------
  Future<void> _fetchPatients() async {
    setState(() => _isLoading = true);
    try {
      // Fetch all patients ordered by most recently added
      final response = await supabase
          .from('patients')
          .select('*')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _allPatients = List<Map<String, dynamic>>.from(response);
          _filteredPatients = _allPatients; // Initially show all
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error fetching patients: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 🔍 SEARCH LOGIC
  // ---------------------------------------------------------------------------
  void _filterPatients(String query) {
    if (query.isEmpty) {
      setState(() => _filteredPatients = _allPatients);
    } else {
      setState(() {
        _filteredPatients = _allPatients.where((patient) {
          final name = (patient['full_name'] ?? "").toString().toLowerCase();
          final id = (patient['id'] ?? "").toString();
          return name.contains(query.toLowerCase()) || id.contains(query);
        }).toList();
      });
    }
  }

  // ---------------------------------------------------------------------------
  // 🎨 MAIN UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Patient Directory",
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.sort, color: textDark),
            onPressed: () {
              // Optional: Implement Sort Logic
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: _searchController,
              onChanged: _filterPatients,
              decoration: InputDecoration(
                hintText: "Search by name or ID...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),

          // 2. Patient List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPatients.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _fetchPatients,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _filteredPatients.length,
                      itemBuilder: (context, index) {
                        return _buildPatientCard(_filteredPatients[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),

      // 3. Add Patient Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Add Patient Screen (To be implemented)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Add Patient feature coming next!")),
          );
        },
        backgroundColor: primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 📇 PATIENT CARD WIDGET
  // ---------------------------------------------------------------------------
  Widget _buildPatientCard(Map<String, dynamic> patient) {
    String name = patient['full_name'] ?? "Unknown";
    String gender = patient['gender'] ?? "Unknown";
    int age = patient['age'] ?? 0;
    String id = patient['id'].toString();
    String lastVisit = patient['created_at'] != null
        ? DateFormat(
            'MMM d, yyyy',
          ).format(DateTime.parse(patient['created_at']))
        : "N/A";

    // Determine avatar color based on gender
    Color avatarColor = gender.toLowerCase() == 'male'
        ? Colors.blue[100]!
        : gender.toLowerCase() == 'female'
        ? Colors.pink[100]!
        : Colors.orange[100]!;
    Color iconColor = gender.toLowerCase() == 'male'
        ? Colors.blue
        : gender.toLowerCase() == 'female'
        ? Colors.pink
        : Colors.orange;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientDetailScreen(
              patientId: patient['id'], // Pass the ID
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 30,
              backgroundColor: avatarColor,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : "?",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(width: 20),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "ID: #$id • $gender • $age yrs",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Registered: $lastVisit",
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(Icons.chevron_right, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            "No patients found",
            style: TextStyle(fontSize: 18, color: Colors.grey[500]),
          ),
          const SizedBox(height: 10),
          Text(
            "Try adjusting your search or add a new patient.",
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
