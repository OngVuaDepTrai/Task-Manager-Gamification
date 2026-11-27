import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../models/task_model.dart';

class GameStore {
  static const maxHp = 100, penalty = 5;
  static int expFor(bool priority) => priority ? 40 : 20;
  static int goldFor(bool priority) => priority ? 20 : 10;
  static String date(DateTime d) => d.toIso8601String().substring(0, 10);
  static DateTime next(DateTime d) => DateTime(d.year, d.month, d.day + 1);

  static Future<void> migrate(DatabaseExecutor db) async {
    await db.execute(
      'ALTER TABLE users ADD COLUMN hp INTEGER NOT NULL DEFAULT $maxHp CHECK(hp BETWEEN 0 AND $maxHp)',
    );
    await db.execute(
      'ALTER TABLE users ADD COLUMN freezes INTEGER NOT NULL DEFAULT 0 CHECK(freezes>=0)',
    );
    await db.execute('ALTER TABLE users ADD COLUMN streak_checked TEXT');
    await db.execute('ALTER TABLE tasks ADD COLUMN checked_day TEXT');
    await db.execute('''CREATE TABLE events (
      id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      task_id INTEGER, kind TEXT NOT NULL, occurrence TEXT NOT NULL, day TEXT,
      title TEXT NOT NULL, exp INTEGER NOT NULL DEFAULT 0, gold INTEGER NOT NULL DEFAULT 0,
      hp INTEGER NOT NULL DEFAULT 0, category TEXT, stamp TEXT,
      UNIQUE(user_id,kind,occurrence))''');
    await db.execute('CREATE INDEX event_days ON events(user_id, day, kind)');
    await db.execute(
      '''CREATE TABLE rewards(id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      name TEXT NOT NULL, description TEXT NOT NULL, category TEXT NOT NULL, price INTEGER NOT NULL CHECK(price>0))''',
    );
    await db.execute(
      '''CREATE TABLE inventory(user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      slot TEXT NOT NULL, equipped INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(user_id,slot))''',
    );
    await db.execute(
      '''CREATE TABLE shared_tasks(id INTEGER PRIMARY KEY, owner INTEGER NOT NULL REFERENCES users(id),
      assignee_id INTEGER NOT NULL REFERENCES users(id), title TEXT NOT NULL, done INTEGER NOT NULL DEFAULT 0)''',
    );
    // V1 recorded the date of daily completions only. Historical balances already include these rewards.
    await db.execute(
      """INSERT INTO events(user_id,task_id,kind,occurrence,day,title)
      SELECT t.user_id,t.id,'complete',t.id||'/'||c.date_key,c.date_key,t.title
      FROM daily_task_completions c JOIN tasks t ON t.id=c.task_id AND t.user_id=c.user_id WHERE c.is_done=1""",
    );
    await db.execute(
      """INSERT INTO events(user_id,task_id,kind,occurrence,title)
      SELECT user_id,id,'complete',CAST(id AS TEXT),title FROM tasks WHERE isDaily=0 AND isDone=1""",
    );
    await db.execute(
      "UPDATE tasks SET checked_day=date('now','localtime','-1 day') WHERE isDaily=1",
    );
  }

  static Future<void> reconcile(
    DatabaseExecutor db,
    int uid,
    DateTime now,
  ) async {
    final today = date(now);
    final tasks = await db.query(
      'tasks',
      where: 'user_id=? AND (isDaily=1 OR isDone=0)',
      whereArgs: [uid],
    );
    for (final row in tasks) {
      final t = TaskModel.fromMap(row);
      var day = DateTime(t.year, t.month, t.day);
      if (t.isDaily && row['checked_day'] != null) {
        final start = next(DateTime.parse(row['checked_day'] as String));
        if (start.isAfter(day)) day = start;
      }
      final parts = t.time.split(':');
      final hour = int.tryParse(parts.first) ?? 23,
          minute = int.tryParse(parts.last) ?? 59;
      String? last;
      while (!DateTime(
        day.year,
        day.month,
        day.day,
        hour,
        minute,
      ).isAfter(now)) {
        final key = date(day);
        final occurrence = t.isDaily ? '${t.id}/$key' : '${t.id}';
        final completed =
            t.isDaily &&
            (await db.query(
              'daily_task_completions',
              columns: ['id'],
              where: 'user_id=? AND task_id=? AND date_key=? AND is_done=1',
              whereArgs: [uid, t.id, key],
              limit: 1,
            )).isNotEmpty;
        final prior = await db.query(
          'events',
          columns: ['id'],
          where: "user_id=? AND occurrence=? AND kind='penalty'",
          whereArgs: [uid, occurrence],
          limit: 1,
        );
        if (!completed && prior.isEmpty) {
          final hp =
              (await db.query(
                    'users',
                    columns: ['hp'],
                    where: 'id=?',
                    whereArgs: [uid],
                  )).first['hp']
                  as int;
          final lost = min(penalty, hp);
          await db.insert('events', {
            'user_id': uid,
            'task_id': t.id,
            'kind': 'penalty',
            'occurrence': occurrence,
            'day': key,
            'title': t.title,
            'hp': -lost,
            'stamp': now.toIso8601String(),
          });
          await db.rawUpdate('UPDATE users SET hp=hp-? WHERE id=?', [
            lost,
            uid,
          ]);
        }
        if (!t.isDaily) break;
        last = key;
        day = next(day);
      }
      if (last != null) {
        await db.update(
          'tasks',
          {'checked_day': last},
          where: 'id=? AND user_id=?',
          whereArgs: [t.id, uid],
        );
      }
    }
    await streak(db, uid, today);
  }

