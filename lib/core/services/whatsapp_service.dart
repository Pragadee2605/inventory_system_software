import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class WhatsAppService {
  static final _logger = Logger('WhatsAppService');

  // These should ideally be moved to a secure settings/environment configuration
  static const String _accessToken = "YOUR_META_ACCESS_TOKEN";
  static const String _phoneNumberId = "YOUR_PHONE_NUMBER_ID";
  static const String _apiVersion = "v21.0";

  /// Sends a PDF document directly to a phone number via WhatsApp Cloud API
  static Future<bool> sendInvoicePdf({
    required String toNumber,
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    try {
      // 1. Clean phone number (remove +, spaces, etc.)
      final cleanNumber = toNumber.replaceAll(RegExp(r'[^0-9]'), '');

      // 2. Upload Media to Meta Servers to get a Media ID
      final mediaId = await _uploadMedia(pdfBytes, fileName);
      if (mediaId == null) return false;

      // 3. Send Message with Media ID
      final response = await http.post(
        Uri.parse('https://graph.facebook.com/$_apiVersion/$_phoneNumberId/messages'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "messaging_product": "whatsapp",
          "recipient_type": "individual",
          "to": cleanNumber,
          "type": "document",
          "document": {
            "id": mediaId,
            "filename": fileName
          }
        }),
      );

      if (response.statusCode == 200) {
        _logger.info('Invoice sent successfully to $cleanNumber');
        return true;
      } else {
        _logger.severe('Failed to send message: ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.severe('Error in WhatsApp direct send: $e');
      return false;
    }
  }

  /// Internal helper to upload the PDF bytes to Meta
  static Future<String?> _uploadMedia(Uint8List bytes, String fileName) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://graph.facebook.com/$_apiVersion/$_phoneNumberId/media'),
      );

      request.headers['Authorization'] = 'Bearer $_accessToken';
      request.fields['messaging_product'] = 'whatsapp';
      
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        // contentType: MediaType('application', 'pdf'), // Requires http_parser package
      ));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final json = jsonDecode(responseData);
        return json['id'];
      } else {
        _logger.severe('Media upload failed: $responseData');
        return null;
      }
    } catch (e) {
      _logger.severe('Error uploading media: $e');
      return null;
    }
  }
}
