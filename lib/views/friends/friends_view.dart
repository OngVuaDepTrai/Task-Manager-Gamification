import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_session.dart';
import '../../core/database_helper.dart';
import '../../models/friend_model.dart';
import 'add_friend_view.dart';

// Màn Bạn bè: [Nút thêm bạn bè] -> [Thanh tìm kiếm] -> [Danh sách bạn bè]
class FriendsView extends StatefulWidget {
  const FriendsView({super.key});

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView> {
  final TextEditingController _searchController = TextEditingController();
  List<FriendModel> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    final user = AppSession.currentUser;
    if (user == null || user.id == null) return;
    final list = await DatabaseHelper.instance.getFriends(user.id!);
    if (!mounted) return;
    setState(() {
      _friends = list;
      _isLoading = false;
    });
  }

  List<FriendModel> get _filteredFriends {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _friends;
    return _friends.where((f) => f.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _confirmRemove(FriendModel friend) async {
    final user = AppSession.currentUser;
    if (user?.id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          "Hủy kết bạn",
          style: TextStyle(color: AppColors.textMain),
        ),
        content: Text(
          "Hủy kết bạn với ${friend.name}?",
          style: const TextStyle(color: AppColors.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              "Không",
              style: TextStyle(color: AppColors.textSub),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.hpRed),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Hủy kết bạn", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseHelper.instance.removeFriend(user!.id!, friend.friendUserId);
      _loadFriends();
    }
  }

  @override
  Widget build(BuildContext context) {
    final friends = _filteredFriends;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "Bạn bè",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // 1. Nút thêm bạn bè
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.person_add_alt_1, color: Colors.black),
                label: const Text(
                  "Thêm bạn bè",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddFriendView()),
                  );
                  _loadFriends();
                },
              ),
            ),
            const SizedBox(height: 14),

            // 2. Thanh tìm kiếm tên bạn bè
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: AppColors.textMain),
              decoration: InputDecoration(
                hintText: "Tìm tên bạn bè...",
                hintStyle: const TextStyle(color: AppColors.textSub),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSub),
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 3. Danh sách bạn bè
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : friends.isEmpty
                  ? Center(
                      child: Text(
                        _friends.isEmpty
                            ? "Bạn chưa có bạn bè nào.\nBấm \"Thêm bạn bè\" để kết bạn."
                            : "Không tìm thấy bạn bè phù hợp.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSub),
                      ),
                    )
                  : ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (_, index) {
                        final f = friends[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            onLongPress: () => _confirmRemove(f),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Text(
                                f.name.isNotEmpty
                                    ? f.name[0].toUpperCase()
                                    : "?",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              f.name,
                              style: const TextStyle(
                                color: AppColors.textMain,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              f.email,
                              style: const TextStyle(color: AppColors.textSub),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "${f.currentStreak}",
                                  style: const TextStyle(
                                    color: AppColors.textMain,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Icon(
                                  Icons.local_fire_department,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                "Nhấn giữ vào một người để hủy kết bạn",
                style: TextStyle(color: AppColors.textSub, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
