import 'package:flutter/material.dart';
import 'package:swipe_path_typer/main.dart';

void main() {
  runApp(const SwipeDemoApp());
}

class SwipeDemoApp extends StatelessWidget {
  const SwipeDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swipe Path Typer Demo',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const SwipeDemoHome(),
    );
  }
}

class SwipeDemoHome extends StatelessWidget {
  const SwipeDemoHome({super.key});

  @override
  Widget build(BuildContext context) {
    final letters = ['W', 'O', 'R', 'D', 'S', 'P', 'L', 'I', 'T', 'E'];

    return Scaffold(
      appBar: AppBar(title: const Text("SwipePathTyper Demo")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Swipe across letters to form a word!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SwipePathTyper(
                tiles: letters,
                onWordCompleted: (word) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('You swiped: $word')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
