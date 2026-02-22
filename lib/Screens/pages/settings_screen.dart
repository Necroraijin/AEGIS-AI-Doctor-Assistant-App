
import 'package:aegis/Screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart'; // Ensure this exists

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  // State Variables
  bool _faceIdEnabled = true;
  bool _darkModeEnabled = false;
  double _sensitivity = 0.7;
  String _doctorName = "Doctor";
  String _doctorEmail = "loading...";

  final TextEditingController _urlController = TextEditingController();

  // Colors
  final Color primaryBlue = const Color(0xFF1B5AF0);
  final Color bgGrey = const Color(0xFFF2F4F7);
  final Color textDark = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadSavedSettings();
  }

  // ---------------------------------------------------------------------------
  // 1. LOAD DATA (User Profile + Saved URL)
  // ---------------------------------------------------------------------------
  Future<void> _loadUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _doctorEmail = user.email ?? "";
        String first = user.userMetadata?['first_name'] ?? "";
        String last = user.userMetadata?['last_name'] ?? "";
        _doctorName = "$first $last".trim();
        if (_doctorName.isEmpty) _doctorName = "Medical Officer";
      });
    }
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Load the saved Ngrok URL, or fallback to the one in Constants
      String savedUrl = prefs.getString('ngrok_url') ?? AppConstants.ngrokUrl;
      _urlController.text = savedUrl;

      _faceIdEnabled = prefs.getBool('face_id') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode') ?? false;
    });
  }

  // ---------------------------------------------------------------------------
  // 2. SAVE LOGIC (URL + Toggles)
  // ---------------------------------------------------------------------------
  Future<void> _saveUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ngrok_url', _urlController.text.trim());

    // Ideally, update the singleton/constant in real-time too
    // Constants.baseUrl = _urlController.text.trim();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "✅ Backend URL Updated! Restarting app recommended.",
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // ---------------------------------------------------------------------------
  // 3. LOGOUT LOGIC
  // ---------------------------------------------------------------------------
  Future<void> _handleLogout() async {
    // Show confirmation dialog
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Sign Out"),
            content: const Text("Are you sure you want to log out?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 🎨 UI BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: bgGrey,
        elevation: 0,
        // Since this is likely inside a TabView, we don't always need a back button
        // But if navigated to directly:
        automaticallyImplyLeading: false,
        title: Text(
          "Settings",
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // 1. Account Section
            _buildSectionHeader("ACCOUNT"),
            _buildTileGroup([
              _buildTile(
                icon: Icons.person,
                color: Colors.blue,
                title: _doctorName,
                subtitle: _doctorEmail,
                onTap: () {},
              ),
              _buildSwitchTile(
                icon: Icons.face,
                color: Colors.green,
                title: "Face ID Login",
                value: _faceIdEnabled,
                onChanged: (v) {
                  setState(() => _faceIdEnabled = v);
                  _toggleSetting('face_id', v);
                },
              ),
            ]),
            const SizedBox(height: 30),

            // 2. AI Configuration (Hackathon Special)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader("AI CONFIGURATION"),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "MED-GEMMA ACTIVE",
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTile(
                    icon: Icons.smart_toy,
                    color: Colors.deepPurple,
                    title: "AI Model Version",
                    subtitle: "Med-Gemma 27B (v2.4)",
                    isGrouped: true,
                  ),
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Analysis Sensitivity",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "${(_sensitivity * 100).toInt()}%",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                  Slider(
                    value: _sensitivity,
                    activeColor: primaryBlue,
                    onChanged: (v) => setState(() => _sensitivity = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 3. Developer / Server Config
            _buildSectionHeader("SERVER CONNECTION (DEV)"),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ngrok URL",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _urlController,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.blueGrey,
                    ),
                    decoration: InputDecoration(
                      hintText: "https://....ngrok-free.app",
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save, color: Colors.green),
                        onPressed: _saveUrl,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 4. App Preferences
            _buildSectionHeader("APP PREFERENCES"),
            _buildTileGroup([
              _buildTile(
                icon: Icons.notifications,
                color: Colors.redAccent,
                title: "Notifications",
                trailingBadge: true,
              ),
              _buildSwitchTile(
                icon: Icons.dark_mode,
                color: Colors.black87,
                title: "Dark Mode",
                value: _darkModeEnabled,
                onChanged: (v) {
                  setState(() => _darkModeEnabled = v);
                  _toggleSetting('dark_mode', v);
                },
              ),
            ]),
            const SizedBox(height: 30),

            // 5. Logout Button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                title: const Center(
                  child: Text(
                    "Sign Out",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: _handleLogout,
              ),
            ),

            const SizedBox(height: 50),
            Center(
              child: Text(
                "Aegis Medical v1.0.4 (Hackathon Build)",
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTileGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: children),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    bool trailingBadge = false,
    bool isGrouped = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            )
          : null,
      trailing: trailingBadge
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            )
          : Icon(Icons.chevron_right, color: Colors.grey[300], size: 20),
      onTap: onTap,
      contentPadding: isGrouped
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color color,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      value: value,
      activeColor: color,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
