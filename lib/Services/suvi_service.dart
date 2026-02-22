import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SuviService {
  static String cleanTextForSuvi(String rawText) {
    String cleaned = rawText;

    cleaned = cleaned.replaceAll(
      RegExp(
        r'<[^>]*>thought[\s\S]*?(?=\n\n|\Z|<unused95>)',
        caseSensitive: false,
      ),
      '',
    );

    cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>'), '');

    cleaned = cleaned
        .replaceAll('*', '')
        .replaceAll('#', '')
        .replaceAll('`', '');

    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return cleaned.trim();
  }

  static Future<String> chatWithSuvi({
    required String text,
    required String patientId,
    File? imageFile,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('ngrok_url') ?? AppConstants.ngrokUrl;

      var uri = Uri.parse("$baseUrl/suvi/chat");
      var request = http.MultipartRequest('POST', uri);

      request.fields['text'] = text;
      request.fields['patient_id'] = patientId;

      if (imageFile != null) {
        var pic = await http.MultipartFile.fromPath("file", imageFile.path);
        request.files.add(pic);
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String rawResponse = data['response'] ?? "";
        return cleanTextForSuvi(rawResponse);
      } else {
        return "Error: Suvi is currently offline. (Status: ${response.statusCode})";
      }
    } catch (e) {
      return "Connection Error: Check your internet or update the Ngrok URL in settings.";
    }
  }

  static Future<Map<String, dynamic>> identifyPatientFace(
    File imageFile,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('ngrok_url') ?? AppConstants.ngrokUrl;

      var uri = Uri.parse("$baseUrl/suvi/identify_face");
      var request = http.MultipartRequest('POST', uri);

      var pic = await http.MultipartFile.fromPath("file", imageFile.path);
      request.files.add(pic);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data as Map<String, dynamic>;
      } else {
        return {
          "status": "error",
          "message": "Server error ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"status": "error", "message": "Connection failed. Check Ngrok."};
    }
  }

  static Future<String> generateReport(String transcript) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('ngrok_url') ?? AppConstants.ngrokUrl;

      var uri = Uri.parse("$baseUrl/suvi/generate_report");
      var response = await http.post(uri, body: {"transcript": transcript});

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['report'] ?? "Error generating report.";
      }
      return "Error: Backend returned ${response.statusCode}";
    } catch (e) {
      return "Connection failed. Please check your backend.";
    }
  }
}
