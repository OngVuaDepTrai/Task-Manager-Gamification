import 'package:flutter/material.dart';

import 'core/app_colors.dart';
import 'views/auth/auth_view.dart'; // Đổi import thành AuthView

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Gamification',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
      ),
      // Quan trọng: Đổi trang khởi động (home) thành AuthView
      home: const AuthView(),
    );
  }
}