  static Future<void> streak(DatabaseExecutor db, int uid, String today) async {
    final rows = await db.rawQuery(
      "SELECT day, MAX(kind='complete') AS active FROM events WHERE user_id=? AND day<=? AND kind IN ('complete','freeze') GROUP BY day ORDER BY day",
      [uid, today],
    );
    final profile = (await db.query(
      'users',
      where: 'id=?',
      whereArgs: [uid],
    )).first;
    var shields = profile['freezes'] as int,
        longest = profile['longestStreak'] as int,
        run = 0;
    DateTime? last;
    for (final row in rows) {
      final d = DateTime.parse(row['day'] as String);
      if (last == null || next(last) != d) run = 0;
      if (row['active'] == 1) run++;
      longest = max(longest, run);
      last = d;
    }
    if (last != null) {
      var gap = next(last);
      while (date(gap).compareTo(today) < 0) {
        if (shields == 0 ||
            (profile['streak_checked'] != null &&
                date(gap).compareTo(profile['streak_checked'] as String) <=
                    0)) {
          run = 0;
          break;
        }
        final key = date(gap);
        await db.insert('events', {
          'user_id': uid,
          'kind': 'freeze',
          'occurrence': key,
          'day': key,
          'title': 'Khiên bảo vệ chuỗi',
        });
        shields--;
        gap = next(gap);
      }
    }
    await db.update(
      'users',
      {
        'streak_checked': date(
          DateTime.parse(today).subtract(const Duration(hours: 12)),
        ),
        'currentStreak': run,
        'longestStreak': longest,
        'freezes': shields,
      },
      where: 'id=?',
      whereArgs: [uid],
    );
  }

  static Future<bool> complete(
    Database db,
    int uid,
    int id,
    bool done,
    DateTime now,
  ) => db.transaction((tx) async {
    await reconcile(tx, uid, now);
    final rows = await tx.query(
      'tasks',
      where: 'id=? AND user_id=?',
      whereArgs: [id, uid],
    );
    if (rows.isEmpty) return false;
    final t = TaskModel.fromMap(rows.first), day = date(now);
    if (DateTime(t.year, t.month, t.day).isAfter(now)) return false;
    final occurrence = t.isDaily ? '$id/$day' : '$id';
    if (t.isDaily) {
      await tx.insert('daily_task_completions', {
        'user_id': uid,
        'task_id': id,
        'date_key': day,
        'is_done': done ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await tx.update(
        'tasks',
        {'isDone': done ? 1 : 0},
        where: 'id=? AND user_id=?',
        whereArgs: [id, uid],
      );
    }
    if (!done) {
      if (t.isDaily) {
        await tx.rawUpdate(
          'UPDATE tasks SET checked_day=? WHERE user_id=? AND id=? AND checked_day=?',
          [date(DateTime(now.year, now.month, now.day - 1)), uid, id, day],
        );
      }
      await reconcile(tx, uid, now);
      return false;
    }
    final prior = await tx.query(
      'events',
      where: "user_id=? AND kind='complete' AND occurrence=?",
      whereArgs: [uid, occurrence],
    );
    if (prior.isNotEmpty) return false;
    final xp = max(0, t.exp), gold = max(0, t.gold);
    await tx.insert('events', {
      'user_id': uid,
      'task_id': id,
      'kind': 'complete',
      'occurrence': occurrence,
      'day': day,
      'title': t.title,
      'exp': xp,
      'gold': gold,
      'stamp': now.toIso8601String(),
    });
    await tx.rawUpdate('UPDATE users SET exp=exp+?, gold=gold+? WHERE id=?', [
      xp,
      gold,
      uid,
    ]);
    await streak(tx, uid, day);
    return true;
  });
}
