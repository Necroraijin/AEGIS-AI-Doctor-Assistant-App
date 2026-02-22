// import 'package:aegis/Screens/pages/patients_page.dart';
// import 'package:aegis/Screens/pages/reports_page.dart';

// import 'package:aegis/Screens/pages/settings_screen.dart';
// import 'package:aegis/Screens/pages/suvi_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:intl/intl.dart'; // Add intl to pubspec.yaml if missing

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   int _selectedIndex = 0;
//   final SupabaseClient supabase = Supabase.instance.client;

//   // Data State
//   String _doctorName = "Doctor";
//   List<Map<String, dynamic>> _recentReports = [];
//   List<Map<String, dynamic>> _recentPatients = [];
//   bool _isLoading = true;
//   bool _hasNotifications = false;

//   // Colors
//   final Color primaryBlue = const Color(0xFF1B5AF0);
//   final Color bgGrey = const Color(0xFFF5F7FA);
//   final Color textDark = const Color(0xFF1A1A1A);

//   @override
//   void initState() {
//     super.initState();
//     _fetchDashboardData();
//   }

//   // ---------------------------------------------------------------------------
//   // 🔗 REAL DATA FETCHING
//   // ---------------------------------------------------------------------------
//   Future<void> _fetchDashboardData() async {
//     try {
//       final user = supabase.auth.currentUser;

//       // 1. Fetch Doctor Name
//       if (user != null && user.userMetadata != null) {
//         String first = user.userMetadata?['first_name'] ?? "";
//         String last = user.userMetadata?['last_name'] ?? "";
//         _doctorName = "$first $last".trim();
//         if (_doctorName.isEmpty) _doctorName = "Doctor";
//       }

//       // 2. Fetch Recent Reports (Clinical Records)
//       // We join with 'patients' table to get the name
//       final reportsResponse = await supabase
//           .from('clinical_records')
//           .select('*, patients(full_name)')
//           .order('created_at', ascending: false)
//           .limit(5);

//       // 3. Fetch Recent Patients
//       final patientsResponse = await supabase
//           .from('patients')
//           .select('*')
//           .order('created_at', ascending: false)
//           .limit(5);

//       setState(() {
//         _recentReports = List<Map<String, dynamic>>.from(reportsResponse);
//         _recentPatients = List<Map<String, dynamic>>.from(patientsResponse);

//         // Simple Logic: If there are recent reports, show notification dot
//         _hasNotifications = _recentReports.isNotEmpty;
//         _isLoading = false;
//       });
//     } catch (e) {
//       print("Error fetching data: $e");
//       setState(() => _isLoading = false);
//     }
//   }

//   // ---------------------------------------------------------------------------
//   // 🧭 NAVIGATION LOGIC
//   // ---------------------------------------------------------------------------
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   // ---------------------------------------------------------------------------
//   // 🔔 NOTIFICATION POPUP
//   // ---------------------------------------------------------------------------
//   void _showNotifications() {
//     if (!_hasNotifications) return; // Don't show if empty

//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         height: 400,
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//         ),
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "Recent Updates",
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const Divider(),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: _recentReports.length,
//                 itemBuilder: (context, index) {
//                   final report = _recentReports[index];
//                   return ListTile(
//                     leading: const Icon(Icons.description, color: Colors.blue),
//                     title: Text(
//                       "New Report: ${report['patients']['full_name']}",
//                     ),
//                     subtitle: Text(
//                       DateFormat(
//                         'MMM d, h:mm a',
//                       ).format(DateTime.parse(report['created_at'])),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // 🎨 MAIN BUILD
//   // ---------------------------------------------------------------------------
//   @override
//   Widget build(BuildContext context) {
//     // The Pages for the Bottom Nav
//     final List<Widget> pages = [
//       _buildDashboardContent(), // 0: Home
//       const PatientsPage(), // 1: Patients
//       const ReportsPage(), // 2: Reports (Placeholder)
//       const SettingsScreen(), // 3: Settings
//     ];

//     return Scaffold(
//       backgroundColor: bgGrey,

//       // 1. THE BODY (Switches based on selection)
//       body: SafeArea(
//         child: IndexedStack(index: _selectedIndex, children: pages),
//       ),

