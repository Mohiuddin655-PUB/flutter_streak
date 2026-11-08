import 'dart:async';

import 'package:flutter/foundation.dart';

class StreakData {
  final int count;
  final DateTime time;
  final Set<String> contributes;
  final Set<String> history;

  const StreakData(
    this.count,
    this.time, {
    this.contributes = const {},
    this.history = const {},
  });

  /// [moment]'s calendar day as a UTC date, so days compare the same in any time zone.
  static DateTime dayOf(DateTime moment) =>
      DateTime.utc(moment.year, moment.month, moment.day);

  /// [time] falls on [today]'s day.
  bool isTodayOn(DateTime today) => dayOf(time) == dayOf(today);

  /// [time] falls on [today]'s day or the day before: the streak still runs.
  bool isAliveOn(DateTime today) {
    final day = dayOf(time), now = dayOf(today);
    return day == now || day == now.subtract(const Duration(days: 1));
  }

  /// By the phone's clock; [Streak] uses [StreakDelegate.today].
  bool get isToday => isTodayOn(DateTime.now());

  /// By the phone's clock; [Streak] uses [StreakDelegate.today].
  bool get isYesterdayOrToday => isAliveOn(DateTime.now());

  StreakData.initial()
    : count = 0,
      time = DateTime.utc(0),
      contributes = {},
      history = {};

  StreakData copyWith({
    int? count,
    DateTime? time,
    Set<String>? contributes,
    Set<String>? history,
  }) {
    return StreakData(
      count ?? this.count,
      time ?? this.time,
      contributes: contributes ?? this.contributes,
      history: history ?? this.history,
    );
  }

  StreakData mergeWith(Object? source) {
    if (source is! Map) return this;
    final count = source['count'];
    final time = source['time'];
    final contributes = source['contributes'];
    final history = source['history'];
    return copyWith(
      count: count is num ? count.toInt() : null,
      time: time is num
          ? DateTime.fromMillisecondsSinceEpoch(time.toInt(), isUtc: true)
          : null,
      contributes: contributes is List
          ? contributes
                .map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toSet()
          : null,
      history: history is List
          ? history.map((e) => e.toString()).where((e) => e.isNotEmpty).toSet()
          : null,
    );
  }

  factory StreakData.parse(Object? source) {
    if (source is! Map) return StreakData.initial();
    final count = source['count'];
    final time = source['time'];
    final contributes = source['contributes'];
    final history = source['history'];
    return StreakData(
      count is num ? count.toInt() : 0,
      time is num
          ? DateTime.fromMillisecondsSinceEpoch(time.toInt(), isUtc: true)
          : DateTime.utc(0),
      contributes: contributes is List
          ? contributes
                .map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toSet()
          : {},
      history: history is List
          ? history.map((e) => e.toString()).where((e) => e.isNotEmpty).toSet()
          : {},
    );
  }

  Map<String, dynamic> get props {
    return {
      "count": count,
      "time": time.millisecondsSinceEpoch,
      if (contributes.isNotEmpty) "contributes": contributes.toList(),
      if (history.isNotEmpty) "history": history.toList(),
    };
  }

  @override
  int get hashCode =>
      count.hashCode ^ time.hashCode ^ contributes.hashCode ^ history.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is StreakData &&
        other.count == count &&
        other.time == time &&
        other.contributes == contributes &&
        other.history == history;
  }

  @override
  String toString() => "$StreakData($count)";
}

abstract class StreakDelegate {
  Future<Map?> get();

  Stream<Map?> listen();

  Future<void> set(Map<String, dynamic> props);

  /// Now, by the clock the streak's days are counted on; its calendar day is the day. The phone's clock unless a
  /// delegate gives a trusted one (such as the server's).
  DateTime today() => DateTime.now();
}

class Streak extends ValueNotifier<StreakData> {
  final bool contributable;
  final StreakDelegate _delegate;
  String uid = '';
  Set<String> contributors = {};

  bool loaded = false;

  Streak._(this.contributable, this._delegate) : super(StreakData.initial());

  bool get _isSingle => uid.isEmpty || contributors.length <= 1;

  static Streak? _i;

  static Streak get i => _i!;

  static StreakData _normalized(StreakData v) {
    final today = i._delegate.today();
    if (v.isTodayOn(today)) return v;
    // A missed day breaks the streak, even when the last day was fully contributed.
    var alive = v.isAliveOn(today);
    if (i.contributable) {
      alive = alive && i.contributors.every(v.contributes.contains);
    }
    return v.copyWith(contributes: {}, count: alive ? null : 0);
  }

  static Future<void> _callbackHandler(AsyncCallback callback) async {
    try {
      if (_i == null) return;
      if (i.contributable && i._isSingle) return;
      if (!i.loaded) await load();
      await callback();
    } catch (_) {}
  }

  static Future<void> init({
    required StreakDelegate delegate,
    bool contributable = false,
    String? uid,
    Set<String>? contributors,
  }) async {
    try {
      // Only the stream is stopped: widgets may still hold the old notifier.
      await _i?._sub?.cancel();
      _i = Streak._(contributable, delegate);
      if (uid != null) i.uid = uid;
      if (contributors != null) i.contributors = contributors;
      if (!(i.contributable && i._isSingle)) await load();
      listen();
    } catch (_) {}
  }

  static Future<void> reset({String? uid, Set<String>? contributors}) async {
    if (_i == null) return;
    if (uid != null) i.uid = uid;
    if (contributors != null) i.contributors = contributors;
    try {
      i.value = StreakData.initial();
      await load();
      listen();
    } catch (_) {}
  }

  /// Signed out: stops listening and drops the streak, until [init] starts it again.
  static Future<void> clear() async {
    if (_i == null) return;
    try {
      await i._sub?.cancel();
    } catch (_) {}
    i._sub = null;
    i.uid = '';
    i.contributors = {};
    i.loaded = false;
    i.value = StreakData.initial();
  }

  static void applyUid(String uid) {
    if (_i == null) return;
    i.uid = uid;
  }

  static Future<void> applyContributors(Set<String> contributors) async {
    if (_i == null) return;
    i.contributors = contributors;
    await load();
  }

  static Future<void> load() async {
    if (_i == null) return;
    try {
      await i._delegate.get().then(StreakData.parse).then((value) {
        i.value = _normalized(value);
        i.loaded = true;
      });
    } catch (_) {}
  }

  StreamSubscription? _sub;

  static Future<void> listen() async {
    if (_i == null) return;
    try {
      i._sub?.cancel();
      i._sub = i._delegate.listen().map(StreakData.parse).listen(
        (value) {
          i.value = _normalized(value);
          i.loaded = true;
        },
        // A failed event keeps the last value; later events still arrive.
        onError: (Object _) {},
      );
    } catch (_) {}
  }

  static Future<void> update() async {
    return _callbackHandler(() async {
      StreakData v = i.value;
      final today = i._delegate.today();
      final date = StreakData.dayOf(today);
      final day = "${date.year}/${date.month}/${date.day}";
      if (!i._isSingle) {
        if (v.contributes.contains(i.uid)) return;
        final contributes = {i.uid, ...v.contributes};
        final increase = i.contributors.every(contributes.contains);
        i.value = v.copyWith(
          count: increase ? v.count + 1 : null,
          time: date,
          contributes: {i.uid, ...v.contributes},
          history: {...v.history, day},
        );
      } else {
        if (v.isTodayOn(today)) return;
        i.value = v.copyWith(
          count: v.count + 1,
          time: date,
          history: {...v.history, day},
        );
      }
      await i._delegate.set(i.value.props);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
