import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_session.dart';
import '../../core/database_helper.dart';
import '../../models/user_model.dart';

// Bảng xếp hạng chuỗi giữa bạn và bạn bè của bạn
class LeaderboardView extends StatefulWidget {
  const LeaderboardView({super.key});

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {
  List<UserModel> _users = [];
  List<int> _ranks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final me = AppSession.currentUser;
    if (me == null || me.id == null) return;
    final list = await DatabaseHelper.instance.getStreakLeaderboard(me.id!);

    // Cùng số chuỗi thì cùng hạng (VD: 1, 2, 2, 4)
    final ranks = <int>[];
    for (int i = 0; i < list.length; i++) {
      if (i > 0 && list[i].currentStreak == list[i - 1].currentStreak) {
        ranks.add(ranks[i - 1]);
      } else {
        ranks.add(i + 1);
      }
    }

    if (!mounted) return;
    setState(() {
      _users = list;
      _ranks = ranks;
      _isLoading = false;
    });
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return AppColors.gold;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade300;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = AppSession.currentUser?.id;
    final myIndex = _users.indexWhere((u) => u.id == myId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Bảng Xếp Hạng Chuỗi',
          style: TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (myIndex >= 0) _buildMyRankCard(myIndex),
                  const SizedBox(height: 16),
                  ...List.generate(
                    _users.length,
                    (i) => _buildRow(_users[i], _ranks[i], _users[i].id == myId),
                  ),
                  if (_users.length <= 1)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        "Bạn chưa có bạn bè nào.\nVào Bạn bè → Thêm bạn bè để cùng so chuỗi!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSub, height: 1.5),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildMyRankCard(int myIndex) {
    final me = _users[myIndex];
    final rank = _ranks[myIndex];
    final ahead = myIndex > 0 ? _users[myIndex - 1] : null;
    final gap = ahead == null ? 0 : ahead.currentStreak - me.currentStreak;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withAlpha(120)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: AppColors.gold, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bạn đang hạng $rank/${_users.length}",
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rank == 1
                      ? "Bạn đang dẫn đầu, giữ vững chuỗi nhé!"
                      : gap > 0
                      ? "Cần thêm $gap ngày để vượt ${ahead!.name}"
                      : "Đang bằng chuỗi với ${ahead!.name}",
                  style: const TextStyle(color: AppColors.textSub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(UserModel user, int rank, bool isMe) {
    final color = _rankColor(rank);
    final hasMedal = color != Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withAlpha(20) : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe
              ? AppColors.primary
              : (hasMedal ? color : Colors.grey.shade800),
          width: isMe ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              "#$rank",
              style: TextStyle(
                color: hasMedal ? color : AppColors.textSub,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: hasMedal ? color : AppColors.primary,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : "?",
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? "${user.name} (Bạn)" : user.name,
                  style: TextStyle(
                    color: isMe ? AppColors.primary : AppColors.textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Kỷ lục: ${user.longestStreak} ngày",
                  style: const TextStyle(color: AppColors.textSub, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            "${user.currentStreak}",
            style: TextStyle(
              color: user.currentStreak > 0 ? Colors.orange : Colors.grey,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.local_fire_department,
            color: user.currentStreak > 0 ? Colors.orange : Colors.grey,
            size: 20,
          ),
        ],
      ),
    );
  }
}
