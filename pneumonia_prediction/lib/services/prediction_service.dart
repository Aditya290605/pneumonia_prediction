import 'dart:io';
import 'package:dio/dio.dart';
import '../models/prediction_model.dart';

class PredictionService {
  static const String _baseUrl =
      'https://pneumonia-prediction-016u.onrender.com';
  late final Dio _dio;

  PredictionService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 50),
      receiveTimeout: const Duration(seconds: 50),
      sendTimeout: const Duration(seconds: 50),
    ));
  }

  Future<PredictionModel> predictPneumonia(File imageFile) async {
    try {
      // Create form data with the image file
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'xray_image.jpg',
        ),
      });

      // Make the POST request
      Response response = await _dio.post(
        '/predict',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        return PredictionModel.fromJson(response.data);
      } else {
        throw Exception('Failed to get prediction: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Server response timeout. Please try again.');
      } else if (e.type == DioExceptionType.sendTimeout) {
        throw Exception('Request timeout. Please try again.');
      } else if (e.response != null) {
        throw Exception('Server error: ${e.response?.statusCode}');
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
