import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class SwipePathController {
  /// The list of letters to display as swipeable tiles.
  final List<String> _tiles;

  /// A set of currently selected tile indexes.
  final Set<int> selectedIndexes = {};

  /// A map of tile indexes to their rectangle bounds.
  final Map<int, Rect> _tileRects = {};

  /// A list of indexes representing the swipe path.
  final List<int> _swipePath = [];

  /// A list of points representing the swipe trail.
  final List<Offset> _swipePoints = [];

  /// If true, a single tap will immediately submit a word.
  final bool simpleTapMode;

  /// Called when the swipe or tap gesture selects a letter.
  final ValueChanged<String>? onLetterSelected;

  /// A list of points representing the swipe trail.
  List<Offset> get swipeTrail => List.unmodifiable(_swipePoints);

  /// A list of points used to lock tiles during swipes.
  final Set<int> _lockedTiles = {};

  /// The index of the currently hovered tile.
  int? _hoveredTileIndex;

  /// The index of the currently hovered selected tile.
  int? _hoveredSelectedTile;

  /// Indicates if the swipe gesture is currently pressed down.
  bool _downPressed = false;

  /// A timer duration for handling dwell time before unselecting a tile.
  static const Duration _cleanupDelay = Duration(milliseconds: 200);

  /// The minimum delay before a tile is selected when hovered onto.
  static const Duration _minSwipeTurnDelay = Duration(milliseconds: 420);

  /// The maximum number of swipe points to keep in memory.
  static const int _maxSwipePoints = 69;

  /// A list of timers controlling the dwelling time to select a tile, for each of the tiles
  List<Timer> _dwellTimers = [];

  /// A list of timers controlling the cleanup delay for each tile.
  List<Timer> _cleanupTimers = [];

  /// Creates a controller for managing swipe path typing.
  SwipePathController(

      /// The list of letters to display as swipeable tiles.
      this._tiles,

      /// Called when the swipe or tap gesture selects a letter.
      this.onLetterSelected,

      /// If true, a single tap will immediately submit a word.
      {this.simpleTapMode = true}) {
    _dwellTimers =
        List.generate(_tiles.length, (_) => Timer(_minSwipeTurnDelay, () {}));
    _cleanupTimers =
        List.generate(_tiles.length, (_) => Timer(_cleanupDelay, () {}));
  }

  /// Adds a swipe point to the internal list, maintaining a maximum length.
  void _addSwipePoint(

      /// The point to add to the swipe trail.
      Offset point) {
    // Only add point if it's significantly different from last point
    if (_swipePoints.isEmpty || (_swipePoints.last - point).distance > 2.0) {
      if (_swipePoints.length >= _maxSwipePoints) {
        _swipePoints.removeAt(0);
      }
      _swipePoints.add(point);
    }
  }

  /// Resets the controller's state, optionally clearing all data.
  void _resetState(

      /// If true, clears all selected tiles but also sets _downPressed to false and cancels the dwell timer.
      bool fullReset,

      /// If true, rebuilds the widget tree after resetting.
      bool rebuild,

      /// A function to trigger a rebuild of the widget tree.
      void Function(VoidCallback) triggerRebuild) {
    selectedIndexes.clear();
    _swipePath.clear();
    _swipePoints.clear();
    _lockedTiles.clear();
    _hoveredTileIndex = null;
    _hoveredSelectedTile = null;
    for (var ctimer in _cleanupTimers) {
      ctimer.cancel();
    }

    if (fullReset) {
      _downPressed = false;
      for (var timer in _dwellTimers) {
        timer.cancel();
      }
    }
    if (rebuild) {
      triggerRebuild(() {});
    }
  }

  int onPanStart(

      /// The global position of the tap.
      Offset globalPosition,

      /// A function to trigger a rebuild of the widget tree.
      void Function(VoidCallback) triggerRebuild) {
    if (_downPressed) return -1;
    _resetState(true, false, triggerRebuild);

    _downPressed = true;
    _addSwipePoint(globalPosition);
    triggerRebuild(() {});

    int defaultIndex = -1;

    for (var entry in _tileRects.entries) {
      final index = entry.key;
      final rect = entry.value;

      if (!rect.contains(globalPosition)) continue;
      if (_lockedTiles.contains(index)) continue;

      selectedIndexes.add(index);

      _swipePath.add(index);
      onLetterSelected?.call(_tiles[index]);

      _lockedTiles.add(index);
      _hoveredSelectedTile = index;
      triggerRebuild(() {});

      if (simpleTapMode) {
        _cleanupTimers[index] = Timer(_cleanupDelay, () {
          if (simpleTapMode && _hoveredSelectedTile != null) {
            _lockedTiles.remove(_hoveredSelectedTile!);
            selectedIndexes.remove(_hoveredSelectedTile);
            _hoveredSelectedTile = null;
            triggerRebuild(() {});

            // Clean up state
            _resetState(true, false, triggerRebuild);
          }
        });
      }
      return index;
    }

    return defaultIndex;
  }

  /// Initializes the tile rectangles after the first build.
  void onTileTapDown(

      /// The index of the tile that was tapped.
      int index,

      /// The global position of the tap.
      Offset globalPosition,

      /// A function to trigger a rebuild of the widget tree.
      void Function(VoidCallback) triggerRebuild) {
    if (_downPressed) return;
    _resetState(true, false, triggerRebuild);

    _downPressed = true;
    selectedIndexes.add(index);
    _swipePath.add(index);
    onLetterSelected?.call(_tiles[index]);
    _lockedTiles.add(index);
    _addSwipePoint(globalPosition);
    _hoveredSelectedTile = index;
    triggerRebuild(() {});

    if (simpleTapMode) {
      _cleanupTimers[index] = Timer(_cleanupDelay, () {
        if (simpleTapMode && _hoveredSelectedTile != null) {
          _lockedTiles.remove(_hoveredSelectedTile!);
          selectedIndexes.remove(_hoveredSelectedTile);
          _hoveredSelectedTile = null;
          triggerRebuild(() {});

          // Clean up state
          _resetState(true, false, triggerRebuild);
        }
      });
    }
  }

  /// Updates the swipe path based on the current global position.
  void updateSwipe(

      /// The current global position of the swipe gesture.
      Offset globalPosition,

      /// A function to trigger a rebuild of the widget tree.
      void Function(VoidCallback) triggerRebuild) {
    if (!_downPressed || simpleTapMode) return;

    _addSwipePoint(globalPosition);

    // Unlock selected tile when finger leaves it
    if (_hoveredSelectedTile != null) {
      final rect = _tileRects[_hoveredSelectedTile!];
      if (rect != null && !rect.contains(globalPosition)) {
        _lockedTiles.remove(_hoveredSelectedTile!);
        selectedIndexes.remove(_hoveredSelectedTile);
        _hoveredSelectedTile = null;
        triggerRebuild(() {});

        return;
      }
    }

    for (var entry in _tileRects.entries) {
      final index = entry.key;
      final rect = entry.value;

      if (!rect.contains(globalPosition)) continue;
      if (_lockedTiles.contains(index)) continue;

      // Dwell trigger
      if (_hoveredTileIndex != index) {
        _hoveredTileIndex = index;
        _dwellTimers[index].cancel();
        _dwellTimers[index] = Timer(_minSwipeTurnDelay, () {
          if (_hoveredTileIndex == index && !_lockedTiles.contains(index)) {
            selectedIndexes.add(index);
            _swipePath.add(index);
            onLetterSelected?.call(_tiles[index]);
            _lockedTiles.add(index);
            _hoveredSelectedTile = index;
            triggerRebuild(() {});
          }
        });
        break;
      }

      // Sharp turn detection
      final sharpTurn = _isSharpTurnNear(index);
      if (sharpTurn) {
        _dwellTimers[index].cancel();
        _hoveredTileIndex = null;
        selectedIndexes.add(index);
        _swipePath.add(index);
        onLetterSelected?.call(_tiles[index]);
        _lockedTiles.add(index);
        _hoveredSelectedTile = index;
        _addSwipePoint(globalPosition);
        triggerRebuild(() {});
        break;
      }
    }
  }

  /// Ends the swipe and returns the current word formed by the swipe path.
  String getCurrentWord() {
    return _swipePath.map((i) => _tiles[i]).join();
  }

  /// Ends the swipe and returns the current word formed by the swipe path.
  String endSwipe(

      /// The global position where the swipe ended.
      Offset globalPosition,

      /// A function to trigger a rebuild of the widget tree.
      void Function(VoidCallback) triggerRebuild) {
    if (!_downPressed) return '';

    _addSwipePoint(globalPosition);

    for (var entry in _tileRects.entries) {
      final index = entry.key;
      final rect = entry.value;

      if (!rect.contains(globalPosition)) continue;
      if (_lockedTiles.contains(index)) continue;

      selectedIndexes.add(index);
      _swipePath.add(index);
      onLetterSelected?.call(_tiles[index]);
      triggerRebuild(() {});

      _cleanupTimers[index] = Timer(_cleanupDelay, () {
        if (_hoveredSelectedTile != null) {
          _lockedTiles.remove(_hoveredSelectedTile!);
          selectedIndexes.remove(_hoveredSelectedTile);
          _hoveredSelectedTile = null;

          // Clean up state
          _resetState(true, true, triggerRebuild);
        }
      });
      break;
    }

    final word = getCurrentWord();
    _resetState(true, true, triggerRebuild);

    return word;
  }

  /// Checks if a tile was tapped and updates the state accordingly.
  bool onTileTapUp(

      /// The index of the tile that was tapped.
      int index,

      /// If true, a single tap will immediately submit a word.
      void Function(VoidCallback) triggerRebuild) {
    if (simpleTapMode) return false;
    if (!_downPressed) return false;

    if (_hoveredSelectedTile == index) {
      _resetState(true, true, triggerRebuild);
      selectedIndexes.add(index);
      _swipePath.add(index);

      _lockedTiles.add(index);
      _hoveredSelectedTile = index;
      triggerRebuild(() {});

      _cleanupTimers[index] = Timer(_cleanupDelay, () {
        if (_hoveredSelectedTile != null) {
          _lockedTiles.remove(_hoveredSelectedTile!);
          selectedIndexes.remove(_hoveredSelectedTile);
          _hoveredSelectedTile = null;

          // Clean up state
          _resetState(true, true, triggerRebuild);
        }
      });

      return true;
    } else {
      return false;
    }
  }

  // --- Sharp Turn Detection ---
  double _angleBetween(Offset a, Offset b) {
    final dot = a.dx * b.dx + a.dy * b.dy;
    final magA = a.distance;
    final magB = b.distance;
    if (magA == 0 || magB == 0) return 0;
    final cosTheta = dot / (magA * magB);
    return acos(cosTheta.clamp(-1.0, 1.0)) * (180 / pi);
  }

  /// Checks if the last three swipe points form a sharp turn near the tile at the given index.
  bool _isSharpTurnNear(int index) {
    final len = _swipePoints.length;

    if (len < 3) return false;

    final a = _swipePoints[len - 3];
    final b = _swipePoints[len - 2];
    final c = _swipePoints[len - 1];

    final ab = b - a;
    final bc = c - b;

    // NEW: Add distance threshold (e.g., minimum 10px)
    const minSegmentLength = 10.0;
    if (ab.distance < minSegmentLength || bc.distance < minSegmentLength) {
      return false;
    }

    final angle = _angleBetween(ab, bc);
    final rect = _tileRects[index];

    if (rect == null) return false;

    return angle > 20 && angle < 110 && rect.contains(c);
  }

  // --- Tile Bounds Management ---
  /// Registers the rectangle bounds of a tile at the given index.
  void registerTileRect(int index, Rect rect) {
    _tileRects[index] = rect;
  }

  /// Disposes the controller, clearing all internal state.
  void dispose() {
    _tileRects.clear();
    selectedIndexes.clear();
    _swipePath.clear();
    _swipePoints.clear();
    _lockedTiles.clear();

    for (var ctimer in _cleanupTimers) {
      ctimer.cancel();
    }
    for (var timer in _dwellTimers) {
      timer.cancel();
    }
  }
}
