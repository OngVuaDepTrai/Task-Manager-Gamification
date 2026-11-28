class GroupModel {
  final int id;
  final String name;
  final int leaderId;
  final String leaderName;
  final int memberCount;

  GroupModel({
    required this.id,
    required this.name,
    required this.leaderId,
    this.leaderName = '',
    this.memberCount = 0,
  });

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'],
      name: map['name'] ?? '',
      leaderId: map['leader_id'] ?? 0,
      leaderName: map['leader_name'] ?? '',
      memberCount: map['member_count'] ?? 0,
    );
  }
}
