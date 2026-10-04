import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Thông tin cá nhân'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              "Huỳnh Thanh Tài", // Placeholder cho tên của bạn
              style: TextStyle(
                color: AppColors.textMain,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Tài khoản sẽ được thiết kế chi tiết sau...",
              style: TextStyle(color: AppColors.textSub),
            ),
          ],
        ),
      ),
    );
  }
}
