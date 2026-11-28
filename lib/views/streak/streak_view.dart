import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_session.dart';
import '../../core/database_helper.dart';
import '../../core/game_rules.dart';
import '../../view_models/gamification_view_model.dart';

// Trạng thái 1 ngày trong tuần
enum _DayStatus { done, missed, empty, pending, future }

class StreakView extends StatefulWidget {
  const StreakView({super.key});

  @override
  State<StreakView> createState() => _StreakViewState();
}

class _StreakViewState extends State<StreakView> {
  bool _isLoading = true;
  int _completedCount = 0;
  int _overdueCount = 0;
  List<_DayStatus> _weekStatus = List.filled(7, _DayStatus.future);
  List<DateTime> _weekDays = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = AppSession.currentUser;
    if (user == null || user.id == null) {
      setState(() => _isLoading = false);
      return;
    }
    final db = DatabaseHelper.instance;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = DateTime(today.year, today.month, today.day - (today.weekday - 1));

    final days = List.generate(
      7,
      (i) => DateTime(monday.year, monday.month, monday.day + i),
    );
    final statuses = <_DayStatus>[];
    for (final d in days) {
      if (d.isAfter(today)) {
        statuses.add(_DayStatus.future);
        continue;
      }
      final tasks = await db.getTasksForDate(user.id!, d.day, d.month, d.year);
      if (tasks.isEmpty) {
        statuses.add(_DayStatus.empty);
      } else if (tasks.any((t) => t.isDone)) {
        statuses.add(_DayStatus.done);
      } else if (d == today) {
        statuses.add(_DayStatus.pending);
      } else {
        statuses.add(_DayStatus.missed);
      }
    }

    final completed = await db.countCompletedTasks(user.id!);
    final allTasks = await db.getTasks(user.id!);
    final overdue = allTasks.where((t) => t.isOverdue(now)).length;

