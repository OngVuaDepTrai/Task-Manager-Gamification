import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_session.dart';
import '../../core/database_helper.dart';
import '../../models/friend_model.dart';
import '../../models/group_model.dart';
import 'group_detail_view.dart';

// Màn Việc nhóm: danh sách các nhóm đang tham gia + nút thêm việc nhóm
class GroupsView extends StatefulWidget {
  const GroupsView({super.key});

  @override
  State<GroupsView> createState() => _GroupsViewState();
}

class _GroupsViewState extends State<GroupsView> {
  List<GroupModel> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final user = AppSession.currentUser;
    if (user == null || user.id == null) return;
    final list = await DatabaseHelper.instance.getGroupsForUser(user.id!);
    if (!mounted) return;
    setState(() {
      _groups = list;
      _isLoading = false;
    });
  }

  // Cửa sổ thêm việc nhóm: tên việc nhóm + tích chọn bạn bè + nút Tạo
  Future<void> _openCreateGroupDialog() async {
    final user = AppSession.currentUser;
    if (user == null || user.id == null) return;
    final List<FriendModel> friends = await DatabaseHelper.instance.getFriends(
      user.id!,
    );
    if (!mounted) return;

    final nameController = TextEditingController();
    final Set<int> selected = {};

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text(
            "Thêm việc nhóm",
            style: TextStyle(color: AppColors.textMain),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textMain),
                  decoration: const InputDecoration(
                    hintText: "Tên việc nhóm...",
                    hintStyle: TextStyle(color: AppColors.textSub),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Chọn thành viên (${selected.length} đã chọn)",
                  style: const TextStyle(color: AppColors.textSub),
                ),
                const SizedBox(height: 6),
                if (friends.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      "Bạn chưa có bạn bè nào để mời vào nhóm.",
                      style: TextStyle(color: AppColors.textSub),
                    ),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: friends
                          .map(
                            (f) => CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              activeColor: AppColors.primary,
                              checkColor: Colors.black,
                              value: selected.contains(f.friendUserId),
                              onChanged: (val) => setDialogState(() {
                                if (val == true) {
                                  selected.add(f.friendUserId);
                                } else {
                                  selected.remove(f.friendUserId);
                                }
                              }),
                              title: Text(
                                f.name,
                                style: const TextStyle(
                                  color: AppColors.textMain,
                                ),
                              ),
                              subtitle: Text(
                                f.email,
                                style: const TextStyle(
                                  color: AppColors.textSub,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty || selected.isEmpty) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Nhập tên việc nhóm và chọn ít nhất 1 thành viên",
                      ),
                    ),
                  );
                  return;
                }
                await DatabaseHelper.instance.createGroup(
                  name,
                  user.id!,
                  selected.toList(),
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text(
                "Tạo",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    _loadGroups();
  }

  @override
  Widget build(BuildContext context) {
    final myId = AppSession.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "Việc nhóm",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _groups.isEmpty
          ? const Center(
              child: Text(
                "Chưa có nhóm nào.\nBấm \"Thêm việc nhóm\" để tạo nhóm.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSub),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
              itemCount: _groups.length,
              itemBuilder: (_, index) {
                final g = _groups[index];
                final bool isLeader = g.leaderId == myId;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupDetailView(group: g),
                        ),
                      );
                      _loadGroups();
                    },
                    leading: const CircleAvatar(
                      backgroundColor: Colors.greenAccent,
                      child: Icon(Icons.group, color: Colors.black),
                    ),
                    title: Text(
                      g.name,
                      style: const TextStyle(
                        color: AppColors.textMain,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Nhóm trưởng: ${isLeader ? 'Bạn' : g.leaderName} · ${g.memberCount} thành viên",
                      style: const TextStyle(color: AppColors.textSub),
                    ),
                    trailing: isLeader
                        ? const Icon(Icons.star, color: AppColors.gold)
                        : const Icon(
                            Icons.chevron_right,
                            color: AppColors.textSub,
                          ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _openCreateGroupDialog,
        icon: const Icon(Icons.group_add, color: Colors.black),
        label: const Text(
          "Thêm việc nhóm",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
