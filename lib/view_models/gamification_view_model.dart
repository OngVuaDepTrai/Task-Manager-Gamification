import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../core/app_session.dart';
import '../core/database_helper.dart';
import '../models/shop_item_model.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/game_store.dart';

class GamificationViewModel extends ChangeNotifier {
  List<Map<String, Object?>> events = [], ranking = [];
  List<ShopItemModel> custom = [];
  Map<String, bool> inventory = {};
  int total = 0, done = 0, overdue = 0;
  int _revision = 0;
  int get uid => AppSession.currentUser!.id!;
  String get today => GameStore.date(DateTime.now());
  bool activeToday = false;
  static const completedTodaySql = """SELECT 1 FROM events e JOIN tasks t ON t.id=e.task_id AND t.user_id=e.user_id
    WHERE e.user_id=? AND e.day=? AND e.kind='complete' AND
    ((t.isDaily=0 AND t.isDone=1) OR EXISTS(SELECT 1 FROM daily_task_completions c WHERE c.task_id=t.id AND c.user_id=t.user_id AND c.date_key=e.day AND c.is_done=1)) LIMIT 1""";
  int completedSince(String start) => events
      .where(
        (e) =>
            e['kind'] == 'complete' &&
            e['day'] != null &&
            (e['day'] as String).compareTo(start) >= 0,
      )
      .length;
  Future<Database> get database => DatabaseHelper.instance.database;

  Future<void> refresh() async {
    final id = uid, revision = ++_revision, now = DateTime.now();
    final db = await database;
    await db.transaction((tx) async {
      await GameStore.reconcile(tx, id, now);
      final peers = await tx.rawQuery(
        "SELECT friend_user_id FROM friends WHERE user_id=? AND status='accepted'",
        [id],
      );
      for (final row in peers) {
        await GameStore.streak(
          tx,
          row['friend_user_id'] as int,
          GameStore.date(now),
        );
      }
      final leaders = await tx.rawQuery(
        """SELECT id,name,currentStreak,exp FROM users WHERE id=? OR id IN
        (SELECT friend_user_id FROM friends WHERE user_id=? AND status='accepted') ORDER BY currentStreak DESC,exp DESC,id""",
        [id, id],
      );
      final profile = UserModel.fromMap(
        (await tx.query('users', where: 'id=?', whereArgs: [id])).single,
      );
      final history = await tx.query(
        'events',
        where: 'user_id=?',
        whereArgs: [id],
        orderBy: 'day DESC,id DESC',
      );
      final active = (await tx.rawQuery(completedTodaySql, [
        id,
        GameStore.date(now),
      ])).isNotEmpty;
      final gear = await tx.query(
        'inventory',
        where: 'user_id=?',
        whereArgs: [id],
      );
      final rewards = await tx.query(
        'rewards',
        where: 'user_id=?',
        whereArgs: [id],
      );
      final tasks = await tx.query(
        'tasks',
        where: 'user_id=?',
        whereArgs: [id],
      );
      final completions = await tx.rawQuery(
        'SELECT task_id,count(*) AS n, MAX(date_key=?) AS today_done FROM daily_task_completions WHERE user_id=? AND is_done=1 AND date_key<=? GROUP BY task_id',
        [GameStore.date(now), id, GameStore.date(now)],
      );
      final counts = {for (final c in completions) c['task_id']: c['n'] as int};
      final doneToday = {
        for (final c in completions)
          if (c['today_done'] == 1) c['task_id'],
      };
      var n = 0, finished = 0, late = 0;
      for (final row in tasks) {
        final t = TaskModel.fromMap(row);
        if (t.isDaily) {
          final elapsed =
              DateTime.utc(
                now.year,
                now.month,
                now.day,
              ).difference(DateTime.utc(t.year, t.month, t.day)).inDays +
              1;
          final count = counts[t.id] ?? 0;
          n += max(1, max(count, elapsed));
          finished += count;
          final time = t.time.split(':');
          final deadline = DateTime(
            now.year,
            now.month,
            now.day,
            int.tryParse(time.first) ?? 23,
            int.tryParse(time.last) ?? 59,
          );
          late += max(
            0,
            elapsed -
                count -
                (now.isBefore(deadline) && !doneToday.contains(t.id) ? 1 : 0),
          );
        } else {
          n++;
          if (t.isDone) finished++;
          if (t.isOverdue(now)) late++;
        }
      }
      if (AppSession.currentUser?.id != id || revision != _revision) return;
      AppSession.currentUser = profile;
      total = n;
      done = finished;
      overdue = late;
      activeToday = active;
      events = history;
      ranking = leaders;
      inventory = {
        for (final g in gear) g['slot'] as String: g['equipped'] == 1,
      };
      custom = [
        for (final r in rewards)
          ShopItemModel(
            id: r['id'] as int,
            name: r['name'] as String,
            description: r['description'] as String,
            category: r['category'] as String,
            price: r['price'] as int,
            icon: Icons.redeem,
          ),
      ];
    });
    if (AppSession.currentUser?.id == id && revision == _revision) {
      notifyListeners();
    }
  }

