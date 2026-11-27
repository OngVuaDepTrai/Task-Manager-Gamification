import 'package:provider/provider.dart';

import '../../view_models/gamification_view_model.dart';
import '../../services/game_store.dart';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_session.dart';

class StreakView extends StatelessWidget {
  const StreakView({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GamificationViewModel>();
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
              _buildCurrentStreakCard(game),
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

              _buildWeekActivity(game),

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

              _buildStatistics(game),

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

  Widget _buildCurrentStreakCard(GamificationViewModel game) {
    final user = AppSession.currentUser;
    final int currentStreak = user?.currentStreak ?? 0;
    final int longestStreak = user?.longestStreak ?? 0;
    final int exp = user?.exp ?? 0;
    final int completedTasks = game.events
        .where((e) => e['kind'] == 'complete')
        .length;
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

  Widget _buildWeekActivity(GamificationViewModel game) {
    final now = DateTime.now();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(7, (i) {
        final d = DateTime(now.year, now.month, now.day - now.weekday + 1 + i),
            key = GameStore.date(d);
        final kinds = game.events
            .where((e) => e['day'] == key)
            .map((e) => e['kind']);
        final (icon, label, color) = kinds.contains('complete')
            ? (Icons.local_fire_department, 'Hoàn thành', Colors.orange)
            : kinds.contains('freeze')
            ? (Icons.shield, 'Được bảo vệ', Colors.blue)
            : key.compareTo(game.today) < 0
            ? (Icons.close, 'Bỏ lỡ', Colors.redAccent)
            : key == game.today
            ? (Icons.today, 'Hôm nay · Chưa hoàn thành', Colors.amber)
            : (Icons.schedule, 'Ngày chưa diễn ra', Colors.grey);
        return Tooltip(
          message: '$key · $label',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${d.day}/${d.month}'),
              Icon(icon, color: color),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatistics(GamificationViewModel game) {
    final now = DateTime.now(),
        week = GameStore.date(
          DateTime(now.year, now.month, now.day - now.weekday + 1),
        );
    final month = GameStore.date(DateTime(now.year, now.month, 1));
    int sum(String key, String kind) => game.events
        .where((e) => e['kind'] == kind)
        .fold(0, (n, e) => n + (e[key] as int));
    final rate = game.total == 0 ? 0.0 : game.done / game.total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Công việc hiện có (tính từng ngày lặp): ${game.total}'),
            Text(
              'Đã xong: ${game.done} · Chưa xong: ${game.total - game.done} · Quá hạn: ${game.overdue}',
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: rate),
            Text('Tỷ lệ hoàn thành: ${(rate * 100).round()}%'),
            const Divider(),
            Text(
              'Lượt hoàn thành tuần này: ${game.completedSince(week)} · Tháng này: ${game.completedSince(month)}',
            ),
            Text('Tổng EXP: ${AppSession.currentUser!.exp}'),
            Text(
              "Vàng kiếm: ${sum('gold', 'complete')} · Vàng tiêu: ${-sum('gold', 'purchase')} · HP mất: ${-sum('hp', 'penalty')}",
            ),
            ExpansionTile(
              title: const Text('Lịch sử hoạt động'),
              children: [
                if (game.events.isEmpty) const Text('Chưa có hoạt động'),
                for (final e in game.events)
                  ListTile(
                    title: Text(e['title'] as String),
                    subtitle: Text(
                      "${e['day'] ?? 'Chưa lưu ngày'} · ${const {'complete': 'Hoàn thành', 'freeze': 'Dùng khiên', 'purchase': 'Đổi thưởng', 'penalty': 'Quá hạn'}[e['kind']]}",
                    ),
                  ),
              ],
            ),
          ],
        ),
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

          Expanded(
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
                  "Bạn đang có ${AppSession.currentUser!.freezes} khiên. Khiên giúp giữ chuỗi khi bỏ lỡ một ngày.",
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
            child: Text(
              "x${AppSession.currentUser!.freezes}",
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
