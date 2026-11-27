import '../core/database_helper.dart';

class SharedTasks {
  static Future<List<Map<String, Object?>>> list(int viewer) async {
    final db = await DatabaseHelper.instance.database;
    return db.rawQuery(
      '''SELECT s.*,u.name AS assignee FROM shared_tasks s JOIN users u ON s.assignee_id=u.id
      WHERE owner=? OR assignee_id=? ORDER BY s.id DESC''',
      [viewer, viewer],
    );
  }

  static Future<bool> assign(int owner, int assignee, String title) async {
    if (title.trim().isEmpty) return false;
    final db = await DatabaseHelper.instance.database;
    return db.transaction((tx) async {
      if (owner != assignee &&
          (await tx.query(
            'friends',
            where: "user_id=? AND friend_user_id=? AND status='accepted'",
            whereArgs: [owner, assignee],
          )).isEmpty) {
        return false;
      }
      await tx.insert('shared_tasks', {
        'owner': owner,
        'assignee_id': assignee,
        'title': title.trim(),
      });
      return true;
    });
  }

  static Future<bool> setDone(int viewer, int task, bool done) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
          'shared_tasks',
          {'done': done ? 1 : 0},
          where: 'id=? AND (owner=? OR assignee_id=?)',
          whereArgs: [task, viewer, viewer],
        ) ==
        1;
  }
}
