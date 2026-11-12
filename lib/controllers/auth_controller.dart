import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _auth = AuthService();

  final isLoading = false.obs;
  final error = ''.obs;
  final role = ''.obs;
  final username = ''.obs;

  @override
  void onInit() {
    super.onInit();
    role.value = _auth.role ?? '';
    username.value = _auth.username ?? '';
  }

  bool get isLoggedIn => _auth.isLoggedIn;
  bool get isAdmin => role.value == 'admin';

  Future<bool> login(String user, String pass) async {
    isLoading.value = true;
    error.value = '';
    try {
      final data = await _auth.login(user.trim(), pass);
      role.value = data['role'];
      username.value = data['username'];
      return true;
    } catch (e) {
      error.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    role.value = '';
    username.value = '';
    Get.offAllNamed('/login');
  }

  void showLogoutDialog() {
    Get.dialog(AlertDialog(
      title: const Text('Logout'),
      content: Text('Logout from "${username.value}"?'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            Get.back();
            logout();
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: const Text('Logout'),
        ),
      ],
    ));
  }
}
