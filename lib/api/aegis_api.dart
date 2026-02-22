import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';

class AegisApi {
  // The function to talk to the Brain
  static Future<String> askNurse(String text, File? image) async {
    try {
      // 1. TODO: Add Logic here to check RAM (Hybrid Check)
      // If RAM > 8GB && Image == null -> Run Local Model
      // Else -> Run Cloud Model (Below)

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${AppConstants.ngrokUrl}/nurse/chat"),
      );

      request.fields['text'] = text;

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['response'];
      } else {
        return "Error: Server is down (${response.statusCode})";
      }
    } catch (e) {
      return "Error: Could not connect to AEGIS Brain.";
    }
  }
}
