import 'dart:io';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_session.dart';
import '../../core/database_helper.dart';
import '../../core/game_rules.dart';
import '../../models/task_model.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../services/widget_service.dart';
import '../../view_models/gamification_view_model.dart';
import '../../widgets/task_card_widget.dart';
import '../task/task_form_view.dart';
import '../profile/profile_view.dart';
import '../leaderboard/leaderboard_view.dart';
import '../friends/friends_view.dart';
import '../groups/groups_view.dart';
import '../notifications/notifications_view.dart';

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
  // Số lời mời kết bạn + thông báo chưa xem (hiện chấm đỏ trên avatar)
  int unseenCount = 0;

  // Tìm kiếm công việc theo tên / mô tả
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Hiệu ứng tung hoa khi hoàn thành đúng hạn
  late final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 2),
  );

  // Có việc nhóm mới qua Realtime -> tải lại danh sách và chấm đỏ thông báo
  void _onGroupTaskArrived() {
    if (mounted) _loadTasksAndCategories();
  }

  @override
  void dispose() {
    NotificationService.groupTaskArrived.removeListener(_onGroupTaskArrived);
    _searchController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadTasksAndCategories();
    NotificationService.groupTaskArrived.addListener(_onGroupTaskArrived);
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
      final unseen = await DatabaseHelper.instance.countUnseen(user.id!);

      if (!mounted) return;
      setState(() {
        todayTasks = tasks;
        unseenCount = unseen;
        // "Nhóm" là danh mục cố định để lọc việc nhóm được giao
        categories = [
          'Tất cả',
          DatabaseHelper.groupCategoryName,
          ...dbCategories
              .map((c) => c['name'] as String)
              .where((n) => n != DatabaseHelper.groupCategoryName),
        ];

        if (!categories.contains(selectedCategory)) {
          selectedCategory = 'Tất cả';
        }
        isLoading = false;
      });
      // Làm mới widget ngoài màn hình chính theo danh sách việc hôm nay
      WidgetService.update();
      // Cập nhật danh sách địa điểm cần theo dõi cho nhắc nhở GPS
      LocationService().refresh();
    } else {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = todayTasks.where((t) => !t.isDone).length;

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGamificationTopBar(),
                const SizedBox(height: 16),
                _buildHeader(pendingCount, todayTasks.length),
                const SizedBox(height: 12),
                _buildSearchBar(),
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
        ),
        // Tung hoa khi hoàn thành nhắc nhở đúng hạn
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildGamificationTopBar() {
    // Lắng nghe ViewModel để thanh trạng thái cập nhật ngay khi vàng/HP thay đổi
    context.watch<GamificationViewModel>();
    final user = AppSession.currentUser;
    final int hp = user?.hp ?? GameRules.maxHp;
    final int shields = user?.shields ?? 0;
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
              if (value == 'leaderboard') screen = const LeaderboardView();
              if (value == 'friends') screen = const FriendsView();
              if (value == 'groups') screen = const GroupsView();
              if (value == 'notifications') screen = const NotificationsView();

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
                value: 'friends',
                child: Row(
                  children: [
                    Icon(Icons.people_outline, color: Colors.lightBlueAccent),
                    SizedBox(width: 10),
                    Text('Bạn bè'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'groups',
                child: Row(
                  children: [
                    Icon(Icons.group_outlined, color: Colors.greenAccent),
                    SizedBox(width: 10),
                    Text('Việc nhóm'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'notifications',
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(width: 10),
                    const Text('Thông báo'),
                    if (unseenCount > 0) ...[
                      const SizedBox(width: 8),
                      _buildBadge(unseenCount),
                    ],
                  ],
                ),
              ),
            ],
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Builder(
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
                // Chấm đỏ báo có lời mời kết bạn / việc được giao chưa xem
                if (unseenCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.hpRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.card, width: 2),
                      ),
                    ),
                  ),
              ],
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
                // HP dạng trái tim: mỗi tim = 1 ngày bỏ lỡ được phép
                Row(
                  children: [
                    for (int i = 0; i < GameRules.maxHp; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Icon(
                          i < hp ? Icons.favorite : Icons.favorite_border,
                          color: i < hp ? AppColors.hpRed : Colors.grey,
                          size: 16,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.shield,
                      color: shields > 0 ? AppColors.primary : Colors.grey,
                      size: 15,
                    ),
                    Text(
                      " x$shields",
                      style: TextStyle(
                        color: shields > 0
                            ? AppColors.textMain
                            : AppColors.textSub,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
        style: const TextStyle(color: AppColors.textMain),
        decoration: InputDecoration(
          hintText: "Tìm công việc...",
          hintStyle: const TextStyle(color: AppColors.textSub),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSub),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSub),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
          isDense: true,
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.hpRed,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        "$count",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
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
          selectedCategory == 'Tất cả' ||
          (selectedCategory == DatabaseHelper.groupCategoryName
              ? t.isGroupTask
              : t.category == selectedCategory);
      if (!matchCategory) return false;

      if (_searchQuery.isNotEmpty) {
        final inTitle = t.title.toLowerCase().contains(_searchQuery);
        final inDesc = (t.description ?? '').toLowerCase().contains(
          _searchQuery,
        );
        if (!inTitle && !inDesc) return false;
      }

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
              "Không có công việc.",
              style: TextStyle(color: AppColors.textSub, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredTasks.length,
      itemBuilder: (_, index) {
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
            if (task.isDone) return;

            final result = await context
                .read<GamificationViewModel>()
                .completeTask(task, now);
            if (result == null || !mounted) return;
            if (result.onTime) _confettiController.play();

            final hpText = result.hpGained > 0
                ? ' & +${result.hpGained} ❤️'
                : '';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result.onTime
                      ? '🎉 Hoàn thành đúng hạn "${task.title}"! +${result.gold} Vàng$hpText'
                      : '⏰ Hoàn thành trễ "${task.title}". +${result.gold} Vàng (trễ hạn không hồi máu)',
                ),
                backgroundColor: result.onTime ? Colors.green : Colors.orange,
              ),
            );
            setState(() {});
          },
        );
      },
    );
  }
}
