// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../utils/constants.dart'; 

// class SuviService {
  
//   // -------------------------------------------------------
//   // 🧹 CLEAN AI TEXT (Removes Thoughts & Markdown)
//   // -------------------------------------------------------
//   static String cleanTextForSuvi(String rawText) {
//     String cleaned = rawText;
    
//     // 1. Remove the Gemma thought blocks (e.g., <unused94>thought ... )
//     // This regex looks for <unused94>thought (or similar) and removes everything 
//     // until a double newline or the end of the string.
//     cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>thought[\s\S]*?(?=\n\n|\Z|<unused95>)', caseSensitive: false), '');
    
//     // 2. Remove any remaining internal XML/system tags completely (like <unused95>, <start_of_turn>, etc.)
//     cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>'), '');
    
//     // 3. Strip Markdown asterisks, hashes, and backticks so the Voice engine doesn't read them
//     cleaned = cleaned.replaceAll('*', '')
//                      .replaceAll('#', '')
//                      .replaceAll('`', '');
    
//     // 4. Clean up excessive newlines or spaces left behind by the removal
//     cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
//     return cleaned.trim();
//   }

//   // -------------------------------------------------------
//   // 🗣️ TALK TO SUVI (Text + Optional Image)
//   // -------------------------------------------------------
//   static Future<String> chatWithSuvi({
//     required String text,
//     required String patientId,
//     File? imageFile
//   }) async {
    
//     try {
//       // 1. Get URL from Preferences (Allows dynamic updates from Settings page)
//       final prefs = await SharedPreferences.getInstance();
//       String baseUrl = prefs.getString('ngrok_url') ?? AppConstants.ngrokUrl;

//       // 2. Build Uri
//       var uri = Uri.parse("$baseUrl/suvi/chat");
      
//       // We use MultipartRequest because we might be sending an Image file
//       var request = http.MultipartRequest('POST', uri);

//       // 3. Add Text Data (The Doctor's Question & Patient ID)
//       request.fields['text'] = text;
//       request.fields['patient_id'] = patientId;

//       // 4. Add Image (If the doctor selected an X-Ray/Scan)
//       if (imageFile != null) {
//         var pic = await http.MultipartFile.fromPath("file", imageFile.path);
//         request.files.add(pic);
//       }

//       // 5. Send the request to Kaggle
//       var streamedResponse = await request.send();
//       var response = await http.Response.fromStream(streamedResponse);

//       if (response.statusCode == 200) {
//         // 6. Success! Decode the JSON response
//         var data = jsonDecode(response.body);
//         String rawResponse = data['response'] ?? "";
        
//         // 7. CLEAN THE TEXT before returning it so the UI and TTS get pure conversational text
//         return cleanTextForSuvi(rawResponse);
        
//       } else {
//         return "Error: Suvi is currently offline or the NGROK URL expired. (Status: ${response.statusCode})";
//       }
//     } catch (e) {
//       return "Connection Error: Check your internet or update the Ngrok URL in settings.";
//     }
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart'; 

class SuviService {
  
  // -------------------------------------------------------
  // 🧹 CLEAN AI TEXT (Removes Thoughts & Markdown)
  // -------------------------------------------------------
  static String cleanTextForSuvi(String rawText) {
    String cleaned = rawText;
    
    // 1. Remove the Gemma thought blocks
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>thought[\s\S]*?(?=\n\n|\Z|<unused95>)', caseSensitive: false), '');
    
    // 2. Remove any remaining internal XML/system tags completely
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // 3. Strip Markdown asterisks, hashes, and backticks
    cleaned = cleaned.replaceAll('*', '')
                     .replaceAll('#', '')
                     .replaceAll('`', '');
    
    // 4. Clean up excessive newlines
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    return cleaned.trim();
  }

  // -------------------------------------------------------
  // 🗣️ TALK TO SUVI (Text + Optional Image)
  // -------------------------------------------------------
  static Future<String> chatWithSuvi({
    required String text,
    required String patientId,
    File? imageFile
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

  // -------------------------------------------------------
  // 👁️ AEGIS-VISION: IDENTIFY PATIENT BY FACE
  // -------------------------------------------------------
  static Future<Map<String, dynamic>> identifyPatientFace(File imageFile) async {
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
        return {"status": "error", "message": "Server error ${response.statusCode}"};
      }
    } catch (e) {
      return {"status": "error", "message": "Connection failed. Check Ngrok."};
    }
  }

  // -------------------------------------------------------
  // ✍️ AEGIS-SCRIBE: GENERATE REPORT
  // -------------------------------------------------------
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