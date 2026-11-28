import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_session.dart';
import '../../core/database_helper.dart';
import '../../models/friend_model.dart';
import '../../models/notification_model.dart';

// Thông báo: (1) Lời mời kết bạn  (2) Thông báo nhóm: được giao việc, được thêm vào nhóm
class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  List<FriendModel> _requests = [];
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load(markRead: true);
  }

  Future<void> _load({bool markRead = false}) async {
    final user = AppSession.currentUser;
    if (user == null || user.id == null) return;
    final db = DatabaseHelper.instance;
    final requests = await db.getIncomingFriendRequests(user.id!);
    final notifications = await db.getNotifications(user.id!);
    // Mở màn hình = đã xem (vẫn hiển thị chấm "mới" cho lần xem này)
    if (markRead) await db.markAllNotificationsRead(user.id!);
    if (!mounted) return;
    setState(() {
      _requests = requests;
      _notifications = notifications;
      _isLoading = false;
    });
  }

  Future<void> _respond(FriendModel request, bool accept) async {
    final me = AppSession.currentUser;
    if (me?.id == null) return;
    final db = DatabaseHelper.instance;
    // request.userId là người gửi lời mời
    if (accept) {
      await db.acceptFriendRequestFrom(request.userId, me!.id!);
    } else {
      await db.declineFriendRequestFrom(request.userId, me!.id!);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          accept
              ? "Đã kết bạn với ${request.name}"
              : "Đã từ chối lời mời của ${request.name}",
        ),
      ),
    );
    _load();
  }

  String _formatTime(String iso) {
    final t = DateTime.tryParse(iso);
    if (t == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(t.hour)}:${two(t.minute)} · ${t.day}/${t.month}/${t.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "Thông báo",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionTitle("Lời mời kết bạn", _requests.length),
                  if (_requests.isEmpty)
                    _emptyText("Không có lời mời kết bạn nào.")
                  else
                    ..._requests.map(_buildRequestTile),
                  const SizedBox(height: 20),
                  _sectionTitle("Thông báo nhóm", _notifications.length),
                  if (_notifications.isEmpty)
                    _emptyText("Chưa có thông báo nhóm nào.")
                  else
                    ..._notifications.map(_buildNotificationTile),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String text, int count) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      "$text ($count)",
      style: const TextStyle(
        color: AppColors.textMain,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _emptyText(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: const TextStyle(color: AppColors.textSub)),
  );

  Widget _buildRequestTile(FriendModel r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text(
              r.name.isNotEmpty ? r.name[0].toUpperCase() : "?",
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.name,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  r.email,
                  style: const TextStyle(color: AppColors.textSub, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Từ chối",
            icon: const Icon(Icons.close, color: AppColors.hpRed),
            onPressed: () => _respond(r, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => _respond(r, true),
            child: const Text(
              "Chấp nhận",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: n.isRead
              ? Colors.transparent
              : Colors.greenAccent.withAlpha(120),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            n.type == 'group_added' ? Icons.group_add : Icons.assignment_ind,
            color: Colors.greenAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.message,
                  style: const TextStyle(color: AppColors.textMain, height: 1.4),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(n.createdAt),
                  style: const TextStyle(color: AppColors.textSub, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!n.isRead)
            const Padding(
              padding: EdgeInsets.only(left: 6, top: 4),
              child: Text(
                "MỚI",
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
