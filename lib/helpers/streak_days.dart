/// Days as `YYYY-MM-DD` keys. Counted on UTC dates, so every day is 24 hours long (no daylight saving shift).
abstract final class StreakDays {
  /// [day]'s key, from its year, month and day.
  static String key(DateTime day) => '${_pad(day.year, 4)}-${_pad(day.month, 2)}-${_pad(day.day, 2)}';

  static DateTime date(String key) {
    final parts = key.split('-');
    return DateTime.utc(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  /// [value] as a key: a `YYYY-MM-DD` key, or a `Y/M/D` one as 1.x kept history; null when it is neither.
  static String? parse(Object? value) {
    if (value is! String) return null;
    final parts = value.split(value.contains('/') ? '/' : '-').map(int.tryParse).toList();
    if (parts.length != 3 || parts.contains(null)) return null;
    return key(DateTime.utc(parts[0]!, parts[1]!, parts[2]!));
  }

  /// The day of 1.x's `time`, a moment on the phone that wrote it.
  static String ofMillis(int millis) => key(DateTime.fromMillisecondsSinceEpoch(millis));

  /// [key]'s noon (UTC), in milliseconds: the same date on any phone 1.x reads it on.
  static int noonMillis(String key) => date(key).add(const Duration(hours: 12)).millisecondsSinceEpoch;

  static String add(String key, int days) => StreakDays.key(date(key).add(Duration(days: days)));

  /// Days from [from] to [to]; negative when [to] is before.
  static int between(String from, String to) => date(to).difference(date(from)).inDays;

  /// The days from [from] to [to], both included; none when [to] is before [from].
  static List<String> range(String from, String to) => [for (var i = 0; i <= between(from, to); i++) add(from, i)];

  static String _pad(int value, int width) => value.toString().padLeft(width, '0');
}
