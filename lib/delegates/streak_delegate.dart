import '../models/streak_data.dart';

/// Where a streak is kept (on the phone, in a database, or both) and whose day it is. Errors are the delegate's to
/// report: the streak only hears that a write didn't happen.
abstract class StreakDelegate {
  const StreakDelegate();

  /// The streak kept close by (such as a copy on the phone), shown at once on [Streak.init]; null when there is none.
  Map<String, dynamic>? cached() => null;

  /// The streak now and each time it changes.
  Stream<Map<String, dynamic>?> listen();

  /// Writes what [change] makes of the streak as it is stored, atomically (such as in a transaction, which may run
  /// [change] more than once), and gives back the streak after it. When [change] gives null, nothing is written.
  Future<Map<String, dynamic>?> write(Map<String, dynamic>? Function(Map<String, dynamic>? stored) change);

  /// Now on the delegate's clock: its year, month and day are today (such as the server's day for the user's time
  /// zone). The phone's by default.
  DateTime now() => DateTime.now();

  /// Before a restore of [data]: whether it may go ahead, such as once it is paid for. Allowed by default.
  Future<bool> canRestore(StreakData data) async => true;
}
