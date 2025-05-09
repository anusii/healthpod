import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ApiService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'YOUR_API_BASE_URL', // Replace with your actual API base URL
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  static Future<Response> get(String endpoint, BuildContext context) async {
    try {
      return await _dio.get(endpoint);
    } on DioException catch (e) {
      debugPrint('API Error: ${e.message}');
      rethrow;
    }
  }

  static Future<Response> post(
      String endpoint, dynamic data, BuildContext context) async {
    try {
      return await _dio.post(endpoint, data: data);
    } on DioException catch (e) {
      debugPrint('API Error: ${e.message}');
      rethrow;
    }
  }
}
