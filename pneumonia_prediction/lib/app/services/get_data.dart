import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      "https://pneumonia-prediction-016u.onrender.com"; // change when deployed

  static Future<Map<String, dynamic>> predict({
    io.File? file,
    Uint8List? bytes,
  }) async {
    var uri = Uri.parse("$baseUrl/predict");
    var request = http.MultipartRequest("POST", uri);

    if (file != null) {
      // For mobile/desktop
      request.files.add(await http.MultipartFile.fromPath("file", file.path));
    } else if (bytes != null) {
      // For Web
      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          bytes,
          filename: "upload.jpg", // dummy filename
        ),
      );
    } else {
      throw Exception("No file or bytes provided for prediction");
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    print(response.body);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("Failed to predict: ${response.body}");
    }
  }
}
