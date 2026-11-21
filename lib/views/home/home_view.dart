import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_session.dart';
import '../../core/database_helper.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../widgets/task_card_widget.dart';
import '../task/task_form_view.dart';
import '../profile/profile_view.dart';
import '../pet/pet_view.dart';
import '../leaderboard/leaderboard_view.dart';
import '../shared/shared_task_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<String> categories = ['Tất cả'];
  String selectedCategory = 'Tất cả';

  final List<String> reminderFilters = [
    'Tất cả',
    'Cần làm',
    'Hàng ngày',
    'Quá hạn',
  ];
  String selectedReminderFilter = 'Tất cả';

  List<TaskModel> todayTasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasksAndCategories();
  }

  Future<void> _loadTasksAndCategories() async {
    final user = AppSession.currentUser;
    if (user != null && user.id != null) {
      final now = DateTime.now();
      final tasks = await DatabaseHelper.instance.getTasksForDate(
        user.id!,
        now.day,
        now.month,
        now.year,
      );
      final dbCategories = await DatabaseHelper.instance.getCategories(
        user.id!,
      );

      if (!mounted) return;
      setState(() {
        todayTasks = tasks;
        categories = [
          'Tất cả',
          ...dbCategories.map((c) => c['name'] as String),
        ];

        if (!categories.contains(selectedCategory)) {
          selectedCategory = 'Tất cả';
        }
        isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = todayTasks.where((t) => !t.isDone).length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGamificationTopBar(),
            const SizedBox(height: 16),
            _buildHeader(pendingCount, todayTasks.length),
            const SizedBox(height: 12),
            _buildReminderStatusFilters(),
            const SizedBox(height: 10),
            _buildDynamicFilters(),
            const SizedBox(height: 12),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _buildTaskList(todayTasks),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TaskFormView()),
          );
          if (result == true) {
            _loadTasksAndCategories();
          }
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildGamificationTopBar() {
    final user = AppSession.currentUser;
    final int exp = user?.exp ?? 0;
    final int gold = user?.gold ?? 0;
    final int streak = user?.currentStreak ?? 0;

    final int level = (exp ~/ 100) + 1;
    final double expProgress = (exp % 100) / 100.0;

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
          PopupMenuButton<String>(
            color: AppColors.card,
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade800),
            ),
            onSelected: (value) async {
              Widget? screen;
              if (value == 'profile') screen = const ProfileView();
              if (value == 'pet') screen = const PetView();
              if (value == 'leaderboard') screen = const LeaderboardView();
              if (value == 'shared') screen = const SharedTaskView();

              if (screen != null) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => screen!),
                );
                _loadTasksAndCategories();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text('Thông tin cá nhân'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'pet',
                child: Row(
                  children: [
                    Icon(Icons.pets, color: Colors.orange),
                    SizedBox(width: 10),
                    Text('Pet giữ chuỗi'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'leaderboard',
                child: Row(
                  children: [
                    Icon(Icons.emoji_events_outlined, color: AppColors.gold),
                    SizedBox(width: 10),
                    Text('BXH Chuỗi'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'shared',
                child: Row(
                  children: [
                    Icon(Icons.group_outlined, color: Colors.greenAccent),
                    SizedBox(width: 10),
                    Text('Bạn bè & Việc nhóm'),
                  ],
                ),
              ),
            ],
            child: Builder(
              builder: (context) {
                String? path = user?.avatarPath;
                if (path == null || path.isEmpty) {
                  return CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user?.name.substring(0, 1).toUpperCase() ?? "U",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  );
                }
                if (path.startsWith('icon:')) {
                  int codePoint = int.parse(path.split(':')[1]);
                  return CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      IconData(codePoint, fontFamily: 'MaterialIcons'),
                      size: 24,
                      color: Colors.white,
                    ),
                  );
                }
                return CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  backgroundImage: FileImage(File(path)),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Lv. $level - Cấp độ",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: 1.0,
                  color: AppColors.hpRed,
                  backgroundColor: Colors.grey[800],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: expProgress,
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
                children: [
                  Text(
                    "$streak",
                    style: TextStyle(
                      color: streak > 0 ? AppColors.textMain : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.local_fire_department,
                    color: streak > 0 ? Colors.orange : Colors.grey,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    "$gold",
                    style: const TextStyle(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(
                    Icons.monetization_on,
                    color: AppColors.gold,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int pendingCount, int totalCount) {
    final now = DateTime.now();
    final userName = AppSession.currentUser?.name ?? "bạn";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Chào $userName!",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Hôm nay, ${now.day} Tháng ${now.month}, ${now.year}",
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            totalCount == 0
                ? "Chưa có nhắc nhở nào hôm nay. Bấm + để thêm nhé!"
                : "Còn $pendingCount/$totalCount nhắc nhở chưa hoàn thành.",
            style: const TextStyle(color: AppColors.textSub),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderStatusFilters() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: reminderFilters.length,
        itemBuilder: (context, index) {
          final filter = reminderFilters[index];
          final bool isSelected = filter == selectedReminderFilter;
          return GestureDetector(
            onTap: () => setState(() => selectedReminderFilter = filter),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withAlpha(35)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade800,
                ),
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textSub,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
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
          final bool isSelected = categories[index] == selectedCategory;
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

  Widget _buildTaskList(List<TaskModel> tasksList) {
    final now = DateTime.now();
    final filteredTasks = tasksList.where((t) {
      final matchCategory =
          selectedCategory == 'Tất cả' || t.category == selectedCategory;
      if (!matchCategory) return false;

      switch (selectedReminderFilter) {
        case 'Cần làm':
          return !t.isDone;
        case 'Hàng ngày':
          return t.isDaily;
        case 'Quá hạn':
          return t.isOverdue(now);
        default:
          return true;
      }
    }).toList();

    filteredTasks.sort((a, b) {
      if (a.isDone && !b.isDone) return 1;
      if (!a.isDone && b.isDone) return -1;

      if (a.isHighPriority && !b.isHighPriority) return -1;
      if (!a.isHighPriority && b.isHighPriority) return 1;

      return a.time.compareTo(b.time);
    });

    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.inbox, size: 60, color: AppColors.textSub),
            SizedBox(height: 10),
            Text(
              "Không có công việc phù hợp bộ lọc.",
              style: TextStyle(color: AppColors.textSub, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        var task = filteredTasks[index];
        return TaskCardWidget(
          task: task,
          onEdit: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TaskFormView(task: task)),
            );
            if (result == true) {
              _loadTasksAndCategories();
            }
          },
          onComplete: () async {
            if (!task.isDone) {
              setState(() => task.isDone = true);

              final user = AppSession.currentUser;
              if (user != null && user.id != null) {
                final updatedUser = UserModel(
                  id: user.id,
                  name: user.name,
                  email: user.email,
                  password: user.password,
                  exp: user.exp + task.exp,
                  gold: user.gold + task.gold,
                  currentStreak: user.currentStreak == 0
                      ? 1
                      : user.currentStreak,
                  longestStreak: user.longestStreak == 0
                      ? 1
                      : user.longestStreak,
                  avatarPath: user.avatarPath,
                );

                AppSession.currentUser = updatedUser;
                await DatabaseHelper.instance.updateUserStats(updatedUser);

                await DatabaseHelper.instance.setTaskCompletionForDate(
                  userId: user.id!,
                  task: task,
                  isDone: true,
                  day: now.day,
                  month: now.month,
                  year: now.year,
                );
              }

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '🎉 Hoàn thành "${task.title}"! +${task.exp} EXP & +${task.gold} Vàng',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              setState(() {});
            }
          },
        );
      },
    );
  }
}
