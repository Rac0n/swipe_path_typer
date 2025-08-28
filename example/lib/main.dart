import 'package:flutter/material.dart';
import 'package:swipe_path_typer/swipe_path_typer.dart';

import 'custom_tile_button.dart';

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

class SwipeDemoHome extends StatefulWidget {
  const SwipeDemoHome({super.key});

  @override
  State<SwipeDemoHome> createState() => _SwipeDemoHomeState();
}

class _SwipeDemoHomeState extends State<SwipeDemoHome> {
  bool simpleTapMode = false;

  @override
  Widget build(BuildContext context) {
    final letters = ['W', 'O', 'R', 'D', 'S', 'P', 'L', 'I', 'T', 'E'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("SwipePathTyper Demo"),
        actions: [
          Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  Text(
                    "Select Mode:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(simpleTapMode ? 'TAP' : 'SWIPE'),
                    backgroundColor: simpleTapMode
                        ? Colors.teal.withAlpha(50)
                        : Colors.grey.withAlpha(50),
                  ),
                  Switch(
                    value: simpleTapMode,
                    onChanged: (value) {
                      setState(() {
                        simpleTapMode = value;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(value
                              ? 'Tap mode activated'
                              : 'Swipe mode activated'),
                          duration: const Duration(milliseconds: 800),
                        ),
                      );
                    },
                  )
                ],
              ))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              simpleTapMode
                  ? 'Tap letters to form words (quick single-tap input)'
                  : 'Swipe across letters to form a word! (gesture typing)',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SwipePathTyper(
                simpleTapMode: simpleTapMode,
                tiles: letters,
                tileBuilder: (context, letter, isSelected) => CustomTileButton(
                  letter: letter,
                  isSelected: isSelected,
                ),
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
