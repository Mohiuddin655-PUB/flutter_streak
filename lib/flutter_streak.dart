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

  bool get isToday {
    final now = DateTime.now();
    return now.day == time.day &&
        now.month == time.month &&
        now.year == time.year;
  }

  bool get isYesterdayOrToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(time.year, time.month, time.day);
    final value = checkDate == today || checkDate == yesterday;
    return value;
  }

  StreakData.initial()
    : count = 0,
      time = DateTime(0),
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
          ? DateTime.fromMillisecondsSinceEpoch(time.toInt())
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
          ? DateTime.fromMillisecondsSinceEpoch(time.toInt())
          : DateTime(0),
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
    if (v.isToday) return v;
    if (i.contributable) {
      final contributed = i.contributors.every(v.contributes.contains);
      return v.copyWith(contributes: {}, count: !contributed ? 0 : null);
    }
    return v.copyWith(contributes: {}, count: !v.isYesterdayOrToday ? 0 : null);
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
      i._sub = i._delegate.listen().map(StreakData.parse).listen((value) {
        i.value = _normalized(value);
        i.loaded = true;
      });
    } catch (_) {}
  }

  static Future<void> update() async {
    return _callbackHandler(() async {
      StreakData v = i.value;
      if (!i._isSingle) {
        if (v.contributes.contains(i.uid)) return;
        final contributes = {i.uid, ...v.contributes};
        final increase = i.contributors.every(contributes.contains);
        final date = DateTime.now();
        i.value = v.copyWith(
          count: increase ? v.count + 1 : null,
          time: date,
          contributes: {i.uid, ...v.contributes},
          history: {...v.history, "${date.year}/${date.month}/${date.day}"},
        );
      } else {
        if (v.isToday) return;
        final date = DateTime.now();
        i.value = v.copyWith(
          count: v.count + 1,
          time: date,
          history: {...v.history, "${date.year}/${date.month}/${date.day}"},
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
