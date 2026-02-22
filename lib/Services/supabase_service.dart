import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

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

  Future<String?> register(String email, String password, String name) async {
    try {
      AuthResponse res = await _client.auth.signUp(
        email: email,
        password: password,
      );

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

  Stream<List<Map<String, dynamic>>> getReports() {
    return _client
        .from('reports')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }
}
