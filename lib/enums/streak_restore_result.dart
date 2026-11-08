/// How a restore ended.
enum StreakRestoreResult {
  /// The last streak is back.
  restored,

  /// There is no broken streak to restore.
  unavailable,

  /// The delegate didn't allow it (such as an unpaid restore).
  declined,

  /// It couldn't be written.
  failed,
}
