import 'package:provider/provider.dart';

import '../../view_models/gamification_view_model.dart';
import '../../core/app_session.dart';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class LeaderboardView extends StatelessWidget {
  const LeaderboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final leaders = context.watch<GamificationViewModel>().ranking;
    final friends = <Map<String, dynamic>>[
      for (var i = 0; i < leaders.length; i++)
        {
          'rank': i + 1,
          'me': leaders[i]['id'] == AppSession.currentUser?.id,
          'name': leaders[i]['name'],
          'streak': leaders[i]['currentStreak'],
          'color': i == 0 ? AppColors.gold : Colors.transparent,
        },
    ];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Xếp hạng bạn bè · Cục bộ',
          style: TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: friends.length,
        itemBuilder: (context, index) {
          var friend = friends[index];
          bool isMe = friend["me"] == true;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary.withAlpha(20) : AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: friend["color"] != Colors.transparent
                    ? friend["color"]
                    : Colors.grey.shade800,
                width: isMe ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  "#${friend["rank"]}",
                  style: TextStyle(
                    color: friend["color"] != Colors.transparent
                        ? friend["color"]
                        : AppColors.textSub,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    friend["name"][0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "${friend['name']}${isMe ? ' (Bạn)' : ''}",
                    style: TextStyle(
                      color: isMe ? AppColors.primary : AppColors.textMain,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "${friend["streak"]}",
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
