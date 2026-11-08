import 'dart:async' show StreamSubscription;

import 'package:flutter/foundation.dart';

import 'delegates/streak_delegate.dart';
import 'enums/streak_mode.dart';
import 'enums/streak_restore_result.dart';
import 'helpers/streak_days.dart';
import 'helpers/streak_rules.dart';
import 'models/streak_data.dart';

/// The streak, shared by the whole app: [value] at once from any screen, as it stands today. [init] it for whoever
/// keeps it ([member], alone or in a team), and [clear] it when they leave. One instance for good, so listeners stay
/// across sign-ins.
class Streak extends ValueNotifier<StreakData> {
  Streak._() : super(StreakData.empty);

  static final i = Streak._();

  StreakDelegate? _delegate;
  String _member = '';
  Set<String> _members = const {};
  StreakMode _mode = StreakMode.single;
  StreamSubscription<Map<String, dynamic>?>? _sub;

  /// Each init or clear: a write begun before it is let go.
  int _generation = 0;

  /// The streak as stored; [value] is it as it stands today.
  StreakData _stored = StreakData.empty;

  /// Asked once at a time: a second caller waits for the first.
  Future<bool>? _updating;

  StreakMode get mode => _mode;
  Set<String> get members => _members;

  /// Today's key on the delegate's clock.
  String get today => StreakDays.key(_delegate?.now() ?? DateTime.now());

  /// Starts the streak of [member], alone ([StreakMode.single]) or in a team of [members] ([StreakMode.team]): the
  /// delegate's copy at once, then each change it hears.
  void init({
    required StreakDelegate delegate,
    required String member,
    StreakMode mode = StreakMode.single,
    Set<String> members = const {},
  }) {
    _stop();
    _delegate = delegate;
    _member = member;
    _mode = mode;
    _members = mode == StreakMode.single ? {member} : {...members, member};
    _show(StreakData.parse(delegate.cached()));
    final generation = _generation;
    _sub = delegate.listen().listen((stored) {
      if (generation == _generation) _show(StreakData.parse(stored));
    }, onError: (Object _) {});
  }

  /// The team changed: the days from now on count it.
  set members(Set<String> members) {
    if (_mode == StreakMode.team) _members = {...members, _member};
  }

  /// Stops it and drops the streak, such as on sign-out.
  void clear() {
    _stop();
    _delegate = null;
    _member = '';
    _members = const {};
    _mode = StreakMode.single;
    _show(StreakData.empty);
  }

  /// A day may have passed (such as back from the background): shows the streak as it stands now.
  void refresh() => _show(_stored);

  /// Calls [listener] with the latest streak each time it changes; the returned function stops it.
  VoidCallback on(void Function(StreakData latest) listener) {
    void changed() => listener(value);
    addListener(changed);
    return () => removeListener(changed);
  }

  /// This member completed today; whether the streak changed.
  Future<bool> update() {
    return _updating ??= _write(
      (data, day) => StreakRules.complete(data, day, _member, _members, _mode),
    ).whenComplete(() => _updating = null);
  }

  /// In a team, this member was active today without completing it; whether it was kept.
  Future<bool> active() async {
    if (_mode != StreakMode.team) return false;
    return _write((data, day) => StreakRules.active(data, day, _member, _members));
  }

  /// Brings the last streak back, once the delegate allows it ([StreakDelegate.canRestore]).
  Future<StreakRestoreResult> restore() async {
    final delegate = _delegate;
    if (delegate == null || !value.restorable) return StreakRestoreResult.unavailable;
    if (!await delegate.canRestore(value)) return StreakRestoreResult.declined;
    return await _write(StreakRules.restore) ? StreakRestoreResult.restored : StreakRestoreResult.failed;
  }

  Future<bool> _write(StreakData? Function(StreakData data, String day) change) async {
    final delegate = _delegate;
    if (delegate == null || _member.isEmpty) return false;
    final generation = _generation, day = today;
    // Nothing to change on the streak as last heard: no write.
    if (change(_stored, day) == null) return false;
    var changed = false;
    try {
      final stored = await delegate.write((stored) {
        final next = change(StreakData.parse(stored), day);
        changed = next != null;
        return next?.toMap();
      });
      if (generation == _generation) _show(StreakData.parse(stored));
      return changed;
    } catch (_) {
      return false;
    }
  }

  void _show(StreakData stored) {
    _stored = stored;
    value = StreakRules.settle(stored, today);
  }

  void _stop() {
    _generation++;
    _sub?.cancel();
    _sub = null;
    _updating = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }
}
