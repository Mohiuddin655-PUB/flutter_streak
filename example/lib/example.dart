import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_streak/flutter_streak.dart';

/// Keeps the streak in memory only.
class MemoryDelegate extends StreakDelegate {
  Map<String, dynamic>? _stored;
  final _changes = StreamController<Map<String, dynamic>?>.broadcast();

  @override
  Map<String, dynamic>? cached() => _stored;

  @override
  Stream<Map<String, dynamic>?> listen() => _changes.stream;

  @override
  Future<Map<String, dynamic>?> write(Map<String, dynamic>? Function(Map<String, dynamic>? stored) change) async {
    final next = change(_stored);
    if (next == null) return _stored;
    _changes.add(_stored = next);
    return next;
  }
}

void main() {
  Streak.i.init(delegate: MemoryDelegate(), member: 'me');
  runApp(const MaterialApp(home: StreakPage()));
}

class StreakPage extends StatelessWidget {
  const StreakPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ValueListenableBuilder(
          valueListenable: Streak.i,
          builder: (context, streak, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${streak.count}', style: Theme.of(context).textTheme.displayLarge),
              Text('Best ${streak.best}'),
              if (streak.restorable) TextButton(onPressed: Streak.i.restore, child: Text('Restore ${streak.last}')),
              FilledButton(onPressed: Streak.i.update, child: const Text('Complete today')),
            ],
          ),
        ),
      ),
    );
  }
}
