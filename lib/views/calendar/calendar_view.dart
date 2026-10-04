import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/dummy_data.dart'; // IMPORT FILE DỮ LIỆU

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  String viewMode = 'Tháng';
  int selectedDay = 21;
  int currentMonth = 9; // Tháng hiện tại

  // Chuyển tháng
  void _changeMonth(int increment) {
    setState(() {
      currentMonth += increment;
      if (currentMonth > 12) currentMonth = 1;
      if (currentMonth < 1) currentMonth = 12;
      selectedDay = 1; // Chọn về ngày mùng 1 của tháng mới
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "Lịch Công Việc",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildViewModeTabs(),
          const SizedBox(height: 20),

          if (viewMode != 'Ngày')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Tháng $currentMonth, 2026",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: AppColors.primary,
                          size: 30,
                        ),
                        onPressed: () => _changeMonth(-1),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: AppColors.primary,
                          size: 30,
                        ),
                        onPressed: () => _changeMonth(1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          if (viewMode == 'Tháng')
            _buildMonthGrid()
          else if (viewMode == 'Tuần')
            _buildWeekRow(),

          const SizedBox(height: 10),
          Divider(color: Colors.grey[800], thickness: 1),
          const SizedBox(height: 10),

          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              viewMode == 'Ngày'
                  ? "Hôm nay, 21 Tháng 9"
                  : "Công việc ngày $selectedDay/$currentMonth",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(child: _buildTaskList()),
        ],
      ),
    );
  }

  // 1. Tab Chọn Chế Độ (Ngày / Tuần / Tháng)
  Widget _buildViewModeTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ['Ngày', 'Tuần', 'Tháng'].map((mode) {
        bool isSelected = viewMode == mode;
        return GestureDetector(
          onTap: () => setState(() => viewMode = mode),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              mode,
              style: TextStyle(
                color: isSelected ? Colors.black : AppColors.textMain,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 2. Lịch Tháng (Sổ cả tháng)
  Widget _buildMonthGrid() {
    const daysOfWeek = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: daysOfWeek
                .map(
                  (d) => Text(
                    d,
                    style: const TextStyle(
                      color: AppColors.textSub,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 250,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 31,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                int day = index + 1;
                return _buildDayCell(day);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 3. Lịch Tuần (Chỉ hiển thị 1 dòng ngang)
  Widget _buildWeekRow() {
    const daysOfWeek = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    List<int> weekDays = [21, 22, 23, 24, 25, 26, 27]; // Tuần giả lập

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: daysOfWeek
                .map(
                  (d) => Text(
                    d,
                    style: const TextStyle(
                      color: AppColors.textSub,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays
                .map(
                  (day) => SizedBox(
                    width: 40,
                    height: 40,
                    child: _buildDayCell(day),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // Giao diện 1 ô Ngày (Dùng chung cho Tuần và Tháng)
  Widget _buildDayCell(int day) {
    bool isSelected = day == selectedDay;
    bool hasTask = currentMonth == 9 && DummyData.getTasksByDay(day).isNotEmpty;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDay = day;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          // Dùng withAlpha(50) thay vì withOpacity(0.2) để fix lỗi cảnh báo của Flutter
          color: isSelected
              ? AppColors.primary.withAlpha(50)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$day",
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textMain,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (hasTask)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.hpRed,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 4. Danh sách công việc động dựa vào ngày được chọn
  Widget _buildTaskList() {
    List<Map<String, dynamic>> tasksForSelectedDay = currentMonth == 9
        ? DummyData.getTasksByDay(selectedDay)
        : [];

    if (tasksForSelectedDay.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.inbox, size: 50, color: AppColors.textSub),
            SizedBox(height: 10),
            Text(
              "Không có công việc nào",
              style: TextStyle(color: AppColors.textSub),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tasksForSelectedDay.length,
      itemBuilder: (context, index) {
        var task = tasksForSelectedDay[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[850]!),
          ),
          child: Row(
            children: [
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
                    Text(
                      task['title'],
                      style: const TextStyle(
                        color: AppColors.textMain,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      task['time'],
                      style: const TextStyle(
                        color: AppColors.textSub,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
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
        );
      },
    );
  }
}
