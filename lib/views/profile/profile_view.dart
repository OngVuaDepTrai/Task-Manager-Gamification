import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../core/app_session.dart';
import '../../core/database_helper.dart';
import '../../models/user_model.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../services/widget_service.dart';
import '../auth/auth_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ImagePicker _picker = ImagePicker();

  // Danh sách các Icon mặc định của ứng dụng
  final List<IconData> _defaultIcons = [
    Icons.sentiment_satisfied_alt,
    Icons.pets,
    Icons.rocket_launch,
    Icons.sports_esports,
    Icons.music_note,
    Icons.local_fire_department,
    Icons.face,
    Icons.star,
  ];

  // Hàm chung để cập nhật avatarPath lên Database và Session
  Future<void> _updateAvatarPath(String newPath) async {
    final user = AppSession.currentUser;
    if (user != null) {
      final UserModel updatedUser = user.copyWith(avatarPath: newPath);

      await DatabaseHelper.instance.updateUserStats(updatedUser);
      setState(() {
        AppSession.currentUser = updatedUser;
      });
    }
  }

  // 1. Hàm chọn ảnh từ Camera hoặc Thư viện
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        await _updateAvatarPath(image.path); // Lưu đường dẫn file vật lý
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Lỗi khi chọn ảnh!")));
    }
  }

  // 2. Giao diện chọn Icon mặc định của App
  void _showDefaultIconPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Chọn Icon đại diện",
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: _defaultIcons.length,
                  itemBuilder: (context, index) {
                    final icon = _defaultIcons[index];
                    return GestureDetector(
                      onTap: () {
                        // Lưu codePoint của Icon với tiền tố "icon:"
                        _updateAvatarPath('icon:${icon.codePoint}');
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.background,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        child: Icon(icon, color: AppColors.primary, size: 30),
                      ),
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

  // Khung Tùy chọn nguồn ảnh
  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.emoji_emotions, color: Colors.orange),
                title: const Text(
                  'Chọn Icon mặc định',
                  style: TextStyle(color: AppColors.textMain),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDefaultIconPicker();
                },
              ),
              const Divider(color: Colors.white24, height: 1),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Chọn ảnh từ Thư viện',
                  style: TextStyle(color: AppColors.textMain),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Chụp ảnh mới',
                  style: TextStyle(color: AppColors.textMain),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // HÀM RENDER AVATAR THÔNG MINH (Tự phân biệt Icon và File)
  Widget _buildAvatarWidget(String? path, double radius) {
    // 1. Nếu chưa có ảnh -> Hiện chữ cái đầu
    if (path == null || path.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary,
        child: Text(
          AppSession.currentUser?.name.substring(0, 1).toUpperCase() ?? "U",
          style: TextStyle(
            fontSize: radius * 0.8,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // 2. Nếu là Icon mặc định (có chữ icon: ở đầu)
    if (path.startsWith('icon:')) {
      int codePoint = int.parse(path.split(':')[1]);
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary,
        child: Icon(
          IconData(codePoint, fontFamily: 'MaterialIcons'),
          size: radius,
          color: Colors.white,
        ),
      );
    }

    // 3. Nếu là file vật lý từ máy
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      backgroundImage: FileImage(File(path)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AppSession.currentUser;
    final int exp = user?.exp ?? 0;
    final int level = (exp ~/ 100) + 1;
    final double expProgress = (exp % 100) / 100.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Thông tin cá nhân',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // ================= KHU VỰC AVATAR =================
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  // Sử dụng hàm render thông minh
                  _buildAvatarWidget(user?.avatarPath, 55),

                  GestureDetector(
                    onTap: () => _showImageSourceActionSheet(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.background,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.black,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text(
              user?.name ?? "Người dùng",
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Thành viên năng nổ",
              style: TextStyle(
                color: AppColors.primary.withAlpha(200),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 30),

            // ================= KHU VỰC THỐNG KÊ (STATS) =================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Cấp độ hiện tại",
                        style: TextStyle(
                          color: AppColors.textSub,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "Lv. $level",
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: expProgress,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "${exp % 100} / 100 EXP",
                      style: const TextStyle(
                        color: AppColors.textSub,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 30),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          Icons.bolt,
                          Colors.orange,
                          "Tổng EXP",
                          "${user?.exp ?? 0}",
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.white24),
                      Expanded(
                        child: _buildStatItem(
                          Icons.monetization_on,
                          AppColors.gold,
                          "Vàng",
                          "${user?.gold ?? 0}",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          Icons.local_fire_department,
                          AppColors.hpRed,
                          "Chuỗi hiện tại",
                          "${user?.currentStreak ?? 0} ngày",
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.white24),
                      Expanded(
                        child: _buildStatItem(
                          Icons.emoji_events,
                          Colors.yellow,
                          "Kỷ lục chuỗi",
                          "${user?.longestStreak ?? 0} ngày",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ================= KHU VỰC THÔNG TIN TÀI KHOẢN =================
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Thông tin tài khoản",
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              Icons.email,
              "Email",
              user?.email ?? "Không có dữ liệu",
            ),
            const SizedBox(height: 10),
            _buildInfoRow(Icons.lock, "Mật khẩu", "********", isPassword: true),

            const SizedBox(height: 40),

            // ================= NÚT ĐĂNG XUẤT =================
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.hpRed.withAlpha(20),
                  foregroundColor: AppColors.hpRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.hpRed, width: 1.5),
                  ),
                ),
                icon: const Icon(Icons.logout, size: 24),
                label: const Text(
                  "ĐĂNG XUẤT",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: () async {
                  // Hủy nhắc nhở của tài khoản đang đăng xuất
                  NotificationService().cancelAll();
                  NotificationService().stopGroupTaskListener();
                  await LocationService().stop();
                  await DatabaseHelper.instance.signOut();
                  AppSession.currentUser = null;
                  await WidgetService.clear();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthView()),
                    (route) => false,
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    Color color,
    String title,
    String value,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textMain,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(color: AppColors.textSub, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String value, {
    bool isPassword = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSub, size: 24),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppColors.textSub, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textMain,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isPassword)
            TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Tính năng đổi mật khẩu đang cập nhật"),
                ),
              ),
              child: const Text(
                "Đổi",
                style: TextStyle(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
