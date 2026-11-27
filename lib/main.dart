import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_colors.dart';
import 'services/notification_service.dart';
import 'views/auth/auth_view.dart';
import 'view_models/task_view_model.dart';
import 'view_models/gamification_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Khởi tạo thông báo nhắc nhở (hẹn giờ qua hệ điều hành)
  await NotificationService().initService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Bọc MultiProvider ở cấp cao nhất để chuẩn bị kết nối Logic (Tuần 9 - GĐ2)
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskViewModel()),
        ChangeNotifierProvider(create: (_) => GamificationViewModel()),
      ],
      child: MaterialApp(
        title: 'Task Manager Gamification',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: AppColors.background,
        ),
        home: const AuthView(),
      ),
    );
  }
}
