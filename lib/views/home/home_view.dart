import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/dummy_data.dart';
import '../task/task_form_view.dart';
import '../profile/profile_view.dart';
import '../pet/pet_view.dart';
import '../leaderboard/leaderboard_view.dart'; // Mới
import '../shared/shared_task_view.dart'; // Mới

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final List<String> categories = ['Tất cả', 'Đại học', 'Cá nhân', 'Thể thao'];
  String selectedCategory = 'Tất cả';
  final List<Map<String, dynamic>> todayTasks = DummyData.getTasksByDay(21);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGamificationTopBar(),
            const SizedBox(height: 20),
            _buildHeader(),
            const SizedBox(height: 15),
            _buildDynamicFilters(),
            const SizedBox(height: 15),
            Expanded(child: _buildTaskList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TaskFormView()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildGamificationTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // MENU CHỨA TẤT CẢ TÍNH NĂNG SOCIAL & PROFILE
          PopupMenuButton<String>(
            color: AppColors.card,
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade800),
            ),
            onSelected: (value) {
              Widget? screen;
              if (value == 'profile') screen = const ProfileView();
              if (value == 'pet') screen = const PetView();
              if (value == 'leaderboard') screen = const LeaderboardView();
              if (value == 'shared') screen = const SharedTaskView();

              if (screen != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => screen!),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text('Thông tin cá nhân'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pet',
                child: Row(
                  children: [
                    Icon(Icons.pets, color: Colors.orange),
                    SizedBox(width: 10),
                    Text('Pet giữ chuỗi'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'leaderboard',
                child: Row(
                  children: [
                    Icon(Icons.emoji_events_outlined, color: AppColors.gold),
                    SizedBox(width: 10),
                    Text('BXH Chuỗi'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'shared',
                child: Row(
                  children: [
                    Icon(Icons.group_outlined, color: Colors.greenAccent),
                    SizedBox(width: 10),
                    Text('Công việc nhóm'),
                  ],
                ),
              ),
            ],
            child: const CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),

          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Lv. 12 - Chiến binh",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: 0.8,
                  color: AppColors.hpRed,
                  backgroundColor: Colors.grey[800],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: 0.4,
                  color: AppColors.primary,
                  backgroundColor: Colors.grey[800],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: const [
                  Text(
                    "15",
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: const [
                  Text(
                    "350",
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.monetization_on, color: AppColors.gold, size: 18),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Chào buổi sáng, Tài!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Thứ Hai, 21 Tháng 9, 2026",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Hôm nay có ${todayTasks.length} nhiệm vụ đang chờ.",
            style: const TextStyle(color: AppColors.textSub),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicFilters() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          bool isSelected = categories[index] == selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => selectedCategory = categories[index]),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.black : AppColors.textMain,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskList() {
    List<Map<String, dynamic>> filteredTasks = selectedCategory == 'Tất cả'
        ? todayTasks
        : todayTasks.where((t) => t['cat'] == selectedCategory).toList();
    if (filteredTasks.isEmpty)
      return const Center(
        child: Text(
          "Không có công việc",
          style: TextStyle(color: AppColors.textSub),
        ),
      );

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) => _buildTaskCard(filteredTasks[index]),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TaskFormView(task: task)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[850]!),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.textSub, width: 2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title'] ?? '',
                    style: const TextStyle(
                      color: AppColors.textMain,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.textSub,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task['time'] ?? '',
                        style: const TextStyle(
                          color: AppColors.textSub,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(50),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "+${task['exp'] ?? 0} EXP",
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(50),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Text(
                              "+${task['gold'] ?? 0} ",
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(
                              Icons.monetization_on,
                              color: Colors.orange,
                              size: 11,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (task['high'] == true)
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.hpRed,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
