import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // 1. Login
  Future<String?> login(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return null; // Success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Login failed";
    }
  }

  // 2. Sign Up
  Future<String?> register(String email, String password, String name) async {
    try {
      AuthResponse res = await _client.auth.signUp(
        email: email,
        password: password,
      );

      // Create Profile entry
      if (res.user != null) {
        await _client.from('profiles').insert({
          'id': res.user!.id,
          'first_name': name.split(" ")[0],
          'last_name': name.split(" ").length > 1 ? name.split(" ")[1] : "",
          'specialty': 'General',
        });
      }
      return null;
    } catch (e) {
      return "Registration failed: $e";
    }
  }

  // 3. Fetch Recent Reports (For Dashboard)
  Stream<List<Map<String, dynamic>>> getReports() {
    return _client
        .from('reports')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }
}
