import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/app_colors.dart';
import '../../core/app_session.dart';
import '../../core/database_helper.dart';
import '../../models/task_model.dart';
import '../../services/notification_service.dart';

class TaskFormView extends StatefulWidget {
  final TaskModel? task;
  const TaskFormView({super.key, this.task});

  @override
  State<TaskFormView> createState() => _TaskFormViewState();
}

class _TaskFormViewState extends State<TaskFormView> {
  late TextEditingController _titleController;
  bool _isHighPriority = false;
  bool _isDaily = false;
  bool _reminderEnabled = true;

  late int _day;
  late int _month;
  late int _year;
  String _selectedDate = "Hôm nay";
  String _selectedTime = "18:00";
  String _selectedCategory = DatabaseHelper.dailyCategoryName;
  String _selectedGPS = "Chưa thiết lập";

  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;
  List<Map<String, dynamic>> _dbCategories = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _titleController = TextEditingController(text: widget.task?.title ?? "");
    _isHighPriority = widget.task?.isHighPriority ?? false;
    _isDaily =
        widget.task?.isDaily ??
        (widget.task?.category == DatabaseHelper.dailyCategoryName);
    _reminderEnabled = widget.task?.reminderEnabled ?? true;

    _day = widget.task?.day ?? now.day;
    _month = widget.task?.month ?? now.month;
    _year = widget.task?.year ?? now.year;

