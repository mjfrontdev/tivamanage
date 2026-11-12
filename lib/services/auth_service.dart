import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class AuthService {
  final _storage = GetStorage();

  String? get token => _storage.read<String>('token');
  String? get role => _storage.read<String>('role');
  String? get username => _storage.read<String>('username');
  bool get isLoggedIn => token != null;
  bool get isAdmin => role == 'admin';

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('${ApiClient.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username, 'password': password},
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('Invalid username or password');
    }
    final data = jsonDecode(res.body);
    await _storage.write('token', data['access_token']);
    await _storage.write('role', data['role']);
    await _storage.write('username', data['username']);
    return data;
  }

  Future<void> logout() async {
    await _storage.erase();
  }
}
