import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static String get wsUrl {
    return baseUrl.replaceFirst('http', 'ws') + '/ws';
  }

  final http.Client _client = http.Client();
  final _storage = GetStorage();

  Map<String, String> get _headers {
    final token = _storage.read<String>('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer ' + token,
    };
  }

  Future<dynamic> get(String path) async {
    final res = await _client
        .get(Uri.parse(baseUrl + path), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 401) {
      await _storage.erase();
      throw Exception('UNAUTHORIZED');
    }
    if (res.statusCode >= 400) {
      throw Exception('GET ' + path + ' failed: ' + res.statusCode.toString());
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await _client
        .post(Uri.parse(baseUrl + path), headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 401) {
      await _storage.erase();
      throw Exception('UNAUTHORIZED');
    }
    if (res.statusCode >= 400) {
      throw Exception('POST ' + path + ' failed: ' + res.statusCode.toString());
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }
}
