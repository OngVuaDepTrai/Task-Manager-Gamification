import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class TaskFormView extends StatefulWidget {
  final Map<String, dynamic>? task;

  const TaskFormView({super.key, this.task});

  @override
  State<TaskFormView> createState() => _TaskFormViewState();
}

class _TaskFormViewState extends State<TaskFormView> {
  late TextEditingController _titleController;
  bool _isHighPriority = false;

  // Các biến lưu trạng thái trên UI
  String _selectedDate = "Hôm nay";
  String _selectedTime = "18:00";
  String _selectedCategory = "Đại học";

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?['title'] ?? '');
    _isHighPriority = widget.task?['high'] ?? false;

    // Nếu là sửa thì lấy dữ liệu cũ, không thì lấy mặc định
    if (widget.task != null) {
      _selectedCategory = widget.task?['cat'] ?? "Đại học";
      // Giả lập cắt chuỗi "14:00" từ data cũ
      _selectedTime = widget.task?['time'] ?? "18:00";
    }
  }

  // --- HÀM CHỌN NGÀY ---
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: AppColors.card,
              onSurface: AppColors.textMain,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  // --- HÀM CHỌN GIỜ ---
  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: AppColors.card,
              onSurface: AppColors.textMain,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        // Định dạng 2 chữ số (VD: 09:05)
        String hour = picked.hour.toString().padLeft(2, '0');
        String minute = picked.minute.toString().padLeft(2, '0');
        _selectedTime = "$hour:$minute";
      });
    }
  }

  // --- HÀM CHỌN DANH MỤC ---
  void _showCategoryPicker() {
    // Danh sách giả lập (Tuần 9 sẽ lấy từ Database)
    List<String> categories = ['Đại học', 'Cá nhân', 'Thể thao', 'Gia đình'];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Chọn Danh mục",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  // Nút Quản lý để Thêm/Sửa/Xóa (Sẽ làm ở Tuần 9)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Tính năng Quản lý danh mục sẽ làm ở Tuần 9!",
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "Quản lý",
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        categories[index],
                        style: const TextStyle(color: AppColors.textMain),
                      ),
                      trailing: _selectedCategory == categories[index]
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedCategory = categories[index];
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEditMode = widget.task != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          isEditMode ? "Sửa công việc" : "Thêm công việc mới",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isEditMode)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.hpRed,
                size: 28,
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Giả lập: Đã xóa công việc! (Tuần 9 sẽ xóa thật vào DB)",
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: "Bạn cần làm gì?",
                hintStyle: TextStyle(color: AppColors.textSub, fontSize: 24),
                border: InputBorder.none,
              ),
            ),
            const Divider(color: Colors.white24),
            const SizedBox(height: 20),

            // ĐÃ GẮN SỰ KIỆN ONTAP VÀO CÁC NÚT NÀY
            _buildActionRow(
              Icons.calendar_month,
              "Ngày đến hạn",
              _selectedDate,
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            _buildActionRow(
              Icons.access_time,
              "Giờ thông báo",
              _selectedTime,
              onTap: _pickTime,
            ),
            const SizedBox(height: 12),
            _buildActionRow(
              Icons.folder,
              "Danh mục",
              _selectedCategory,
              onTap: _showCategoryPicker,
            ),
            const SizedBox(height: 12),
            _buildActionRow(
              Icons.location_on,
              "Nhắc nhở GPS",
              "Chọn vị trí...",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Bản đồ GPS sẽ được tích hợp ở Tuần 10!"),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // NÚT BẬT/TẮT ƯU TIÊN
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flag, color: AppColors.textSub),
                  const SizedBox(width: 16),
                  const Text(
                    "Ưu tiên cao (Màu đỏ)",
                    style: TextStyle(color: AppColors.textMain, fontSize: 16),
                  ),
                  const Spacer(),
                  Switch(
                    value: _isHighPriority,
                    activeColor: AppColors.hpRed,
                    onChanged: (val) => setState(() => _isHighPriority = val),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // NÚT LƯU
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  if (_titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Vui lòng nhập tên công việc!"),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Giả lập: Lưu thành công! (Dữ liệu sẽ lưu thật vào DB ở Tuần 9)",
                      ),
                    ),
                  );
                },
                child: const Text(
                  "LƯU CÔNG VIỆC",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Khối giao diện các nút thiết lập (Đã thêm onTap để bấm được)
  Widget _buildActionRow(
    IconData icon,
    String title,
    String value, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap, // Bấm vào sẽ gọi hàm tương ứng
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSub),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(color: AppColors.textSub, fontSize: 16),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSub),
          ],
        ),
      ),
    );
  }
}
