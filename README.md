# flutter_streak

A simple and flexible Flutter package for tracking daily streaks.  
Useful for habit trackers, learning apps, fitness challenges, or any app that requires consecutive daily actions.

## Features

- 🔥 Track daily streaks with automatic reset if a day is skipped.
- 👥 Support for single-user or multi-contributor streaks.
- 📦 Custom persistence via `StreakDelegate` (local, database, or cloud).
- 📊 Store and retrieve streak count, date, contributors, and history.
- ⏱️ Real-time updates through streams.

## Getting started

Add the dependency in your `pubspec.yaml`:

```yaml
dependencies:
  flutter_streak: ^0.0.1
```

Then run:
```shell
flutter pub get
```

## Usage

Here’s a minimal example:
```dart
import 'package:flutter_streak/flutter_streak.dart';

class MyDelegate extends StreakDelegate {
  Map<String, dynamic>? _store;

  @override
  Future<Map?> get() async => _store;

  @override
  Stream<Map?> listen() async* {
    yield _store;
  }

  @override
  Future<void> set(Map<String, dynamic> props) async {
    _store = props;
  }
}

void main() async {
  await Streak.init(delegate: MyDelegate());

  // Increase streak
  await Streak.update();

  print('Current streak: ${Streak.i.value.count}');
}
```