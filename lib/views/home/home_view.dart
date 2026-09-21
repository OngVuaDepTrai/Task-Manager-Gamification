import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/dummy_data.dart';
import '../task/task_form_view.dart'; // Đã import màn hình Thêm/Sửa Task

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // Danh sách các danh mục bộ lọc
  final List<String> categories = ['Tất cả', 'Đại học', 'Cá nhân', 'Thể thao'];
  String selectedCategory = 'Tất cả';

  // Lấy danh sách Task của ngày 21 (Hôm nay) từ file DummyData
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
      // NÚT THÊM TASK MỚI
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          // Bấm vào dấu + sẽ mở Form nhưng không truyền data (Thêm mới)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TaskFormView()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  // KHỐI 1: Thanh trạng thái nhân vật (Gamification)
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
          const CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, color: Colors.white),
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
                // Thanh HP (Máu)
                LinearProgressIndicator(
                  value: 0.8,
                  color: AppColors.hpRed,
                  backgroundColor: Colors.grey[800],
                ),
                const SizedBox(height: 4),
                // Thanh EXP (Kinh nghiệm)
                LinearProgressIndicator(
                  value: 0.4,
                  color: AppColors.primary,
                  backgroundColor: Colors.grey[800],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Chỉ số Streak và Vàng
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

  // KHỐI 2: Lời chào và Ngày tháng hiện tại
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

  // KHỐI 3: Thanh trượt chọn Tab
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

  // KHỐI 4: Vùng Danh sách Công việc
  Widget _buildTaskList() {
    List<Map<String, dynamic>> filteredTasks = selectedCategory == 'Tất cả'
        ? todayTasks
        : todayTasks.where((task) => task['cat'] == selectedCategory).toList();

    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.inbox, size: 50, color: AppColors.textSub),
            SizedBox(height: 10),
            Text(
              "Không có công việc nào trong thư mục này",
              style: TextStyle(color: AppColors.textSub),
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
        // TRUYỀN NGUYÊN OBJECT TASK VÀO HÀM RENDER
        return _buildTaskCard(task);
      },
    );
  }

  // KHỐI 5: Giao diện thẻ chi tiết của 1 Task
  // Lưu ý: Đã đổi tham số truyền vào thành nguyên cái Map task
  Widget _buildTaskCard(Map<String, dynamic> task) {
    return GestureDetector(
      onTap: () {
        // KHI BẤM VÀO THẺ TASK SẼ MỞ FORM Ở CHẾ ĐỘ SỬA
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TaskFormView(task: task)),
        );
      },
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
            // Ô Checkbox tròn
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
                  // Lấy dữ liệu từ object task
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

                      // Khu vực hiển thị phần thưởng (EXP, Vàng)
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
            // Dấu chấm biểu thị mức độ ưu tiên
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
