// lib/models/dummy_data.dart

class DummyData {
  // Dữ liệu chung, dùng cho cả Home và Calendar
  static final List<Map<String, dynamic>> allTasks = [
    {
      "id": 1,
      "day": 21,
      "title": "Thiết kế UI đồ án",
      "time": "14:00",
      "cat": "Đại học",
      "high": true,
      "exp": 20,
      "gold": 10,
    },
    {
      "id": 2,
      "day": 21,
      "title": "Làm bài tập HĐH",
      "time": "15:00",
      "cat": "Đại học",
      "high": false,
      "exp": 10,
      "gold": 5,
    },
    {
      "id": 3,
      "day": 21,
      "title": "Tập cầu lông",
      "time": "17:30",
      "cat": "Thể thao",
      "high": false,
      "exp": 15,
      "gold": 5,
    },
    {
      "id": 4,
      "day": 22,
      "title": "Họp nhóm đồ án",
      "time": "20:00",
      "cat": "Đại học",
      "high": true,
      "exp": 15,
      "gold": 10,
    },
    {
      "id": 5,
      "day": 25,
      "title": "Báo cáo tiến độ",
      "time": "09:00",
      "cat": "Đại học",
      "high": true,
      "exp": 30,
      "gold": 20,
    },
  ];

  // Hàm lọc Task theo ngày
  static List<Map<String, dynamic>> getTasksByDay(int day) {
    return allTasks.where((task) => task['day'] == day).toList();
  }
}
