// src/swipe_path_typer_widget.dart
import 'package:flutter/material.dart';
import 'package:swipe_path_typer/main.dart';

class SwipePathTyper extends StatefulWidget {
  final List<String> tiles;
  final ValueChanged<String> onWordCompleted;
  final TileBuilder? tileBuilder;
  final int rowCount;
  final bool smartDetection;


  const SwipePathTyper({
    super.key,
    required this.tiles,
    required this.onWordCompleted,
    this.tileBuilder,
    this.rowCount = 2,
    this.smartDetection = true,
  });

  @override
  State<SwipePathTyper> createState() => _SwipePathTyperState();
}

typedef TileBuilder = Widget Function(BuildContext context, String letter, bool isSelected);

class _SwipePathTyperState extends State<SwipePathTyper> {
  late SwipePathController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SwipePathController(widget.tiles, smartDetection: widget.smartDetection);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (details) => _controller.startSwipe(),
        onPanUpdate: (details) => _controller.updateSwipe(details.globalPosition, setState),
        onPanEnd: (_) {
          final word = _controller.endSwipe();
          if (word.isNotEmpty) {
            widget.onWordCompleted(word);
          }
          setState(() {});
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final tileCount = widget.tiles.length;
            final tilesPerRow = (tileCount / widget.rowCount).ceil();

            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: List.generate(tileCount, (i) {
                return Builder(
                  builder: (tileContext) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final box = tileContext.findRenderObject() as RenderBox?;
                      if (box != null && box.hasSize) {
                        final position = box.localToGlobal(Offset.zero);
                        final rect = position & box.size;
                        _controller.registerTileRect(i, rect);
                      }
                    });

                    final isSelected = _controller.selectedIndexes.contains(i);
                    final letter = widget.tiles[i];
                    final defaultTile = SwipePathTile(letter: letter, isSelected: isSelected);

                    return SizedBox(
                        width: width / tilesPerRow - 8,
                        child: widget.tileBuilder?.call(tileContext, letter, isSelected) ?? MouseRegion(
                        onEnter: (_) => _controller.onTileEnter(i, setState),
                        onExit: (event) => _controller.onTileExit(i),
                        opaque: false,
                          child: GestureDetector(
                            onTapDown: (_) => _controller.onTileTapDown(i, setState),
                            child: defaultTile,
                          )
                        )
                      );
                  },
                );
              }),
            );
          },
        ),
      );
  }
}
