import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart'; // Add this for MediaType

class ApiService {
  static const String baseUrl = 'http://192.168.0.105:8000'; // Your IP

  static Future<Map<String, dynamic>> scanLabel(File imageFile) async {
    try {
      print('🔵 Connecting to: $baseUrl/scan-label/');
      print('📸 Original file path: ${imageFile.path}');

      // Get file extension
      String fileName = path.basename(imageFile.path);
      String fileExtension = path.extension(imageFile.path).toLowerCase();

      print('📄 File name: $fileName');
      print('🔤 File extension: $fileExtension');

      // Ensure it has a proper image extension
      if (!['.jpg', '.jpeg', '.png', '.gif', '.bmp'].contains(fileExtension)) {
        // If no valid extension, add .jpg
        String newPath = imageFile.path + '.jpg';
        print('⚠️ Adding .jpg extension');
        await imageFile.copy(newPath);
        imageFile = File(newPath);
      }

      var uri = Uri.parse('$baseUrl/scan-label/');
      var request = http.MultipartRequest('POST', uri);

      // Important: Add the file with proper content-type
      var multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: 'image.jpg', // Always send as image.jpg
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      print('📤 Sending image...');
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server error: ${response.body}');
      }
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

  static Future<bool> testConnection() async {
    try {
      print('🔍 Testing: $baseUrl/test');
      final response = await http
          .get(Uri.parse('$baseUrl/test'))
          .timeout(const Duration(seconds: 5));

      print('📥 Test response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Test failed: $e');
      return false;
    }
  }
}