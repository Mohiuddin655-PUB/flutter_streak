import 'dart:math' as math;

import '../helpers/streak_days.dart';
import '../keys/streak_keys.dart';
import 'streak_day.dart';

/// A streak as the delegate keeps it, read leniently: 1.x's streaks (only `count`, `time` and `history`) read too.
class StreakData {
  const StreakData({
    this.count = 0,
    this.day,
    this.best = 0,
    this.last = 0,
    this.lastDay,
    this.history = const {},
    this.restored = const {},
    this.days = const {},
  });

  factory StreakData.parse(Object? source) {
    final map = source is Map ? source : const {};
    int whole(Object? value) => value is num ? value.toInt() : 0;
    Set<String> keys(Object? value) =>
        value is List ? value.map(StreakDays.parse).whereType<String>().toSet() : <String>{};
    final time = map[StreakKeys.time], days = map[StreakKeys.days];
    final count = whole(map[StreakKeys.count]);
    return StreakData(
      count: count,
      day: StreakDays.parse(map[StreakKeys.day]) ?? (time is num ? StreakDays.ofMillis(time.toInt()) : null),
      best: math.max(whole(map[StreakKeys.best]), count),
      last: whole(map[StreakKeys.last]),
      lastDay: StreakDays.parse(map[StreakKeys.lastDay]),
      history: keys(map[StreakKeys.history]),
      restored: keys(map[StreakKeys.restored]),
      days: {
        if (days is Map)
          for (final MapEntry(:key, :value) in days.entries) ?StreakDays.parse(key): StreakDay.parse(value),
      },
    );
  }

  static const empty = StreakData();

  /// The current streak's days; 0 when there is none.
  final int count;

  /// The current streak's last counted day (a day key).
  final String? day;

  /// The longest streak ever.
  final int best;

  /// The streak that broke last, to restore; 0 when there is none.
  final int last;

  /// [last]'s last counted day.
  final String? lastDay;

  /// Every day counted by completing it.
  final Set<String> history;

  /// The ignore list: days missed, then counted by a restore.
  final Set<String> restored;

  /// A team streak's days, by day key.
  final Map<String, StreakDay> days;

  /// [day] counts towards a streak: completed, or restored.
  bool counted(String day) => history.contains(day) || restored.contains(day);

  /// A team's [day]; empty when nobody took part.
  StreakDay dayOf(String day) => days[day] ?? StreakDay.empty;

  /// A broken streak can be restored.
  bool get restorable => last > 0 && lastDay != null;

  StreakData copyWith({
    int? count,
    String? day,
    int? best,
    int? last,
    String? lastDay,
    bool clearLast = false,
    Set<String>? history,
    Set<String>? restored,
    Map<String, StreakDay>? days,
  }) {
    return StreakData(
      count: count ?? this.count,
      day: day ?? this.day,
      best: best ?? this.best,
      last: clearLast ? 0 : last ?? this.last,
      lastDay: clearLast ? null : lastDay ?? this.lastDay,
      history: history ?? this.history,
      restored: restored ?? this.restored,
      days: days ?? this.days,
    );
  }

  Map<String, Object?> toMap() {
    final day = this.day;
    return {
      StreakKeys.count: count,
      StreakKeys.time: day == null ? null : StreakDays.noonMillis(day),
      StreakKeys.day: day,
      StreakKeys.best: best,
      StreakKeys.last: last,
      StreakKeys.lastDay: lastDay,
      StreakKeys.history: history.toList()..sort(),
      StreakKeys.restored: restored.toList()..sort(),
      StreakKeys.days: {for (final MapEntry(:key, :value) in days.entries) key: value.toMap()},
    };
  }
}
