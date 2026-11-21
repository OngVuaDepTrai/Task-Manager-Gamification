import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_session.dart';
import '../../core/database_helper.dart';
import '../../models/task_model.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

enum _DayDotType { none, yellowDailyOnly, redNormalTask }

class _CalendarViewState extends State<CalendarView> {
  String viewMode = 'Tháng';
  int selectedDay = 1;
  int currentMonth = 1;
  int currentYear = 2026;

  List<TaskModel> allStoredTasks = [];
  List<TaskModel> tasksForSelectedDay = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedDay = now.day;
    currentMonth = now.month;
    currentYear = now.year;

    _loadTasks();
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  Future<void> _loadTasks() async {
    final user = AppSession.currentUser;
    if (user != null && user.id != null) {
      final maxDay = _daysInMonth(currentYear, currentMonth);
      if (selectedDay > maxDay) {
        selectedDay = maxDay;
      }

      final stored = await DatabaseHelper.instance.getTasks(user.id!);
      final dayTasks = await DatabaseHelper.instance.getTasksForDate(
        user.id!,
        selectedDay,
        currentMonth,
        currentYear,
      );

      if (!mounted) return;
      setState(() {
        allStoredTasks = stored;
        tasksForSelectedDay = dayTasks;
        isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _selectDay(int day) async {
    setState(() => selectedDay = day);
    final user = AppSession.currentUser;
    if (user != null && user.id != null) {
      final dayTasks = await DatabaseHelper.instance.getTasksForDate(
        user.id!,
        day,
        currentMonth,
        currentYear,
      );
      if (!mounted) return;
      setState(() => tasksForSelectedDay = dayTasks);
    }
  }

  void _changeMonth(int increment) {
    setState(() {
      currentMonth += increment;
      if (currentMonth > 12) {
        currentMonth = 1;
        currentYear++;
      } else if (currentMonth < 1) {
        currentMonth = 12;
        currentYear--;
      }
      selectedDay = 1;
      isLoading = true;
    });
    _loadTasks();
  }

  /// Quy tắc dấu chấm trên lịch:
  /// - Có task bình thường (không phải Hàng ngày) -> Chấm ĐỎ
  /// - Không có task bình thường nhưng có task Hàng ngày -> Chấm VÀNG
  /// - Không có task nào -> Không có chấm
  _DayDotType _getDotTypeForDay(int day) {
    final hasNormalTaskOnDay = allStoredTasks.any(
      (t) =>
          !t.isDaily &&
          t.day == day &&
          t.month == currentMonth &&
          t.year == currentYear,
    );
    if (hasNormalTaskOnDay) {
      return _DayDotType.redNormalTask;
    }

    final hasDailyTask = allStoredTasks.any((t) => t.isDaily);
    if (hasDailyTask) {
      return _DayDotType.yellowDailyOnly;
    }

    return _DayDotType.none;
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
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                _buildViewModeTabs(),
                const SizedBox(height: 12),
                _buildLegend(),
                const SizedBox(height: 12),
                if (viewMode != 'Ngày')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Tháng $currentMonth, $currentYear",
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
                const SizedBox(height: 12),
                if (viewMode == 'Tháng')
                  _buildMonthGrid()
                else if (viewMode == 'Tuần')
                  _buildWeekRow(),
                const SizedBox(height: 8),
                Divider(color: Colors.grey[800], thickness: 1),
                const SizedBox(height: 8),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Công việc ngày $selectedDay/$currentMonth/$currentYear",
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

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.hpRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            "Việc theo ngày",
            style: TextStyle(color: AppColors.textSub, fontSize: 12),
          ),
          const SizedBox(width: 18),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            "Chỉ có việc Hàng ngày",
            style: TextStyle(color: AppColors.textSub, fontSize: 12),
          ),
        ],
      ),
    );
  }

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

  Widget _buildMonthGrid() {
    const daysOfWeek = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final totalDays = _daysInMonth(currentYear, currentMonth);
    final firstWeekdayOffset =
        DateTime(currentYear, currentMonth, 1).weekday - 1;

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
            height: 245,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalDays + firstWeekdayOffset,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                if (index < firstWeekdayOffset) {
                  return const SizedBox.shrink();
                }
                final day = index - firstWeekdayOffset + 1;
                return _buildDayCell(day);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekRow() {
    const daysOfWeek = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final maxDay = _daysInMonth(currentYear, currentMonth);
    List<int> weekDays = [];
    int startDay = selectedDay - 3;
    if (startDay < 1) startDay = 1;
    for (int i = 0; i < 7; i++) {
      int d = startDay + i;
      if (d > maxDay) d = maxDay;
      if (!weekDays.contains(d)) {
        weekDays.add(d);
      }
    }

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

  Widget _buildDayCell(int day) {
    bool isSelected = day == selectedDay;
    final dotType = _getDotTypeForDay(day);

    Color? dotColor;
    if (dotType == _DayDotType.redNormalTask) {
      dotColor = AppColors.hpRed;
    } else if (dotType == _DayDotType.yellowDailyOnly) {
      dotColor = AppColors.gold;
    }

    return GestureDetector(
      onTap: () => _selectDay(day),
      child: Container(
        decoration: BoxDecoration(
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
            if (dotColor != null)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList() {
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
                  border: Border.all(
                    color: task.isDone ? Colors.green : AppColors.textSub,
                    width: 2,
                  ),
                  color: task.isDone ? Colors.green : Colors.transparent,
                ),
                child: task.isDone
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              color: task.isDone
                                  ? AppColors.textSub
                                  : AppColors.textMain,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: task.isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                        if (task.isDaily)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withAlpha(35),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "Hàng ngày",
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Nhắc lúc ${task.time} • ${task.category}",
                      style: const TextStyle(
                        color: AppColors.textSub,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (task.isHighPriority)
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
