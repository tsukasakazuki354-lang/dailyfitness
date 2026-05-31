import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Cloudinary upload service using unsigned upload preset.
/// Replace these values with your own Cloudinary credentials.
class CloudinaryService {
  // ─── REPLACE THESE WITH YOUR CLOUDINARY DETAILS ───
  static const String cloudName = 'YOUR_CLOUD_NAME'; // e.g., 'dxxxxxxxx'
  static const String uploadPreset = 'daily_fitness_uploads'; // your preset name
  // ──────────────────────────────────────────────────

  static String get _uploadUrl => 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// Upload image bytes to Cloudinary and return the secure URL.
  /// [folder] - optional subfolder (e.g., 'sellers/uid123')
  /// [fileName] - optional custom public_id
  static Future<String> uploadImage({
    required Uint8List bytes,
    String? folder,
    String? fileName,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      // Add the image file
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName ?? 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      // Add upload parameters
      request.fields['upload_preset'] = uploadPreset;
      if (folder != null) request.fields['folder'] = folder;

      // Send the request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        return jsonResponse['secure_url'] as String;
      } else {
        throw Exception('Upload failed: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      throw Exception('Cloudinary upload error: $e');
    }
  }
}
