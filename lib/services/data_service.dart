import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class DataService {
  // Backend server URL - replace with your actual server URL
  // For local development with Flask, typically http://10.0.2.2:5000 for Android emulator
  // or http://localhost:5000 for web
  static const String baseUrl = 'http://10.0.2.2:5000';

  // Process the uploaded file
  static Future<Map<String, dynamic>> processData(File file) async {
    try {
      // Create a multipart request
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/process_data'));

      // Add the file to the request
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: basename(file.path),
      ));

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Check if the request was successful
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to process data: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error processing data: $e');
    }
  }
}