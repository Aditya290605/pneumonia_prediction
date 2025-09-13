import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pneumonia_prediction/app/services/get_data.dart';

class PredictScreen extends StatefulWidget {
  @override
  _PredictScreenState createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  io.File? _selectedImageFile;
  Uint8List? _selectedImageBytes; // for Web
  Map<String, dynamic>? _result;
  bool _loading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageFile = null;
          _result = null;
        });
      } else {
        setState(() {
          _selectedImageFile = io.File(pickedFile.path);
          _selectedImageBytes = null;
          _result = null;
        });
      }
    }
  }

  Future<void> _sendToApi() async {
    if (_selectedImageFile == null && _selectedImageBytes == null) return;

    setState(() => _loading = true);

    try {
      final res = await ApiService.predict(
        file: _selectedImageFile,
        bytes: _selectedImageBytes,
      );
      setState(() => _result = res);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pneumonia Detection")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Image Picker
            ElevatedButton(
              onPressed: _pickImage,
              child: Text("Pick X-Ray Image"),
            ),
            const SizedBox(height: 10),

            if (_selectedImageFile != null)
              Image.file(_selectedImageFile!, height: 200)
            else if (_selectedImageBytes != null)
              Image.memory(_selectedImageBytes!, height: 200),

            const SizedBox(height: 10),

            // Send to API
            ElevatedButton(onPressed: _sendToApi, child: Text("Analyze")),
            const SizedBox(height: 20),

            if (_loading) CircularProgressIndicator(),

            if (_result != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Prediction: ${_result!['prediction']}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text("Probability: ${_result!['probability']}"),
                      Text("Threshold Used: ${_result!['threshold_used']}"),
                      Text("Confidence: ${_result!['confidence']}"),
                      const SizedBox(height: 10),

                      // Show Diagnosed Image from backend
                      if (_result!['diagnosed_image_url'] != null)
                        Image.network(
                          _result!['diagnosed_image_url'],
                          height: 250,
                          errorBuilder: (context, error, stackTrace) {
                            return Text("Could not load diagnosed image");
                          },
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
