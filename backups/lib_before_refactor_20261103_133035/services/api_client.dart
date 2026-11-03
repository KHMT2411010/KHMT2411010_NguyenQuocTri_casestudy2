
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static const FlutterSecureStorage _storage =
  FlutterSecureStorage();

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }

    return 'http://localhost:3000';
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: 'auth_token');
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> _request(
      String method,
      String endpoint, {
        Map<String, dynamic>? body,
      }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = await _headers();

    late http.Response response;

    final encodedBody = body == null ? null : jsonEncode(body);

    try {
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;

        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: encodedBody,
          );
          break;

        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: encodedBody,
          );
          break;

        case 'PATCH':
          response = await http.patch(
            uri,
            headers: headers,
            body: encodedBody,
          );
          break;

        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;

        default:
          throw Exception('HTTP method không hỗ trợ');
      }
    } catch (error) {
      throw Exception('Không kết nối được tới máy chủ: $error');
    }

    Map<String, dynamic> data;

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else {
        throw const FormatException('Dữ liệu không phải JSON object');
      }
    } catch (_) {
      throw Exception('Máy chủ trả về dữ liệu không hợp lệ');
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        data['message'] ??
            'Lỗi HTTP ${response.statusCode}',
      );
    }

    return data;
  }

  static Future<Map<String, dynamic>> get(
      String endpoint,
      ) {
    return _request('GET', endpoint);
  }

  static Future<Map<String, dynamic>> post(
      String endpoint,
      Map<String, dynamic> body,
      ) {
    return _request('POST', endpoint, body: body);
  }

  static Future<Map<String, dynamic>> put(
      String endpoint,
      Map<String, dynamic> body,
      ) {
    return _request('PUT', endpoint, body: body);
  }

  static Future<Map<String, dynamic>> patch(
      String endpoint,
      Map<String, dynamic> body,
      ) {
    return _request('PATCH', endpoint, body: body);
  }

  static Future<Map<String, dynamic>> delete(
      String endpoint,
      ) {
    return _request('DELETE', endpoint);
  }
}
