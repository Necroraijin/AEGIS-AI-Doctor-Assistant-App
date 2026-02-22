import 'dart:io';
import 'package:aegis/Screens/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // --- 1. State & Controllers ---
  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  // Text Controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _selectedSpecialty = "General Practice"; // Default value
  File? _medicalIdImage;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // --- 2. Colors & Styles ---
  final Color primaryBlue = const Color(0xFF1B5AF0);
  final Color bgGrey = const Color(0xFFF2F4F7);
  final Color textDark = const Color(0xFF1A1A1A);

  // Fix for text visibility
  final TextStyle inputTextStyle = const TextStyle(
    color: Colors.black87,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // --- 3. Logic: Image Picker ---
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _medicalIdImage = File(image.path));
    }
  }

  // --- 4. Logic: Supabase Registration (UPDATED FOR VERIFICATION) ---
  Future<void> _handleRegistration() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();

    // A. Basic Validation
    if (email.isEmpty || password.isEmpty || firstName.isEmpty) {
      _showError("Please fill in all required fields.");
      return;
    }

    // Uncomment this if you want to enforce ID upload
    // if (_medicalIdImage == null) {
    //   _showError("Please upload your Medical ID for verification.");
    //   return;
    // }

    setState(() => _isLoading = true);

    try {
      // B. Create User in Supabase Auth
      // emailRedirectTo: Helps with deep linking later if needed
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'io.supabase.flutterquickstart://login-callback',
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'specialty': _selectedSpecialty,
          'phone': _phoneCtrl.text.trim(),
          'role': 'doctor',
        },
      );

      // C. Check Verification Status
      // If "Confirm Email" is ON in Supabase, session will be null here.
      if (res.session == null && res.user != null) {
        // CASE 1: Verification Required
        if (mounted) {
          _showVerificationDialog(email);
        }
      } else if (res.session != null) {
        // CASE 2: No Verification Required (Logged in immediately)
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError("Registration failed. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 5. Helper: Verification Dialog (NEW) ---
  void _showVerificationDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must press button to exit
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.mark_email_read, size: 50, color: primaryBlue),
            const SizedBox(height: 10),
            const Text(
              "Verify your Email",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          "We have sent a verification link to:\n\n$email\n\nPlease check your inbox and click the link to activate your account.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Close dialog AND go back to Login Screen
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to Login (pop RegisterScreen)
            },
            child: Text(
              "OK, I'll Check",
              style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  // --- 6. UI Build ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Doctor Registration",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              "Help",
              style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            // The Main Card
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 450),
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProgressDot("Personal", true),
                    _buildLine(),
                    _buildProgressDot("License", true),
                    _buildLine(),
                    _buildProgressDot("Security", true),
                  ],
                ),
                const SizedBox(height: 30),

                // 2. Heading
                Text(
                  "Let’s start with your\ndetails.",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 20),

                // 3. AI Trust Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF2FF), // Light Blue
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryBlue.withOpacity(0.1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.verified_user, color: primaryBlue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "We use Med-Gemma AI to securely verify your license against the national database.",
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // 4. Form Fields
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: "First Name",
                        hint: "Dr. Jane",
                        controller: _firstNameCtrl,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildTextField(
                        label: "Last Name",
                        hint: "Doe",
                        controller: _lastNameCtrl,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // Email
                _buildTextField(
                  label: "Work Email",
                  hint: "jane.doe@hospital.com",
                  icon: Icons.email_outlined,
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),

                // Password
                Text(
                  "Password",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: !_isPasswordVisible,
                  style: inputTextStyle,
                  decoration: _inputDecoration(
                    hint: "Create a strong password",
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Phone
                _buildTextField(
                  label: "Mobile Number",
                  hint: "+1 (555) 000-0000",
                  icon: Icons.phone_outlined,
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 15),

                // Specialty Dropdown
                const Text(
                  "Primary Specialty",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedSpecialty,
                  decoration: _inputDecoration(
                    hint: "Select your specialty",
                    icon: Icons.medical_services_outlined,
                  ),
                  style: inputTextStyle,
                  items:
                      [
                            "Cardiology",
                            "General Practice",
                            "Pediatrics",
                            "Neurology",
                            "Orthopedics",
                          ]
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => _selectedSpecialty = val!),
                ),
                const SizedBox(height: 25),

                // 5. Upload ID Box
                const Text(
                  "Medical ID / Badge",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _medicalIdImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _medicalIdImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text.rich(
                                TextSpan(
                                  text: "Tap to upload",
                                  style: TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: " or drag file here",
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 30),

                // 6. Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Create Account",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 5),
                    Text(
                      "Encrypted & HIPAA Compliant",
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: inputTextStyle,
          decoration: _inputDecoration(hint: hint, icon: icon),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      prefixIcon: icon != null
          ? Icon(icon, color: Colors.grey[600], size: 20)
          : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1B5AF0), width: 2),
      ),
    );
  }

  Widget _buildProgressDot(String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: isActive ? 24 : 10,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1B5AF0) : Colors.grey[300],
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? const Color(0xFF1B5AF0) : Colors.grey[400],
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLine() {
    return Container(
      width: 30,
      height: 2,
      color: Colors.grey[200],
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 15),
    );
  }
}
