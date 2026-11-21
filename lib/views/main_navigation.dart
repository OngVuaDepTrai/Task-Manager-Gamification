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

class _MainNavigationState extends State<MainNavigation> {
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
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