    if (!mounted) return;
    setState(() {
      _weekDays = days;
      _weekStatus = statuses;
      _completedCount = completed;
      _overdueCount = overdue;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<GamificationViewModel>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Chuỗi hoạt động",
          style: TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : RefreshIndicator(
                onRefresh: _loadStats,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCurrentStreakCard(),
                      const SizedBox(height: 16),
                      _buildHpShieldCard(),
                      const SizedBox(height: 20),
                      _sectionTitle("Hoạt động tuần này"),
                      _buildWeekActivity(),
                      const SizedBox(height: 24),
                      _sectionTitle("Thống kê"),
                      _buildStatistics(),
                      const SizedBox(height: 24),
                      _sectionTitle("Luật chơi"),
                      _buildRulesCard(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.textMain,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _buildCurrentStreakCard() {
    final user = AppSession.currentUser;
    final int currentStreak = user?.currentStreak ?? 0;
    final int longestStreak = user?.longestStreak ?? 0;
    final bool todayDone = _statusOfToday() == _DayStatus.done;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withAlpha(90)),
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.withAlpha(35),
            ),
            child: Icon(
              Icons.local_fire_department,
              color: currentStreak > 0 ? Colors.orange : Colors.grey,
              size: 58,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "$currentStreak ngày",
            style: const TextStyle(
              color: AppColors.textMain,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            todayDone
                ? "Hôm nay đã giữ chuỗi ✅ (+1 khi qua ngày mới)"
                : "Hoàn thành 1 nhắc nhở hôm nay để giữ chuỗi",
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSub, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSmallInfo(
                  icon: Icons.emoji_events_outlined,
                  iconColor: AppColors.gold,
                  title: "$longestStreak ngày",
                  subtitle: "Kỷ lục",
                ),
              ),
              Container(width: 1, height: 48, color: Colors.white12),
              Expanded(
                child: _buildSmallInfo(
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.primary,
                  title: "$_completedCount",
                  subtitle: "Lần hoàn thành",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _DayStatus? _statusOfToday() {
    final now = DateTime.now();
    for (int i = 0; i < _weekDays.length; i++) {
      final d = _weekDays[i];
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        return _weekStatus[i];
      }
    }
    return null;
  }

  Widget _buildHpShieldCard() {
    final user = AppSession.currentUser;
    final int hp = user?.hp ?? GameRules.maxHp;
    final int shields = user?.shields ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Máu",
                  style: TextStyle(color: AppColors.textSub, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (int i = 0; i < GameRules.maxHp; i++)
                      Icon(
                        i < hp ? Icons.favorite : Icons.favorite_border,
                        color: i < hp ? AppColors.hpRed : Colors.grey,
                        size: 26,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Còn được bỏ lỡ $hp ngày trước khi mất chuỗi",
                  style: const TextStyle(color: AppColors.textSub, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 70, color: Colors.white12),
          const SizedBox(width: 16),
          Column(
            children: [
              Icon(
                Icons.shield,
                color: shields > 0 ? AppColors.primary : Colors.grey,
                size: 34,
              ),
              const SizedBox(height: 4),
              Text(
                "$shields/${GameRules.maxShields}",
                style: const TextStyle(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text(
                "Khiên",
                style: TextStyle(color: AppColors.textSub, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInfo({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSub, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildWeekActivity() {
    const labels = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final status = _weekStatus[i];
              final date = _weekDays.isNotEmpty ? _weekDays[i].day : 0;

              Color color;
              Widget inner;
              switch (status) {
                case _DayStatus.done:
                  color = Colors.orange;
                  inner = const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 22,
                  );
                  break;
                case _DayStatus.missed:
                  color = AppColors.hpRed;
                  inner = const Icon(
                    Icons.close,
                    color: AppColors.hpRed,
                    size: 20,
                  );
                  break;
                default:
                  color = status == _DayStatus.pending
                      ? AppColors.primary
                      : Colors.grey.shade800;
                  inner = Text(
                    "$date",
                    style: const TextStyle(
                      color: AppColors.textSub,
                      fontSize: 13,
                    ),
                  );
              }

              return Column(
                children: [
                  Text(
                    labels[i],
                    style: const TextStyle(
                      color: AppColors.textSub,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withAlpha(
                        status == _DayStatus.done ||
                                status == _DayStatus.missed
                            ? 45
                            : 0,
                      ),
                      border: Border.all(color: color),
                    ),
                    child: Center(child: inner),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
          const Text(
            "🔥 hoàn thành · ✖ bỏ lỡ · ô trống: không có nhắc nhở",
            style: TextStyle(color: AppColors.textSub, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final user = AppSession.currentUser;
    final int exp = user?.exp ?? 0;
    final int gold = user?.gold ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatisticCard(
                icon: Icons.task_alt,
                iconColor: AppColors.primary,
                value: "$_completedCount",
                title: "Đã hoàn thành",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatisticCard(
                icon: Icons.cancel_outlined,
                iconColor: AppColors.hpRed,
                value: "$_overdueCount",
                title: "Đang quá hạn",
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatisticCard(
                icon: Icons.bolt,
                iconColor: Colors.orange,
                value: "$exp",
                title: "EXP nhận được",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatisticCard(
                icon: Icons.monetization_on,
                iconColor: AppColors.gold,
                value: "$gold",
                title: "Vàng hiện có",
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textMain,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: AppColors.textSub, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesCard() {
    const rules = [
      "✅ Hoàn thành đúng hạn: +${GameRules.goldOnTime} vàng, +1 ❤️",
      "⏰ Hoàn thành trễ: +${GameRules.goldLate} vàng, không hồi máu",
      "🔥 Ngày có nhắc nhở và làm xong ≥ 1 việc: chuỗi +1",
      "😴 Ngày không có nhắc nhở: không thay đổi gì",
      "🛡️ Ngày bỏ lỡ hết: tự dùng 1 khiên nếu có, nếu không thì -1 ❤️",
      "💔 Hết máu: chuỗi về 0, máu hồi đầy",
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in rules)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                r,
                style: const TextStyle(
                  color: AppColors.textSub,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
