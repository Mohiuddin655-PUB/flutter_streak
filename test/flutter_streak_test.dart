import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_streak/flutter_streak.dart';

class MockDelegate extends StreakDelegate {
  Map<String, dynamic>? store;

  @override
  Future<Map?> get() async => store;

  @override
  Stream<Map?> listen() async* {
    yield store;
  }

  @override
  Future<void> set(Map<String, dynamic> props) async {
    store = props;
  }
}

class ErrorDelegate extends MockDelegate {
  @override
  Stream<Map?> listen() async* {
    yield* Stream<Map?>.error(StateError('offline'));
    yield {"count": 2, "time": DateTime.now().millisecondsSinceEpoch};
  }
}

class ControlledDelegate extends MockDelegate {
  final _controller = StreamController<Map?>();

  bool get hasListener => _controller.hasListener;

  @override
  Stream<Map?> listen() => _controller.stream;
}

/// A delegate whose clock is [now], not the phone's.
class ClockDelegate extends MockDelegate {
  ClockDelegate(this.now);

  DateTime now;

  @override
  DateTime today() => now;
}

void main() {
  group('Streak', () {
    late MockDelegate delegate;

    setUp(() {
      delegate = MockDelegate();
    });

    test('initial streak is zero', () async {
      await Streak.init(delegate: delegate);
      expect(Streak.i.value.count, 0);
      expect(Streak.i.value.isToday, false);
    });

    test('update increases streak count', () async {
      await Streak.init(delegate: delegate);
      await Streak.update();
      expect(Streak.i.value.count, 1);
      expect(Streak.i.value.isToday, true);
    });

    test('streak does not increase twice in same day', () async {
      await Streak.init(delegate: delegate);
      await Streak.update();
      final countAfterFirst = Streak.i.value.count;
      await Streak.update();
      expect(
        Streak.i.value.count,
        countAfterFirst,
      ); // should not increment again
    });

    test('mergeWith correctly merges map data', () {
      final now = DateTime.now();
      final data = StreakData(1, now);
      final merged = data.mergeWith({
        "count": 5,
        "time": now.millisecondsSinceEpoch,
        "contributes": ["u1"],
        "history": ["2025/9/26"],
      });
      expect(merged.count, 5);
      expect(merged.contributes.contains("u1"), true);
    });

    test('contributable streak resets after a missed day', () async {
      final old = DateTime.now().subtract(const Duration(days: 3));
      delegate.store = {
        "count": 4,
        "time": old.millisecondsSinceEpoch,
        "contributes": ["u1", "u2"],
      };
      await Streak.init(
        delegate: delegate,
        contributable: true,
        uid: "u1",
        contributors: {"u1", "u2"},
      );
      expect(Streak.i.value.count, 0);
    });

    test('contributable streak keeps count from a full yesterday', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      delegate.store = {
        "count": 4,
        "time": yesterday.millisecondsSinceEpoch,
        "contributes": ["u1", "u2"],
      };
      await Streak.init(
        delegate: delegate,
        contributable: true,
        uid: "u1",
        contributors: {"u1", "u2"},
      );
      expect(Streak.i.value.count, 4);
    });

    test('stream error is handled and later events still arrive', () async {
      await Streak.init(delegate: ErrorDelegate());
      await Future<void>.delayed(Duration.zero);
      expect(Streak.i.value.count, 2);
    });

    test('init again stops the old listener', () async {
      final first = ControlledDelegate();
      await Streak.init(delegate: first);
      expect(first.hasListener, true);
      await Streak.init(delegate: MockDelegate());
      expect(first.hasListener, false);
    });

    test('clear stops the listener and drops the streak', () async {
      final delegate = ControlledDelegate();
      delegate.store = {
        "count": 3,
        "time": DateTime.now().millisecondsSinceEpoch,
      };
      await Streak.init(delegate: delegate, uid: "u1");
      expect(Streak.i.value.count, 3);
      await Streak.clear();
      expect(delegate.hasListener, false);
      expect(Streak.i.value.count, 0);
      expect(Streak.i.uid, '');
      expect(Streak.i.loaded, false);
    });

    test('days follow the delegate clock, not the phone', () async {
      final clock = ClockDelegate(DateTime.utc(2030, 1, 10, 23));
      await Streak.init(delegate: clock);
      await Streak.update();
      expect(Streak.i.value.count, 1);
      expect(Streak.i.value.time, DateTime.utc(2030, 1, 10));
      expect(clock.store?['history'], ['2030/1/10']);

      // The same day by the delegate: not counted again, whatever the phone says.
      await Streak.update();
      expect(Streak.i.value.count, 1);

      clock.now = DateTime.utc(2030, 1, 11, 1);
      await Streak.load();
      await Streak.update();
      expect(Streak.i.value.count, 2);
    });

    test('a missed day by the delegate clock resets the streak', () async {
      final clock = ClockDelegate(DateTime.utc(2030, 1, 13));
      clock.store = StreakData(5, DateTime.utc(2030, 1, 10)).props;
      await Streak.init(delegate: clock);
      expect(Streak.i.value.count, 0);
    });

    test('yesterday by the delegate clock keeps the streak', () async {
      final clock = ClockDelegate(DateTime.utc(2030, 1, 11, 6));
      clock.store = StreakData(5, DateTime.utc(2030, 1, 10)).props;
      await Streak.init(delegate: clock);
      expect(Streak.i.value.count, 5);
    });
  });
}