//       // 2. THE FLOATING MIC BUTTON (SUVI AGENT)
//       floatingActionButton: SizedBox(
//         height: 70,
//         width: 70,
//         child: FloatingActionButton(
//           onPressed: () {
//             // Activate SUVI
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => const SuviScreen(),
//               ), // Replace with NurseScreen() when ready
//             );
//           },
//           backgroundColor: primaryBlue,
//           elevation: 10,
//           shape: const CircleBorder(),
//           child: Container(
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               boxShadow: [
//                 BoxShadow(
//                   color: primaryBlue.withOpacity(0.4),
//                   blurRadius: 15,
//                   spreadRadius: 5,
//                 ),
//               ],
//             ),
//             child: const Icon(Icons.mic, size: 32, color: Colors.white),
//           ),
//         ),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

//       // 3. THE BOTTOM NAVIGATION BAR
//       bottomNavigationBar: BottomAppBar(
//         shape: const CircularNotchedRectangle(),
//         notchMargin: 10,
//         color: Colors.white,
//         child: SizedBox(
//           height: 60,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               _buildNavItem(Icons.grid_view_rounded, "Home", 0),
//               _buildNavItem(Icons.people_alt_outlined, "Patients", 1),
//               const SizedBox(width: 40), // Space for the MIC button
//               _buildNavItem(Icons.description_outlined, "Reports", 2),
//               _buildNavItem(Icons.settings_outlined, "Settings", 3),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // 🏠 DASHBOARD CONTENT (Tab 0)
//   // ---------------------------------------------------------------------------
//   Widget _buildDashboardContent() {
//     var hour = DateTime.now().hour;
//     String greeting = hour < 12
//         ? "Good morning"
//         : hour < 17
//         ? "Good afternoon"
//         : "Good evening";

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   CircleAvatar(
//                     radius: 24,
//                     backgroundColor: Colors.blue[100],
//                     child: Text(
//                       _doctorName.isNotEmpty ? _doctorName[0] : "D",
//                       style: TextStyle(
//                         color: primaryBlue,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 20,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         "ONLINE",
//                         style: TextStyle(
//                           color: Colors.green,
//                           fontSize: 10,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       _isLoading
//                           ? Container(
//                               width: 100,
//                               height: 20,
//                               color: Colors.grey[300],
//                             )
//                           : Text(
//                               "Dr. $_doctorName",
//                               style: TextStyle(
//                                 color: textDark,
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                     ],
//                   ),
//                 ],
//               ),
//               // Notification Bell (Hidden if no notifications)
//               if (_hasNotifications)
//                 GestureDetector(
//                   onTap: _showNotifications,
//                   child: Stack(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(10),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: const Icon(
//                           Icons.notifications_outlined,
//                           size: 24,
//                         ),
//                       ),
//                       Positioned(
//                         right: 10,
//                         top: 10,
//                         child: Container(
//                           width: 8,
//                           height: 8,
//                           decoration: const BoxDecoration(
//                             color: Colors.red,
//                             shape: BoxShape.circle,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 )
//               else
//                 Container(
//                   padding: const EdgeInsets.all(10),
//                   child: Icon(
//                     Icons.notifications_none,
//                     color: Colors.grey[400],
//                   ),
//                 ),
//             ],
//           ),

//           const SizedBox(height: 30),
//           Text(
//             greeting,
//             style: TextStyle(
//               fontSize: 28,
//               fontWeight: FontWeight.bold,
//               color: textDark,
//             ),
//           ),
//           Text(
//             "You have ${_recentReports.length} recent reports.",
//             style: TextStyle(color: Colors.grey[600], fontSize: 14),
//           ),
//           const SizedBox(height: 25),

//           // RECENT REPORTS SECTION
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 "Recent Reports",
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: textDark,
//                 ),
//               ),
//               GestureDetector(
//                 onTap: () =>
//                     setState(() => _selectedIndex = 2), // Go to Reports Tab
//                 child: Text(
//                   "See all",
//                   style: TextStyle(
//                     color: primaryBlue,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 15),

//           // Horizontal List of Reports
//           if (_isLoading)
//             const Center(child: CircularProgressIndicator())
//           else if (_recentReports.isEmpty)
//             _buildEmptyState("No reports found yet.")
//           else
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: _recentReports.map((report) {
//                   return _buildReportCard(report);
//                 }).toList(),
//               ),
//             ),

//           const SizedBox(height: 30),

//           // RECENT PATIENTS SECTION
//           Text(
//             "Recent Patients",
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: textDark,
//             ),
//           ),
//           const SizedBox(height: 15),

//           if (_isLoading)
//             const SizedBox()
//           else if (_recentPatients.isEmpty)
//             _buildEmptyState("No patients found.")
//           else
//             Column(
//               children: _recentPatients
//                   .map((patient) => _buildPatientTile(patient))
//                   .toList(),
//             ),

//           const SizedBox(height: 80), // Space for FAB
//         ],
//       ),
//     );
//   }

//   // --- WIDGET HELPER FUNCTIONS ---

//   Widget _buildReportCard(Map<String, dynamic> report) {
//     String patientName = report['patients']?['full_name'] ?? "Unknown";
//     String date = DateFormat(
//       'MMM d',
//     ).format(DateTime.parse(report['created_at']));
//     // Check if report has content to simulate status
//     String status = (report['content_markdown'] as String).length > 50
//         ? "Analysis Complete"
//         : "Processing...";
//     Color color = status == "Analysis Complete" ? Colors.green : Colors.orange;

//     return GestureDetector(
//       onTap: () {
//         // Here you would navigate to Report Detail Screen passing 'report' data
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Opening Report Detail...")),
//         );
//       },
//       child: Container(
//         width: 260,
//         margin: const EdgeInsets.only(right: 15),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.03),
//               blurRadius: 10,
//               offset: const Offset(0, 5),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     color: Colors.blue[50],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: const Icon(Icons.description, color: Colors.blue),
//                 ),
//                 const SizedBox(width: 12),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       patientName,
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     Text(
//                       "Report • $date",
//                       style: TextStyle(fontSize: 12, color: Colors.grey[500]),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 15),
//             Row(
//               children: [
//                 Container(
//                   width: 8,
//                   height: 8,
//                   decoration: BoxDecoration(
//                     color: color,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//                 const SizedBox(width: 6),
//                 Text(
//                   status,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: color,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPatientTile(Map<String, dynamic> patient) {
//     String name = patient['full_name'] ?? "Unknown";
//     String initials = name.isNotEmpty ? name[0] : "?";

//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey[100]!),
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             backgroundColor: Colors.purple[50],
//             child: Text(
//               initials,
//               style: const TextStyle(
//                 color: Colors.purple,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           const SizedBox(width: 15),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 name,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 15,
//                 ),
//               ),
//               Text(
//                 "ID: #${patient['id']}",
//                 style: TextStyle(color: Colors.grey[500], fontSize: 12),
//               ),
//             ],
//           ),
//           const Spacer(),
//           const Icon(Icons.chevron_right, color: Colors.grey),
//         ],
//       ),
//     );
//   }

//   Widget _buildNavItem(IconData icon, String label, int index) {
//     bool isSelected = _selectedIndex == index;
//     return GestureDetector(
//       onTap: () => _onItemTapped(index),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             icon,
//             color: isSelected ? primaryBlue : Colors.grey[400],
//             size: 26,
//           ),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 10,
//               color: isSelected ? primaryBlue : Colors.grey[400],
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyState(String msg) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey[200]!),
//       ),
//       child: Center(
//         child: Text(msg, style: TextStyle(color: Colors.grey[500])),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'suvi_screen.dart';
import 'patients_page.dart';
import 'reports_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primaryBlue = const Color(0xFF1B5AF0);
  final Color bgGrey = const Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: bgGrey,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Good Morning,",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            Text(
              "Dr. Aegis",
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=11"),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. SYSTEM STATUS CAROUSEL
            SizedBox(
              height: 140,
              child: PageView(
                children: [
                  _buildStatusCard(
                    "Med-Gemma 27B",
                    "Agentic Systems Online",
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildStatusCard(
                    "Pending Reports",
                    "3 Reports await signature",
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              "Quick Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // 2. QUICK ACTION GRID
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.1,
              children: [
                _buildActionCard(
                  "Voice Consult",
                  "Talk to Suvi",
                  Icons.mic,
                  primaryBlue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SuviScreen()),
                    );
                  },
                ),
                _buildActionCard(
                  "Face ID",
                  "Identify Patient",
                  Icons.face_retouching_natural,
                  Colors.purple,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CameraScreen()),
                    );
                  },
                ),
                _buildActionCard(
                  "Patient Directory",
                  "View Vector DB",
                  Icons.folder_shared,
                  Colors.orange,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PatientsPage()),
                    );
                  },
                ),
                _buildActionCard(
                  "Clinical Reports",
                  "Auto-Generated Docs",
                  Icons.article,
                  Colors.teal,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportsPage()),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),
            const Text(
              "Recent Activity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // 3. ACTIVITY TIMELINE
            _buildActivityTile(
              "Consultation Saved",
              "John Doe • 10 mins ago",
              Icons.save,
            ),
            _buildActivityTile(
              "Vitals Updated",
              "Jane Smith • 1 hr ago",
              Icons.favorite,
            ),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---
  Widget _buildStatusCard(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTile(String title, String subtitle, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(icon, color: primaryBlue, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
    );
  }
}
