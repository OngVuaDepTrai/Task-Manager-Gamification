import 'package:flutter/material.dart';

import 'core/app_colors.dart'; // Đổi lại đường dẫn cho đúng với thư mục của bạn
import 'views/main_navigation.dart'; // Đổi lại đường dẫn cho đúng với file MainNavigation

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager Gamification',
      debugShowCheckedModeBanner: false,
      // Thiết lập giao diện tối mặc định để khớp với AppColors của bạn
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
      ),
      // Gọi màn hình thanh điều hướng chính
      home: const MainNavigation(),
    );
  }
}