  Future<String?> buy(ShopItemModel item, String receipt) async {
    final id = uid, db = await database, now = DateTime.now();
    final error = await db.transaction<String?>((tx) async {
      await GameStore.streak(tx, id, GameStore.date(now));
      final seen = await tx.query(
        'events',
        where: "user_id=? AND kind='purchase' AND occurrence=?",
        whereArgs: [id, receipt],
      );
      if (seen.isNotEmpty) return 'Giao dịch đã được xử lý.';
      if (item.id != null) {
        final row = await tx.query(
          'rewards',
          where: 'user_id=? AND id=? AND price=? AND name=? AND category=?',
          whereArgs: [id, item.id, item.price, item.name, item.category],
        );
        if (row.isEmpty) return 'Phần thưởng đã thay đổi.';
      } else if (!ShopItemModel.catalog.contains(item)) {
        return 'Phần thưởng không hợp lệ.';
      }
      final slot = item.slot;
      if (slot != null && slot != 'freeze') {
        if ((await tx.query(
          'inventory',
          where: 'user_id=? AND slot=?',
          whereArgs: [id, slot],
        )).isNotEmpty) {
          return 'Bạn đã sở hữu vật phẩm.';
        }
      }
      if (await tx.rawUpdate(
            'UPDATE users SET gold=gold-? WHERE id=? AND gold>=?',
            [item.price, id, item.price],
          ) !=
          1) {
        return 'Không đủ Vàng.';
      }
      if (slot == 'freeze') {
        await tx.rawUpdate('UPDATE users SET freezes=freezes+1 WHERE id=?', [
          id,
        ]);
      } else if (slot != null) {
        await tx.insert('inventory', {'user_id': id, 'slot': slot});
      }
      await tx.insert('events', {
        'user_id': id,
        'kind': 'purchase',
        'occurrence': receipt,
        'day': GameStore.date(now),
        'stamp': now.toIso8601String(),
        'title': item.name,
        'category': item.category,
        'gold': -item.price,
      });
      return null;
    });
    if (AppSession.currentUser?.id == id) await refresh();
    return error;
  }

  Future<void> equip(String slot, bool equipped) async {
    final id = uid, db = await database;
    await db.rawUpdate(
      """UPDATE inventory SET equipped=? WHERE slot=? AND user_id=? AND EXISTS
       (SELECT 1 FROM users WHERE id=? AND currentStreak>=10) AND EXISTS
       ($completedTodaySql)""",
      [equipped ? 1 : 0, slot, id, id, id, today],
    );
    if (AppSession.currentUser?.id == id) await refresh();
  }

  Future<void> saveReward(
    int? rewardId,
    String name,
    String description,
    int price,
    String category,
  ) async {
    if (name.trim().isEmpty || price <= 0) {
      throw ArgumentError('Tên hoặc giá không hợp lệ.');
    }
    final id = uid, db = await database;
    final values = {
      'user_id': id,
      'name': name.trim(),
      'description': description.trim(),
      'price': price,
      'category': category,
    };
    if (rewardId == null) {
      await db.insert('rewards', values);
    } else {
      await db.update(
        'rewards',
        values,
        where: 'user_id=? AND id=?',
        whereArgs: [id, rewardId],
      );
    }
    if (AppSession.currentUser?.id == id) await refresh();
  }

  Future<void> deleteReward(int rewardId) async {
    final id = uid, db = await database;
    await db.delete(
      'rewards',
      where: 'user_id=? AND id=?',
      whereArgs: [id, rewardId],
    );
    if (AppSession.currentUser?.id == id) await refresh();
  }
}
