import 'package:flutter/material.dart';
import 'package:flutter_streak/flutter_streak.dart';

/// A simple in-memory delegate (no database, just stores in memory).
class MemoryDelegate extends StreakDelegate {
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
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize streak system with in-memory delegate
  await Streak.init(delegate: MemoryDelegate());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Streak Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const StreakPage(),
    );
  }
}

class StreakPage extends StatefulWidget {
  const StreakPage({super.key});

  @override
  State<StreakPage> createState() => _StreakPageState();
}

class _StreakPageState extends State<StreakPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Streak Example')),
      body: Center(
        child: ValueListenableBuilder<StreakData>(
          valueListenable: Streak.i,
          builder: (context, streak, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "🔥 Current Streak: ${streak.count}",
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 12),
                Text("Last updated: ${streak.time}"),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await Streak.update();
                  },
                  child: const Text("Add Today"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
