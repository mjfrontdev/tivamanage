import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'controllers/auth_controller.dart';
import 'middleware/auth_middleware.dart';
import 'views/home_view.dart';
import 'views/login_view.dart';
import 'views/system_detail_view.dart';

Future<void> main() async {
  await GetStorage.init();
  Get.put(AuthController(), permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return GetMaterialApp(
      title: 'Company Systems',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: auth.isLoggedIn ? '/' : '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginView()),
        GetPage(
          name: '/',
          page: () => const HomeView(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/system',
          page: () => const SystemDetailView(),
          middlewares: [AuthMiddleware()],
        ),
      ],
    );
  }
}
