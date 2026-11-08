import 'dart:math' as math;

import '../enums/streak_mode.dart';
import '../models/streak_data.dart';
import 'streak_days.dart';

/// How a streak changes, on its own day keys, apart from where it is kept. Each change gives the new streak, or null
/// when nothing changes, so nothing is written.
abstract final class StreakRules {
  /// [data] as it stands on [today]: a streak whose last counted day is before yesterday has broken. It starts again
  /// from 0, and is kept as the last streak, to restore.
  static StreakData settle(StreakData data, String today) {
    final day = data.day;
    if (data.count <= 0 || day == null || StreakDays.between(day, today) <= 1) return data;
    return data.copyWith(count: 0, last: data.count, lastDay: day);
  }

  /// [member] completed [today]. Alone, the day counts; in a team ([members]), it counts once every member completed
  /// it, and who completed it and who was active are kept either way.
  static StreakData? complete(StreakData data, String today, String member, Set<String> members, StreakMode mode) {
    final now = settle(data, today);
    if (mode == StreakMode.single) return now.counted(today) ? null : _count(now, today);
    final day = now.dayOf(today);
    if (day.done.contains(member)) return null;
    final next = day.copyWith(members: members, done: {...day.done, member}, active: {...day.active, member});
    final updated = now.copyWith(days: {...now.days, today: next});
    return next.complete && !now.counted(today) ? _count(updated, today) : updated;
  }

  /// [member] was active in a team on [today], without completing it.
  static StreakData? active(StreakData data, String today, String member, Set<String> members) {
    final now = settle(data, today);
    final day = now.dayOf(today);
    if (day.active.contains(member)) return null;
    return now.copyWith(
      days: {
        ...now.days,
        today: day.copyWith(members: members, active: {...day.active, member}),
      },
    );
  }

  /// The last streak back, however long ago it broke: the days it missed go in the ignore list (restored), and the
  /// streak since then, if any, adds on to it.
  static StreakData? restore(StreakData data, String today) {
    final now = settle(data, today);
    final lastDay = now.lastDay, day = now.day;
    if (!now.restorable || lastDay == null) return null;
    // The missed days end the day before the current streak began, or yesterday when there is none.
    final current = now.count > 0 && day != null;
    final end = current ? StreakDays.add(day, -now.count) : StreakDays.add(today, -1);
    final count = now.last + now.count;
    return now.copyWith(
      count: count,
      day: current ? day : end,
      best: math.max(now.best, count),
      clearLast: true,
      restored: {...now.restored, ...StreakDays.range(StreakDays.add(lastDay, 1), end)},
    );
  }

  /// [today] counted: one more day on a streak that counted yesterday, or a new streak of 1.
  static StreakData _count(StreakData data, String today) {
    final count = data.count > 0 && data.day == StreakDays.add(today, -1) ? data.count + 1 : 1;
    return data.copyWith(count: count, day: today, best: math.max(data.best, count), history: {...data.history, today});
  }
}
