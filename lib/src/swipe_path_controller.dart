import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class SwipePathController {
  final List<String> _tiles;
  final Set<int> selectedIndexes = {};
  final Map<int, Rect> _tileRects = {};
  final List<int> _swipePath = [];
  final List<Offset> _swipePoints = [];
  final bool simpleTapMode;
  List<Offset> get swipeTrail => List.unmodifiable(_swipePoints);

  final Set<int> _lockedTiles = {};
  int? _hoveredTileIndex;
  int? _hoveredSelectedTile;
  bool _downPressed = false;

  static const Duration _cleanupDelay = Duration(milliseconds: 200);
  static const Duration _minSwipeTurnDelay = Duration(milliseconds: 420);


  static const int _maxSwipePoints = 69;

  Timer? _dwellTimer;

  SwipePathController(this._tiles, {this.simpleTapMode = true});


  Rect _deflateRect(Rect rect, [double factor = 0.1]) {
    double deflation = min(rect.width, rect.height) * factor;
    return rect.deflate(deflation);
  }


  void _addSwipePoint(Offset point) {
    if (_swipePoints.length >= _maxSwipePoints) {
      _swipePoints.removeAt(0);
    }
    _swipePoints.add(point);
  }


  void _resetState(bool fullReset, bool rebuild, void Function(VoidCallback) triggerRebuild) {
    selectedIndexes.clear();
    _swipePath.clear();
    _swipePoints.clear();
    _lockedTiles.clear();
    _hoveredTileIndex = null;
    _hoveredSelectedTile = null;
    _lockedTiles.clear();

    if (fullReset){
      _downPressed = false;
      _dwellTimer?.cancel();
    }
    if (rebuild) {
      triggerRebuild(() {});
    }
  }


  void onTileTapDown(int index, void Function(VoidCallback) triggerRebuild) {
    debugPrint('onTileTapDown: $index, simpleTapMode: $simpleTapMode');
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

  void updateSwipe(Offset globalPosition, void Function(VoidCallback) triggerRebuild) {
    debugPrint('updateSwipe called with globalPosition: $globalPosition');
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

  String getCurrentWord() {
    return _swipePath.map((i) => _tiles[i]).join();
  }

  String endSwipe(Offset globalPosition, void Function(VoidCallback) triggerRebuild) {
    debugPrint('endSwipe called with globalPosition: $globalPosition');
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

  bool onTileTapUp(int index, void Function(VoidCallback) triggerRebuild) {
    debugPrint('onTileTapUp: $index, simpleTapMode: $simpleTapMode');
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
    }
    else {
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
  void registerTileRect(int index, Rect rect) {
    _tileRects[index] = rect;
  }

  void dispose() {
    _tileRects.clear();
    selectedIndexes.clear();
    _swipePath.clear();
    _swipePoints.clear();
    _lockedTiles.clear();
    _dwellTimer?.cancel();
  }
}