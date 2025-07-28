// src/swipe_path_typer_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swipe_path_typer/swipe_path_typer.dart';

class SwipePathTyper extends StatefulWidget {
  final List<String> tiles;
  final ValueChanged<String> onWordCompleted;
  final TileBuilder? tileBuilder;
  final int columnCount;
  final bool simpleTapMode;
  final double horizontalTileSpacing;
  final double verticalTileSpacing;
  final EdgeInsets padding;
  final AlignmentGeometry alignment;
  final Function(DragUpdateDetails)? onPanUpdate;
  final Function(DragEndDetails)? onPanEnd;
  final Function(int tileIndex)? onTapDown;
  final Function(int tileIndex)? onTapUp;
  final HitTestBehavior widgetHitTestBehavior;
  final HitTestBehavior tileHitTestBehavior;
  final SystemMouseCursor tileCursor;
  final Color swipeTrailColor;
  final double swipeTrailStrokeWidth;

  /// A customizable swipe-typing widget, similar to Android's keyboard-style gesture typing.
  /// Automatically detects gestures, sharp turns, and taps on letter tiles.
  const SwipePathTyper({
    super.key,

    /// The list of letters to display as swipeable tiles.
    required this.tiles,

    /// Called when the swipe or tap gesture completes and forms a valid word.
    required this.onWordCompleted,

    /// Optional custom builder for rendering tiles.
    this.tileBuilder,

    /// Number of tiles per row. Defaults to 5.
    this.columnCount = 5,

    /// Spacing between tiles horizontally. Defaults to 8.0.
    this.horizontalTileSpacing = 8.0,

    /// Spacing between tiles vertically. Defaults to 8.0.
    this.verticalTileSpacing = 8.0,

    /// Padding around the entire swipe area. Defaults to EdgeInsets.all(0.0).
    this.padding = const EdgeInsets.all(0.0),

    /// Alignment of the tiles within the swipe area. Defaults to Alignment.bottomCenter.
    this.alignment = Alignment.bottomCenter,

    /// If true, a single tap will immediately submit a word.
    this.simpleTapMode = true,

    /// Callback for pan updates, providing DragUpdateDetails.
    this.onPanUpdate,

    /// Callback for pan end events, providing DragEndDetails.
    this.onPanEnd,

    /// Callback for tap down events on tiles, providing the index of the tapped tile.
    this.onTapDown,

    /// Callback for tap up events on tiles, providing the index of the tapped tile.
    this.onTapUp,

    /// HitTestBehavior for the entire widget, defaults to HitTestBehavior.translucent.
    this.widgetHitTestBehavior = HitTestBehavior.translucent,

    /// HitTestBehavior for each tile, defaults to HitTestBehavior.translucent.
    this.tileHitTestBehavior = HitTestBehavior.translucent,

    /// Mouse cursor to use when hovering over tiles, defaults to SystemMouseCursors.click.
    this.tileCursor = SystemMouseCursors.click,

    /// Color of the swipe trail, defaults to Colors.black87.
    this.swipeTrailColor = Colors.black87,

    /// Stroke width of the swipe trail, defaults to 8.0.
    this.swipeTrailStrokeWidth = 8.0,
  });

  @override
  State<SwipePathTyper> createState() => _SwipePathTyperState();
}

typedef TileBuilder = Widget Function(
    BuildContext context, String letter, bool isSelected);

class _SwipePathTyperState extends State<SwipePathTyper> {
  /// The controller that manages the swipe path state.
  late SwipePathController _controller;

  /// Indicates whether the tile rectangles have been initialized.
  bool _tileRectsInitialized = false;

  /// Flag to ensure tile keys are initialized only once.
  bool firstBuild = true;

  /// List of keys for each tile to access their global positions.
  late List<GlobalKey> _tileKeys;

  /// A key for the painter to ensure it can be referenced in the widget tree.
  final GlobalKey _painterKey = GlobalKey();

  /// Initializes the state and sets up the controller and tile keys.
  @override
  void initState() {
    super.initState();
    if (firstBuild) {
      firstBuild = false;
      _tileKeys = List.generate(widget.tiles.length, (_) => GlobalKey());
    } else if (_tileKeys.length != widget.tiles.length) {
      _tileKeys = List.generate(widget.tiles.length, (_) => GlobalKey());
      _tileRectsInitialized = false;
    }

    _controller =
        SwipePathController(widget.tiles, simpleTapMode: widget.simpleTapMode);
  }

