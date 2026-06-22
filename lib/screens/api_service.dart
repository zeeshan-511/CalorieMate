import 'dart:convert';
import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.0.114:9000';

  static Future<Map<String, dynamic>> scanLabel(File imageFile) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      print('📸 OCR image path: ${imageFile.path}');

      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await textRecognizer.processImage(inputImage);

      final rawText = recognizedText.text.trim();

      print('📝 OCR TEXT: $rawText');

      if (rawText.isEmpty) {
        throw Exception('No text detected. Please scan ingredients clearly.');
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/test-ocr'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'ocrText': rawText,
              'scannedText': rawText,
              'text': rawText,
              'scanResult': {
                'ocrText': rawText,
                'text': rawText,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('📥 OCR clean status: ${response.statusCode}');
      print('📥 OCR clean body: ${response.body}');

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          ...decoded,
          'ocrText': rawText,
          'scannedText': rawText,
          'text': rawText,
          'rawText': rawText,
        };
      }

      throw Exception(decoded['message'] ?? 'OCR server error');
    } catch (e) {
      print('❌ scanLabel error: $e');
      rethrow;
    } finally {
      await textRecognizer.close();
    }
  }

  static Future<void> saveScanHistory({
    required String userId,
    required Map<String, dynamic> scanData,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/scan-history'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer dummy-token',
          },
          body: jsonEncode({
            'userId': userId,
            'ocrText': scanData['ocrText'] ??
                scanData['rawText'] ??
                scanData['text'] ??
                '',
            'scannedText': scanData['scannedText'] ??
                scanData['rawText'] ??
                scanData['text'] ??
                '',
            'ingredients': scanData['ingredients'] ?? [],
            'scanResult': scanData,
          }),
        )
        .timeout(const Duration(seconds: 15));

    print('📥 Save history status: ${response.statusCode}');
    print('📥 Save history body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to save scan history: ${response.body}');
    }
  }

  static Future<List<dynamic>> getScanHistory(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/scan-history/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer dummy-token',
      },
    ).timeout(const Duration(seconds: 15));

    print('📥 History status: ${response.statusCode}');
    print('📥 History body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic> && data['history'] is List) {
        return data['history'];
      }

      if (data is List) return data;

      return [];
    }

    throw Exception('Failed to fetch scan history: ${response.body}');
  }

  static Future<Map<String, dynamic>> analyzeScannedProduct({
    required String userId,
    required List<String> ingredients,
    String productName = 'Scanned Product',
    String? scanHistoryId,
    String? rawOcrText,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/analyze-scanned-product'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer dummy-token-$userId',
          },
          body: jsonEncode({
            'userId': userId,
            'productName': productName,
            'ingredients': ingredients,
            if (scanHistoryId != null && scanHistoryId.isNotEmpty)
              'scanHistoryId': scanHistoryId,
            if (rawOcrText != null && rawOcrText.isNotEmpty)
              'rawOcrText': rawOcrText,
          }),
        )
        .timeout(const Duration(seconds: 35));

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return decoded;
    }

    throw Exception(
      decoded['message'] ?? 'Failed to analyze scanned product',
    );
  }

  static Future<bool> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Test failed: $e');
      return false;
    }
  }
}
