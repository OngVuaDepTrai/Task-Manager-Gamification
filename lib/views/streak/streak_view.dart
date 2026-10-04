import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

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
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Thông tin Chuỗi sẽ được kết nối dữ liệu thật sau!",
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.info_outline,
              color: AppColors.textSub,
            ),
          ),
        ],
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

  // =========================
  // CARD CHUỖI HIỆN TẠI
  // =========================
  Widget _buildCurrentStreakCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withAlpha(90),
        ),
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

          const Text(
            "15 ngày",
            style: TextStyle(
              color: AppColors.textMain,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            "Chuỗi hiện tại",
            style: TextStyle(
              color: AppColors.textSub,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildSmallInfo(
                  icon: Icons.emoji_events_outlined,
                  iconColor: AppColors.gold,
                  title: "21 ngày",
                  subtitle: "Kỷ lục",
                ),
              ),

              Container(
                width: 1,
                height: 48,
                color: Colors.white12,
              ),

              Expanded(
                child: _buildSmallInfo(
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.primary,
                  title: "18",
                  subtitle: "Task hoàn thành",
                ),
              ),

              Container(
                width: 1,
                height: 48,
                color: Colors.white12,
              ),

              Expanded(
                child: _buildSmallInfo(
                  icon: Icons.bolt,
                  iconColor: Colors.orange,
                  title: "+180",
                  subtitle: "EXP tuần",
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
        Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
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
          style: const TextStyle(
            color: AppColors.textSub,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // =========================
  // HOẠT ĐỘNG TRONG TUẦN
  // =========================
  Widget _buildWeekActivity() {
    final List<Map<String, dynamic>> days = [
      {
        "day": "T2",
        "date": "21",
        "done": true,
      },
      {
        "day": "T3",
        "date": "22",
        "done": true,
      },
      {
        "day": "T4",
        "date": "23",
        "done": true,
      },
      {
        "day": "T5",
        "date": "24",
        "done": true,
      },
      {
        "day": "T6",
        "date": "25",
        "done": true,
      },
      {
        "day": "T7",
        "date": "26",
        "done": false,
      },
      {
        "day": "CN",
        "date": "27",
        "done": false,
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 18,
      ),
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
                    color: isDone
                        ? Colors.orange
                        : Colors.grey.shade800,
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

  // =========================
  // THỐNG KÊ
  // =========================
  Widget _buildStatistics() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatisticCard(
                icon: Icons.task_alt,
                iconColor: AppColors.primary,
                value: "18",
                title: "Đã hoàn thành",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatisticCard(
                icon: Icons.cancel_outlined,
                iconColor: AppColors.hpRed,
                value: "2",
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
                value: "180",
                title: "EXP nhận được",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatisticCard(
                icon: Icons.monetization_on,
                iconColor: AppColors.gold,
                value: "95",
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
          Icon(
            icon,
            color: iconColor,
            size: 28,
          ),
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
            style: const TextStyle(
              color: AppColors.textSub,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // BẢO VỆ CHUỖI
  // =========================
  Widget _buildStreakProtectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withAlpha(70),
        ),
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
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
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