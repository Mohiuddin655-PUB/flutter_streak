import '../keys/streak_keys.dart';

/// One day of a team streak: who was in the team, who completed it and who was active, so a calendar can show the
/// day's progress and who took part.
class StreakDay {
  const StreakDay({this.members = const {}, this.done = const {}, this.active = const {}});

  factory StreakDay.parse(Object? source) {
    Set<String> ids(Object? value) => value is List ? value.whereType<String>().toSet() : <String>{};
    final map = source is Map ? source : const {};
    return StreakDay(
      members: ids(map[StreakKeys.members]),
      done: ids(map[StreakKeys.done]),
      active: ids(map[StreakKeys.active]),
    );
  }

  static const empty = StreakDay();

  /// The team that day.
  final Set<String> members;

  /// Those who completed it.
  final Set<String> done;

  /// Those who were active, whether or not they completed it.
  final Set<String> active;

  /// Every member completed it.
  bool get complete => members.isNotEmpty && members.every(done.contains);

  /// The share of members who completed it, 0 to 1.
  double get progress => members.isEmpty ? 0 : members.where(done.contains).length / members.length;

  StreakDay copyWith({Set<String>? members, Set<String>? done, Set<String>? active}) {
    return StreakDay(members: members ?? this.members, done: done ?? this.done, active: active ?? this.active);
  }

  Map<String, Object?> toMap() {
    return {
      StreakKeys.members: members.toList()..sort(),
      StreakKeys.done: done.toList()..sort(),
      StreakKeys.active: active.toList()..sort(),
    };
  }
}
