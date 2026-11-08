/// A streak's fields where the delegate keeps it. [count] and [time] are the ones 1.x wrote, so its streaks still read.
abstract final class StreakKeys {
  /// The current streak's days.
  static const count = 'count';

  /// The current streak's last counted day, in milliseconds since the epoch (as 1.x kept it).
  static const time = 'time';

  /// The current streak's last counted day, as a day key; read over [time] when present.
  static const day = 'day';

  /// The longest streak ever.
  static const best = 'best';

  /// The streak that broke last, kept to restore it.
  static const last = 'last';

  /// [last]'s last counted day.
  static const lastDay = 'lastDay';

  /// Every counted day.
  static const history = 'history';

  /// The days a restore filled in: missed, but counted.
  static const restored = 'restored';

  /// A team streak's days: who was in the team, who completed it, who was active.
  static const days = 'days';
  static const members = 'members';
  static const done = 'done';
  static const active = 'active';
}