    if (widget.task != null) {
      _selectedCategory =
          widget.task?.category ?? DatabaseHelper.dailyCategoryName;
      _selectedTime = widget.task?.time ?? "18:00";
      _selectedGPS = widget.task?.locationName ?? "Chưa thiết lập";
      _selectedDate = "$_day/$_month/$_year";
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final user = AppSession.currentUser;
    if (user != null && user.id != null) {
      final cats = await DatabaseHelper.instance.getCategories(user.id!);
      if (!mounted) return;
      setState(() {
        _dbCategories = cats;
        if (widget.task == null &&
            cats.isNotEmpty &&
            !_dbCategories.any((c) => c['name'] == _selectedCategory)) {
          _selectedCategory = cats.first['name'] as String;
          _isDaily = _selectedCategory == DatabaseHelper.dailyCategoryName;
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTracking(
    double targetLat,
    double targetLng,
    String locationName,
  ) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng bật GPS trên điện thoại.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bị từ chối quyền vị trí.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quyền vị trí bị từ chối vĩnh viễn.')),
      );
      return;
    }

    setState(() {
      _isTracking = true;
      _selectedGPS = locationName;
    });

    final Position currentPos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    final double initialDistance = Geolocator.distanceBetween(
      currentPos.latitude,
      currentPos.longitude,
      targetLat,
      targetLng,
    );

    if (initialDistance <= 500) {
      if (!mounted) return;
      setState(() => _isTracking = false);
      _showReminderDialog(locationName);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đang theo dõi vị trí: $locationName')),
    );

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          final double distanceInMeters = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            targetLat,
            targetLng,
          );
          if (distanceInMeters <= 500) {
            _positionStream?.cancel();
            if (!mounted) return;
            setState(() => _isTracking = false);
            _showReminderDialog(locationName);
          }
        });
  }

  void _showReminderDialog(String locationName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Row(
          children: [
            Icon(Icons.location_on, color: AppColors.hpRed, size: 28),
            SizedBox(width: 10),
            Text("Đã đến nơi!", style: TextStyle(color: AppColors.textMain)),
          ],
        ),
        content: Text(
          "Bạn đang ở gần $locationName (Dưới 500m).\nHãy thực hiện task ngay nhé!",
          style: const TextStyle(color: AppColors.textSub, fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Đã hiểu",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGPSPicker() {
    final List<Map<String, dynamic>> savedLocations = [
      {
        "name": "Trường ĐH Công Thương",
        "icon": Icons.school,
        "lat": 10.8064,
        "lng": 106.6264,
      },
      {
        "name": "Sân Cầu Lông (Sóc Trăng)",
        "icon": Icons.sports_tennis,
        "lat": 9.6000,
        "lng": 105.9700,
      },
      {
        "name": "Vị trí hiện tại của tôi",
        "icon": Icons.my_location,
        "lat": 0.0,
        "lng": 0.0,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Thiết lập nhắc nhở GPS",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "App sẽ gửi thông báo khi bạn di chuyển đến gần các khu vực này.",
                style: TextStyle(color: AppColors.textSub, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: savedLocations.length,
                  itemBuilder: (context, index) {
                    final loc = savedLocations[index];
                    return ListTile(
                      leading: Icon(
                        loc["icon"] as IconData,
                        color: AppColors.textSub,
                      ),
                      title: Text(
                        loc["name"] as String,
                        style: const TextStyle(color: AppColors.textMain),
                      ),
                      trailing: const Icon(
                        Icons.gps_fixed,
                        color: AppColors.primary,
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        if ((loc["lat"] as double) == 0.0) {
                          final Position pos =
                              await Geolocator.getCurrentPosition(
                                locationSettings: const LocationSettings(
                                  accuracy: LocationAccuracy.high,
                                ),
                              );
                          _startLocationTracking(
                            pos.latitude,
                            pos.longitude,
                            loc["name"] as String,
                          );
                        } else {
                          _startLocationTracking(
                            loc["lat"] as double,
                            loc["lng"] as double,
                            loc["name"] as String,
                          );
                        }
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

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_year, _month, _day),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _day = picked.day;
        _month = picked.month;
        _year = picked.year;
        _selectedDate = "$_day/$_month/$_year";
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(
        () => _selectedTime =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}",
      );
    }
  }

  void _showCategoryPicker() {
    final TextEditingController addController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                height: 410,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: addController,
                            style: const TextStyle(color: AppColors.textMain),
                            decoration: InputDecoration(
                              hintText: "Nhập danh mục mới...",
                              hintStyle: const TextStyle(
                                color: AppColors.textSub,
                              ),
                              filled: true,
                              fillColor: AppColors.card,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: AppColors.primary,
                            size: 40,
                          ),
                          onPressed: () async {
                            if (addController.text.trim().isNotEmpty) {
                              final user = AppSession.currentUser;
                              if (user != null && user.id != null) {
                                await DatabaseHelper.instance.insertCategory(
                                  user.id!,
                                  addController.text.trim(),
                                );
                                addController.clear();
                                final updatedCats = await DatabaseHelper
                                    .instance
                                    .getCategories(user.id!);
                                setModalState(
                                  () => _dbCategories = updatedCats,
                                );
                                if (!mounted) return;
                                setState(() => _dbCategories = updatedCats);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _dbCategories.length,
                        itemBuilder: (context, index) {
                          final cat = _dbCategories[index];
                          final String catName = cat['name'] as String;
                          final bool isDailyCat =
                              catName == DatabaseHelper.dailyCategoryName ||
                              (cat['isDaily'] ?? 0) == 1;

                          return ListTile(
                            leading: Icon(
                              isDailyCat ? Icons.repeat : Icons.folder,
                              color: isDailyCat
                                  ? AppColors.gold
                                  : AppColors.textSub,
                            ),
                            title: Text(
                              catName,
                              style: TextStyle(
                                color: isDailyCat
                                    ? AppColors.gold
                                    : AppColors.textMain,
                                fontWeight: isDailyCat
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: isDailyCat
                                ? const Text(
                                    "Tự động nhắc mỗi ngày",
                                    style: TextStyle(
                                      color: AppColors.textSub,
                                      fontSize: 11,
                                    ),
                                  )
                                : null,
                            trailing: isDailyCat
                                ? null
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blueAccent,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _editCategory(cat, setModalState),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: AppColors.hpRed,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _deleteCategory(cat, setModalState),
                                      ),
                                    ],
                                  ),
                            onTap: () {
                              setState(() {
                                _selectedCategory = catName;
                                _isDaily = isDailyCat;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editCategory(Map<String, dynamic> cat, StateSetter setModalState) {
    final TextEditingController editController = TextEditingController(
      text: cat['name'] as String,
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          "Sửa danh mục",
          style: TextStyle(color: AppColors.textMain),
        ),
        content: TextField(
          controller: editController,
          style: const TextStyle(color: AppColors.textMain),
          decoration: const InputDecoration(
            hintText: "Tên danh mục mới",
            hintStyle: TextStyle(color: AppColors.textSub),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              "Hủy",
              style: TextStyle(color: AppColors.textSub),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (editController.text.trim().isNotEmpty) {
                final user = AppSession.currentUser;
                if (user != null && user.id != null) {
                  await DatabaseHelper.instance.updateCategoryAndTasks(
                    user.id!,
                    cat['id'] as int,
                    cat['name'] as String,
                    editController.text.trim(),
                  );
                  final updatedCats = await DatabaseHelper.instance
                      .getCategories(user.id!);

                  setModalState(() => _dbCategories = updatedCats);
                  if (mounted) {
                    setState(() {
                      _dbCategories = updatedCats;
                      if (_selectedCategory == cat['name']) {
                        _selectedCategory = editController.text.trim();
                      }
                    });
                  }
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              }
            },
            child: const Text("Lưu", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(Map<String, dynamic> cat, StateSetter setModalState) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          "Xóa danh mục",
          style: TextStyle(color: AppColors.hpRed),
        ),
        content: Text(
          "Bạn có chắc muốn xóa '${cat['name']}'? Các công việc dùng danh mục này sẽ chuyển về 'Khác'.",
          style: const TextStyle(color: AppColors.textMain),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              "Hủy",
              style: TextStyle(color: AppColors.textSub),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.hpRed),
            onPressed: () async {
              final user = AppSession.currentUser;
              if (user != null && user.id != null) {
                await DatabaseHelper.instance.deleteCategoryAndTasks(
                  user.id!,
                  cat['id'] as int,
                  cat['name'] as String,
                );
                final updatedCats = await DatabaseHelper.instance.getCategories(
                  user.id!,
                );

                setModalState(() => _dbCategories = updatedCats);
                if (mounted) {
                  setState(() {
                    _dbCategories = updatedCats;
                    if (_selectedCategory == cat['name']) {
                      _selectedCategory = "Khác";
                      _isDaily = false;
                    }
                  });
                }
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCurrentTask() async {
    final user = AppSession.currentUser;
    if (widget.task?.id != null && user != null && user.id != null) {
      await DatabaseHelper.instance.deleteTask(widget.task!.id!, user.id!);
      await NotificationService().cancelTaskReminder(widget.task!.id!);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  Future<void> _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tên công việc!")),
      );
      return;
    }

    final user = AppSession.currentUser;
    if (user == null || user.id == null) return;

    final bool effectiveDaily =
        _isDaily || _selectedCategory == DatabaseHelper.dailyCategoryName;

    final taskObj = TaskModel(
      id: widget.task?.id,
      day: _day,
      month: _month,
      year: _year,
      title: _titleController.text.trim(),
      time: _selectedTime,
      category: _selectedCategory,
      isDaily: effectiveDaily,
      isHighPriority: _isHighPriority,
      exp: widget.task?.exp ?? 20,
      gold: widget.task?.gold ?? 10,
      isDone: widget.task?.isDone ?? false,
      locationName: _selectedGPS != "Chưa thiết lập" ? _selectedGPS : null,
      reminderEnabled: _reminderEnabled,
    );

    int taskId;
    if (widget.task == null) {
      taskId = await DatabaseHelper.instance.insertTask(taskObj, user.id!);
    } else {
      await DatabaseHelper.instance.updateTask(taskObj, user.id!);
      taskId = widget.task!.id ?? 0;
    }

    if (taskId > 0) {
      if (_reminderEnabled) {
        await NotificationService().scheduleTaskReminder(
          taskId: taskId,
          title: taskObj.title,
          category: taskObj.category,
          timeHHmm: taskObj.time,
          day: taskObj.day,
          month: taskObj.month,
          year: taskObj.year,
          isDaily: taskObj.isDaily,
        );
      } else {
        await NotificationService().cancelTaskReminder(taskId);
      }
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          widget.task == null ? "Thêm nhắc nhở / việc" : "Chi tiết công việc",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (widget.task != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.hpRed),
              onPressed: _deleteCurrentTask,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: "Bạn cần nhắc việc gì?",
                hintStyle: TextStyle(color: AppColors.textSub, fontSize: 22),
                border: InputBorder.none,
              ),
            ),
            const Divider(color: Colors.white24),
            const SizedBox(height: 14),

            if (!_isDaily) ...[
              _buildActionRow(
                Icons.calendar_month,
                "Ngày đến hạn",
                _selectedDate,
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
            ],

            _buildActionRow(
              Icons.access_time,
              "Giờ nhắc nhở",
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

            _buildSwitchTile(
              icon: Icons.repeat,
              title: "Lặp lại mỗi ngày (Hàng ngày)",
              value: _isDaily,
              activeColor: AppColors.gold,
              onChanged: (val) {
                setState(() {
                  _isDaily = val;
                  if (val) {
                    _selectedCategory = DatabaseHelper.dailyCategoryName;
                  } else if (_selectedCategory ==
                      DatabaseHelper.dailyCategoryName) {
                    _selectedCategory = "Cá nhân";
                  }
                });
              },
            ),
            const SizedBox(height: 12),

            _buildSwitchTile(
              icon: Icons.notifications_active_outlined,
              title: "Bật thông báo nhắc giờ",
              value: _reminderEnabled,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _reminderEnabled = val),
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _showGPSPicker,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: _isTracking
                      ? Border.all(color: AppColors.primary)
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: _isTracking
                          ? AppColors.primary
                          : AppColors.textSub,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "Nhắc nhở GPS",
                      style: TextStyle(
                        color: _isTracking
                            ? AppColors.primary
                            : AppColors.textSub,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        _selectedGPS,
                        style: const TextStyle(
                          color: AppColors.textMain,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isTracking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.chevron_right,
                            color: AppColors.textSub,
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            _buildSwitchTile(
              icon: Icons.flag,
              title: "Ưu tiên cao (Màu đỏ)",
              value: _isHighPriority,
              activeColor: AppColors.hpRed,
              onChanged: (val) => setState(() => _isHighPriority = val),
            ),

            const SizedBox(height: 28),
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
                onPressed: _saveTask,
                child: Text(
                  widget.task == null ? "LƯU CÔNG VIỆC" : "CẬP NHẬT",
                  style: const TextStyle(
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSub),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: AppColors.textMain, fontSize: 15),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: activeColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    IconData icon,
    String title,
    String value, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
