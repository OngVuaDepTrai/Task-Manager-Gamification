import 'dart:async';

import 'package:provider/provider.dart';

import '../core/app_session.dart';
import '../services/notification_service.dart';
import '../view_models/gamification_view_model.dart';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'home/home_view.dart';
import 'calendar/calendar_view.dart';
import 'streak/streak_view.dart';
import 'shop/shop_view.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with WidgetsBindingObserver {
  late final Future<void> initial;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initial = context.read<GamificationViewModel>().refresh();
    restoreReminders();
    timer = Timer.periodic(const Duration(minutes: 1), (_) => refresh());
  }

  String _date = DateTime.now().toIso8601String().substring(0, 10);
  Future<void> restoreReminders() async {
    try {
      await NotificationService().restore();
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể khôi phục nhắc nhở: $e')),
        );
      }
    }
  }

  void refresh() {
    if (!mounted || AppSession.currentUser == null) return;
    final date = DateTime.now().toIso8601String().substring(0, 10);
    if (date != _date) {
      _date = date;
      restoreReminders();
    }
    context.read<GamificationViewModel>().refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  int _currentIndex = 0;

  // Danh sách các màn hình tương ứng với tab (Đã dọn dẹp các dòng nháp dư thừa)
  final List<Widget> _screens = [
    const HomeView(),
    const CalendarView(),
    const StreakView(),
    const ShopView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: initial,
        builder: (context, s) {
          if (s.hasError) {
            return Center(child: Text('Không thể tải tài khoản: ${s.error}'));
          }
          if (s.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return _screens[_currentIndex];
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          refresh();
        },
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSub,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: "Trang chủ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Lịch",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department),
            label: "Chuỗi",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: "Cửa hàng",
          ),
        ],
      ),
    );
  }
}
