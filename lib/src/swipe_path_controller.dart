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

  /// A timer for handling dwell time before unselecting a tile.
  static const Duration _cleanupDelay = Duration(milliseconds: 200);

  /// The minimum delay before a tile is selected when hovered onto.
  static const Duration _minSwipeTurnDelay = Duration(milliseconds: 420);

  /// The maximum number of swipe points to keep in memory.
  static const int _maxSwipePoints = 69;

  /// A timer for handling dwell time before unselecting a tile.
  Timer? _dwellTimer;

  /// Creates a controller for managing swipe path typing.
  SwipePathController(

      /// The list of letters to display as swipeable tiles.
      this._tiles,

      /// If true, a single tap will immediately submit a word.
      {this.simpleTapMode = true});

  /// Registers the rectangle bounds of a tile at the given index.
  Rect _deflateRect(

      /// The rectangle to deflate.
      Rect rect,

      /// The factor by which to deflate the rectangle.
      [double factor = 0.1]) {
    double deflation = min(rect.width, rect.height) * factor;
    return rect.deflate(deflation);
  }

  /// Adds a swipe point to the internal list, maintaining a maximum length.
  void _addSwipePoint(

      /// The point to add to the swipe trail.
      Offset point) {
    if (_swipePoints.length >= _maxSwipePoints) {
      _swipePoints.removeAt(0);
    }
    _swipePoints.add(point);
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
    _lockedTiles.clear();

    if (fullReset) {
      _downPressed = false;
      _dwellTimer?.cancel();
    }
    if (rebuild) {
      triggerRebuild(() {});
    }
  }

  /// Initializes the tile rectangles after the first build.
  void onTileTapDown(

      /// The index of the tile that was tapped.
      int index,

      /// A function to trigger a rebuild of the widget tree.
      void Function(VoidCallback) triggerRebuild) {
    _resetState(false, false, triggerRebuild);
    _downPressed = true;
    selectedIndexes.add(index);
    _swipePath.add(index);
    _lockedTiles.add(index);
    _hoveredSelectedTile = index;
    triggerRebuild(() {});
    Timer(_cleanupDelay, () {
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

  /// Updates the swipe path based on the current global position.
  void updateSwipe(

      /// The current global position of the swipe gesture.
      Offset globalPosition,

      /// A function to trigger a rebuild of the widget tree.
      void Function(VoidCallback) triggerRebuild) {
    if (!_downPressed) return;

    _addSwipePoint(globalPosition);

    // Unlock selected tile when finger leaves it
    if (_hoveredSelectedTile != null) {
      final rect = _tileRects[_hoveredSelectedTile!];
      if (rect != null && !rect.inflate(12).contains(globalPosition)) {
        _lockedTiles.remove(_hoveredSelectedTile!);
        selectedIndexes.remove(_hoveredSelectedTile);
        _hoveredSelectedTile = null;
        triggerRebuild(() {});
      }
    }

    for (var entry in _tileRects.entries) {
      final index = entry.key;
      final rect = entry.value;

      final deflatedRect = _deflateRect(rect);

      if (!deflatedRect.contains(globalPosition)) continue;
      if (_lockedTiles.contains(index)) continue;

      // Dwell trigger
      if (_hoveredTileIndex != index) {
        _hoveredTileIndex = index;
        _dwellTimer?.cancel();
        _dwellTimer = Timer(_minSwipeTurnDelay, () {
          if (_hoveredTileIndex == index && !_lockedTiles.contains(index)) {
            selectedIndexes.add(index);
            _swipePath.add(index);
            _lockedTiles.add(index);
            _hoveredSelectedTile = index;
            triggerRebuild(() {});
          }
        });
      }

      // Sharp turn detection
      final sharpTurn = _isSharpTurnNear(index);
      if (sharpTurn) {
        _dwellTimer?.cancel();
        _hoveredTileIndex = null;
        selectedIndexes.add(index);
        _swipePath.add(index);
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

      if (!_deflateRect(rect).contains(globalPosition)) continue;
      if (_lockedTiles.contains(index)) continue;

      selectedIndexes.add(index);
      _swipePath.add(index);
      _addSwipePoint(globalPosition);
      break;
    }

    final word = _swipePath.map((i) => _tiles[i]).join();

    Timer(_cleanupDelay, () {
      // Clean up state
      _resetState(true, true, triggerRebuild);
    });

    return word;
  }

  /// Checks if a tile was tapped and updates the state accordingly.
  bool onTileTapUp(

      /// The index of the tile that was tapped.
      int index,

      /// If true, a single tap will immediately submit a word.
      void Function(VoidCallback) triggerRebuild) {
    if (simpleTapMode) return false;

    if (_hoveredSelectedTile == index) {
      _resetState(false, false, triggerRebuild);
      selectedIndexes.add(index);
      _swipePath.add(index);
      _lockedTiles.add(index);
      _hoveredSelectedTile = index;
      triggerRebuild(() {});

      Timer(_cleanupDelay, () {
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
    if (_swipePoints.length < 3) return false;

    final a = _swipePoints[_swipePoints.length - 3];
    final b = _swipePoints[_swipePoints.length - 2];
    final c = _swipePoints[_swipePoints.length - 1];

    final ab = b - a;
    final bc = c - b;

    // NEW: Add distance threshold (e.g., minimum 10px)
    const minSegmentLength = 7.0;
    if (ab.distance < minSegmentLength || bc.distance < minSegmentLength) {
      return false;
    }

    final angle = _angleBetween(ab, bc);
    final rect = _tileRects[index];

    if (rect == null) return false;

    return angle > 69 && _deflateRect(rect).contains(c);
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
    _dwellTimer?.cancel();
  }
}
