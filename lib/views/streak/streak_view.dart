import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_session.dart';

class StreakView extends StatelessWidget {
  const StreakView({super.key});

  @override
  Widget build(BuildContext context) {
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCurrentStreakCard(),
              const SizedBox(height: 20),

              const Text(
                "Hoạt động tuần này",
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildWeekActivity(),

              const SizedBox(height: 24),

              const Text(
                "Thống kê",
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildStatistics(),

              const SizedBox(height: 24),

              const Text(
                "Bảo vệ chuỗi",
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildStreakProtectionCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStreakCard() {
    final user = AppSession.currentUser;
    final int currentStreak = user?.currentStreak ?? 0;
    final int longestStreak = user?.longestStreak ?? 0;
    final int exp = user?.exp ?? 0;
    final int completedTasks =
        exp ~/ 20; // Mô phỏng số task đã làm dựa trên EXP (20 điểm/task)

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
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.orange,
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

          const Text(
            "Chuỗi hiện tại",
            style: TextStyle(color: AppColors.textSub, fontSize: 15),
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
                  title: "$completedTasks",
                  subtitle: "Task hoàn thành",
                ),
              ),

              Container(width: 1, height: 48, color: Colors.white12),

              Expanded(
                child: _buildSmallInfo(
                  icon: Icons.bolt,
                  iconColor: Colors.orange,
                  title: "+$exp",
                  subtitle: "Tổng EXP",
                ),
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
    final user = AppSession.currentUser;
    final int streak = user?.currentStreak ?? 0;

    // Dựa vào chuỗi hiện tại để "thắp sáng" ngọn lửa tuần lùi lại. Account trắng (streak = 0) sẽ không có lửa.
    final List<Map<String, dynamic>> days = [
      {"day": "T2", "date": "21", "done": streak >= 5},
      {"day": "T3", "date": "22", "done": streak >= 4},
      {"day": "T4", "date": "23", "done": streak >= 3},
      {"day": "T5", "date": "24", "done": streak >= 2},
      {"day": "T6", "date": "25", "done": streak >= 1},
      {"day": "T7", "date": "26", "done": false},
      {"day": "CN", "date": "27", "done": false},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days.map((item) {
          bool isDone = item["done"];

          return Column(
            children: [
              Text(
                item["day"],
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
                  color: isDone
                      ? Colors.orange.withAlpha(45)
                      : AppColors.background,
                  border: Border.all(
                    color: isDone ? Colors.orange : Colors.grey.shade800,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(
                          Icons.local_fire_department,
                          color: Colors.orange,
                          size: 22,
                        )
                      : Text(
                          item["date"],
                          style: const TextStyle(
                            color: AppColors.textSub,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatistics() {
    final user = AppSession.currentUser;
    final int exp = user?.exp ?? 0;
    final int gold = user?.gold ?? 0;

    // Logic tính toán: Trung bình 1 Task 20 EXP
    final int completedTasks = exp ~/ 20;
    final int missedTasks = (user?.currentStreak == 0 && exp > 0)
        ? 2
        : 0; // Tài khoản mới mặc định 0 bỏ lỡ

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatisticCard(
                icon: Icons.task_alt,
                iconColor: AppColors.primary,
                value: "$completedTasks",
                title: "Đã hoàn thành",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatisticCard(
                icon: Icons.cancel_outlined,
                iconColor: AppColors.hpRed,
                value: "$missedTasks",
                title: "Bỏ lỡ",
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
                title: "Vàng kiếm được",
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

  Widget _buildStreakProtectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(70)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withAlpha(35),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.primary,
              size: 30,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Khiên bảo vệ chuỗi",
                  style: TextStyle(
                    color: AppColors.textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Bạn đang có 1 khiên. Khiên giúp giữ chuỗi khi bỏ lỡ một ngày.",
                  style: TextStyle(
                    color: AppColors.textSub,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "x1",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
