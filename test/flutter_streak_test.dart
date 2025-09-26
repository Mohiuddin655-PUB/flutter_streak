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
      expect(Streak.i.value.count, countAfterFirst); // should not increment again
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
  });
}
