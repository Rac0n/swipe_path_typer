import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// A controller that manages the state and logic for swipe path typing.
///
/// This controller handles:
/// - Tracking swipe points and selected tiles
/// - Gesture recognition (taps, swipes, sharp turns)
/// - Dwell timers for hover-based selection
/// - State management for the swipe path
///
/// Example:
/// ```dart
/// final controller = SwipePathController(
///   ['H', 'E', 'L', 'L', 'O'],
///   (letter) => print('Selected: $letter'),
/// );
/// ```
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

  /// Returns an unmodifiable list of points representing the current swipe trail.
  ///
  /// These points are used to draw the visual trail as the user swipes across tiles.
  /// The list is automatically managed and trimmed to [_maxSwipePoints] for performance.
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

  /// Handles the start of a pan gesture at the specified position.
  ///
  /// This method initializes the swipe gesture, resets the controller state,
  /// and selects the first tile if the position is over a valid tile.
  ///
  /// Returns the index of the selected tile, or -1 if no tile was selected.
  ///
  /// Parameters:
  /// - [globalPosition]: The global position of the tap.
  /// - [triggerRebuild]: A function to trigger a rebuild of the widget tree.
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

  /// Handles a tap down event on a specific tile.
  ///
  /// This method is called when a user taps directly on a tile rather than
  /// starting a pan gesture. It immediately selects the tile and adds it to the path.
  ///
  /// Parameters:
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
  ///
  /// This method is called continuously during a pan gesture to:
  /// - Update the visual trail
  /// - Detect when tiles are entered or exited
  /// - Trigger selection via dwell timers or sharp turn detection
  /// - Unlock tiles when the gesture leaves them
  ///
  /// The method uses two selection strategies:
  /// 1. **Dwell timer**: Tile is selected after hovering for [_minSwipeTurnDelay]
  /// 2. **Sharp turn**: Immediate selection when a sharp directional change is detected
  ///
  /// Parameters:
  void updateSwipe(

      /// The current global position of the swipe gesture.
      Offset globalPosition,

      /// A function to trigger a rebuild of the widget tree.
      void Function(VoidCallback) triggerRebuild) {
    if (!_downPressed || simpleTapMode) return;

    _addSwipePoint(globalPosition);

    // Always trigger rebuild for visual trail updates, even when not over tiles
    bool shouldRebuild = false;

    // Unlock selected tile when finger leaves it
    if (_hoveredSelectedTile != null) {
      final rect = _tileRects[_hoveredSelectedTile!];
      if (rect != null && !rect.contains(globalPosition)) {
        _lockedTiles.remove(_hoveredSelectedTile!);
        selectedIndexes.remove(_hoveredSelectedTile);
        _hoveredSelectedTile = null;
        shouldRebuild = true;
      }
    }

    bool overAnyTile = false;
    for (var entry in _tileRects.entries) {
      final index = entry.key;
      final rect = entry.value;

      if (!rect.contains(globalPosition)) continue;
      overAnyTile = true;

      // Allow revisiting tiles that are not currently the hovered/selected tile
      if (_lockedTiles.contains(index) && _hoveredSelectedTile == index) {
        continue;
      }

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
        shouldRebuild = true;
        break;
      }
    }

    // Reset hovered tile index when not over any tile
    if (!overAnyTile && _hoveredTileIndex != null) {
      _hoveredTileIndex = null;
      shouldRebuild = true;
    }

    // Always rebuild to update the swipe trail
    if (shouldRebuild || true) {
      // Force rebuild for trail updates
      triggerRebuild(() {});
    }
  }

  /// Returns the current word formed by the swipe path.
  ///
  /// Concatenates all selected tiles in order to form a word string.
  /// This can be called at any time during or after a swipe gesture.
  ///
  /// Returns an empty string if no tiles have been selected.
  String getCurrentWord() {
    return _swipePath.map((i) => _tiles[i]).join();
  }

  /// Ends the swipe gesture and returns the formed word.
  ///
  /// This method:
  /// - Adds the final swipe point
  /// - Attempts to select a tile at the end position
  /// - Returns the complete word
  /// - Resets the controller state
  ///
  /// Returns the word formed by the swipe path, or an empty string if no word was formed.
  ///
  /// Parameters:
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
      // Allow selecting new tiles at the end, but not the currently selected one
      if (_hoveredSelectedTile == index) continue;

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

  /// Handles a tap up event on a specific tile.
  ///
  /// This method is used in non-simpleTapMode to complete a word when
  /// the user lifts their finger while over a tile they tapped down on.
  ///
  /// Returns `true` if the tap was processed and a word should be submitted,
  /// `false` otherwise.
  ///
  /// Parameters:
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

  /// Calculates the angle in degrees between two offset vectors.
  ///
  /// Used for sharp turn detection to determine when a user makes a
  /// significant directional change while swiping.
  ///
  /// Returns the angle in degrees (0-180).
  double _angleBetween(Offset a, Offset b) {
    final dot = a.dx * b.dx + a.dy * b.dy;
    final magA = a.distance;
    final magB = b.distance;
    if (magA == 0 || magB == 0) return 0;
    final cosTheta = dot / (magA * magB);
    return acos(cosTheta.clamp(-1.0, 1.0)) * (180 / pi);
  }

  /// Checks if the last three swipe points form a sharp turn near the tile at the given index.
  ///
  /// A sharp turn is detected when:
  /// - There are at least 3 swipe points
  /// - The segments have minimum length ([minSegmentLength])
  /// - The angle between segments is between 20° and 110°
  /// - The final point is within the tile's bounds
  ///
  /// This allows for instant tile selection when making quick directional changes,
  /// improving the responsiveness of the swipe gesture.
  ///
  /// Returns `true` if a sharp turn is detected near the tile.
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
  ///
  /// This method is called during the initial layout to store the screen positions
  /// of all tiles. These bounds are used for hit testing during swipe gestures.
  ///
  /// Parameters:
  /// - [index]: The tile index
  /// - [rect]: The global rectangle bounds of the tile
  void registerTileRect(int index, Rect rect) {
    _tileRects[index] = rect;
  }

  /// Disposes the controller, clearing all internal state and canceling timers.
  ///
  /// This method should be called when the controller is no longer needed
  /// to prevent memory leaks. It:
  /// - Clears all data structures
  /// - Cancels all active timers
  /// - Releases all resources
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