  /// Disposes the controller when the widget is removed from the widget tree.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Registers all tile rectangles after the first frame is rendered.
  void _registerAllTileRects(

      /// The build context for the widget.
      BuildContext context) {
    for (int i = 0; i < widget.tiles.length; i++) {
      final key = _tileKeys[i];
      final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final position = renderBox.localToGlobal(Offset.zero);
        final rect = position & renderBox.size;
        _controller.registerTileRect(i, rect);
      }
    }
    _tileRectsInitialized = true;
  }

  /// Updates the tile rectangles if the widget is rebuilt with a different number of tiles.
  @override
  void didUpdateWidget(

      /// The previous widget to compare against.
      covariant SwipePathTyper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tiles.length != widget.tiles.length) {
      _tileRectsInitialized = false;
      _tileKeys = List.generate(widget.tiles.length, (_) => GlobalKey());
    }
  }

  /// Builds the widget tree for the swipe path typer.
  @override
  Widget build(

      /// The build context for the widget.
      BuildContext context) {
    return GestureDetector(
        key: _painterKey,
        behavior: widget.widgetHitTestBehavior,
        onPanUpdate: (details) {
          _controller.updateSwipe(details.globalPosition, setState);
          widget.onPanUpdate?.call(details);
        },
        onPanEnd: (details) {
          final word = _controller.endSwipe(details.globalPosition, setState);
          widget.onPanEnd?.call(details);

          if (word.isNotEmpty) {
            widget.onWordCompleted(word);
          }
          setState(() {});
        },
        child: Stack(children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final tileCount = widget.tiles.length;
              final tilesPerRow = widget.columnCount;
              final availableWidth = constraints.maxWidth -
                  1 -
                  widget.padding.left -
                  widget.padding.right -
                  (widget.horizontalTileSpacing * (tilesPerRow - 1));
              final tileWidth = availableWidth / tilesPerRow;
              if (!_tileRectsInitialized) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _registerAllTileRects(context);
                });
              }

              return Container(
                  alignment: widget.alignment,
                  padding: widget.padding,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: widget.horizontalTileSpacing,
                    runSpacing: widget.verticalTileSpacing,
                    children: List.generate(tileCount, (i) {
                      return Builder(
                        builder: (tileContext) {
                          final isSelected =
                              _controller.selectedIndexes.contains(i);
                          final letter = widget.tiles[i];
                          final defaultTile = SwipePathTile(
                              letter: letter, isSelected: isSelected);

                          return SizedBox(
                              key: _tileKeys[i],
                              width: tileWidth,
                              child: MouseRegion(
                                hitTestBehavior: widget.tileHitTestBehavior,
                                cursor: widget.tileCursor,
                                child: GestureDetector(
                                  onTapDown: (_) {
                                    _controller.onTileTapDown(i, setState);
                                        widget.onTapDown?.call(i);
                                        if (widget.simpleTapMode) {
                                          final word =
                                              _controller.getCurrentWord();
                                          if (word.isNotEmpty) {
                                            widget.onWordCompleted(word);
                                          }
                                        }
                                      },
                                      onTapUp: (_) {
                                        bool result = _controller.onTileTapUp(
                                            i, setState);
                                        widget.onTapUp?.call(i);

                                        if (result) {
                                          String word =
                                              _controller.getCurrentWord();
                                          if (word.isNotEmpty) {
                                            widget.onWordCompleted(word);
                                          }
                                        }
                                      },
                                      child: widget.tileBuilder
                                      ?.call(tileContext, letter, isSelected) ??defaultTile,
                                    ),
                                  ));
                        },
                      );
                    }),
                  ));
            },
          ),
          IgnorePointer(
            child: Builder(
              builder: (context) {
                final renderBox = _painterKey.currentContext?.findRenderObject()
                    as RenderBox?;
                if (renderBox == null) return const SizedBox.shrink();

                final localPoints = _controller.swipeTrail
                    .map((globalPoint) => renderBox.globalToLocal(globalPoint))
                    .toList();

                return CustomPaint(
                  painter: SwipeTrailPainter(
                    points: localPoints,
                    color: widget.swipeTrailColor,
                    strokeWidth: widget.swipeTrailStrokeWidth,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
        ]));
  }
}
