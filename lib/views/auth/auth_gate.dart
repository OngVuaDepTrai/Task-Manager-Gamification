import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_session.dart';
import '../../core/database_helper.dart';
import '../../services/notification_service.dart';
import '../../view_models/gamification_view_model.dart';
import '../main_navigation.dart';
import 'auth_view.dart';

// Màn khởi động: còn phiên đăng nhập thì vào thẳng app, không bắt đăng nhập lại
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    bool ok = false;
    String? message;
    try {
      final user = await DatabaseHelper.instance.restoreSession();
      if (user != null) {
        AppSession.currentUser = user;
        if (!mounted) return;
        final summary = await context
            .read<GamificationViewModel>()
            .evaluatePastDays();
        await NotificationService().requestPermissions(askExactAlarm: false);
        await NotificationService().rescheduleAllForUser(user.id!);
        // Nghe việc nhóm mới được giao (Realtime)
        NotificationService().startGroupTaskListener(user.id!);
        ok = true;
        if (summary.hasChanges) {
          message = "Chào ${user.name}! ${summary.toMessage()}";
        }
      }
    } catch (e) {
      debugPrint("AuthGate lỗi: $e");
    }

    if (!mounted) return;
    setState(() {
      _loggedIn = ok;
      _loading = false;
    });

    if (message != null) {
      final text = message;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(text)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return _loggedIn ? const MainNavigation() : const AuthView();
  }
}
