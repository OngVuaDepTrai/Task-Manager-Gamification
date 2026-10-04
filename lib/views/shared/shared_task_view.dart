import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class SharedTaskView extends StatelessWidget {
  const SharedTaskView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> sharedTasks = [
      {"title": "Vẽ UML Diagram", "assignee": "Minh Nhật", "done": true},
      {
        "title": "Làm giao diện Flutter",
        "assignee": "Thanh Tài",
        "done": false,
      },
      {"title": "Code Database SQLite", "assignee": "Tấn Thành", "done": false},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Nhóm Đồ Án Quản Lý',
          style: TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person_add, color: AppColors.primary),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Khu vực thành viên
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Thành viên (3)",
                  style: TextStyle(color: AppColors.textSub, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // ĐÃ SỬA LỖI ĐƠ APP: Dùng Stack thay vì SizedBox âm
                    SizedBox(
                      width: 110,
                      height: 40,
                      child: Stack(
                        children: const [
                          Positioned(
                            left: 0,
                            child: CircleAvatar(
                              backgroundColor: Colors.blueAccent,
                              child: Text(
                                "N",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 25,
                            child: CircleAvatar(
                              backgroundColor: AppColors.hpRed,
                              child: Text(
                                "T",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 50,
                            child: CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Text(
                                "T",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.share,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      label: const Text(
                        "Mời thêm",
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          // Danh sách công việc chung
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sharedTasks.length,
              itemBuilder: (context, index) {
                var task = sharedTasks[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        task["done"]
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: task["done"] ? Colors.green : AppColors.textSub,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task["title"],
                              style: TextStyle(
                                color: task["done"]
                                    ? AppColors.textSub
                                    : AppColors.textMain,
                                fontSize: 16,
                                decoration: task["done"]
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Phụ trách: ${task["assignee"]}",
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () {},
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          "Giao việc",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
