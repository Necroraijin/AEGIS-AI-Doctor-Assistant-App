import 'package:aegis/Screens/auth/login_screen.dart';
import 'package:aegis/Screens/pages/home_page.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error in fetching the cameras: $e');
  }

  await Supabase.initialize(
    url: 'https://ceesnsewtbkouxjnzwqc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNlZXNuc2V3dGJrb3V4am56d3FjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzNzMyMzgsImV4cCI6MjA4Njk0OTIzOH0.19fxCmQ4iStEJo0_tq5j2PDtxInIVKLLFfTZMcfMq94',
  );

  final session = Supabase.instance.client.auth.currentSession;
  final isLoggedIn = session != null;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aegis Medical',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Inter',
      ),

      home: isLoggedIn ? const HomePage() : const LoginScreen(),
    );
  }
}
