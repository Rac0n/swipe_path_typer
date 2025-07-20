import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class SwipePathController {
  final List<String> _tiles;
  final Set<int> selectedIndexes = {};
  final Map<int, Rect> _tileRects = {};
  final List<int> _swipePath = [];
  final List<Offset> _swipePoints = [];
  final bool smartDetection;
  List<Offset> get swipeTrail => List.unmodifiable(_swipePoints);

  final Set<int> _lockedTiles = {};
  int? _hoveredTileIndex;
  int? _hoveredSelectedTile;
  bool _downPressed = false;

  final Duration dwellThreshold = Duration(milliseconds: 360);
  Timer _dwellTimer = Timer(Duration.zero, () {});

  SwipePathController(this._tiles, {this.smartDetection = true});


  void onTileTapDown(int index, void Function(VoidCallback) triggerRebuild) {
    selectedIndexes.clear();
    _swipePath.clear();
    _swipePoints.clear();
    _lockedTiles.clear();
    _hoveredTileIndex = null;
    _hoveredSelectedTile = null;
    _downPressed = true;
    selectedIndexes.add(index);
    _swipePath.add(index);
    _lockedTiles.add(index);
    _hoveredSelectedTile = index;
    triggerRebuild(() {});
  }

  void updateSwipe(Offset globalPosition, void Function(VoidCallback) triggerRebuild) {
    if (!_downPressed) return;

    _swipePoints.add(globalPosition);

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

      double deflation = rect.width / 10;
      if (rect.height / 10 < deflation) {
        deflation = rect.height / 10;
      }

      final deflatedRect = rect.deflate(deflation);

      if (!deflatedRect.contains(globalPosition)) continue;
      if (_lockedTiles.contains(index)) continue;

      // Dwell trigger
      if (_hoveredTileIndex != index) {
        _hoveredTileIndex = index;
        _dwellTimer.cancel();
        _dwellTimer = Timer(dwellThreshold, () {
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
      final sharpTurn = smartDetection && _isSharpTurnNear(index);
      if (!smartDetection || sharpTurn) {
        _dwellTimer.cancel();
        _hoveredTileIndex = null;
        selectedIndexes.add(index);
        _swipePath.add(index);
        _lockedTiles.add(index);
        _hoveredSelectedTile = index;
        _swipePoints.add(globalPosition);
        triggerRebuild(() {});
        break;
      }
    }
  }

  String endSwipe(Offset globalPosition, void Function(VoidCallback) triggerRebuild) {
    if (!_downPressed) return '';

    _swipePoints.add(globalPosition);

    for (var entry in _tileRects.entries) {
      final index = entry.key;
      final rect = entry.value;

      double deflation = rect.width / 10;
      if (rect.height / 10 < deflation) {
        deflation = rect.height / 10;
      }

      if (!rect.deflate(deflation).contains(globalPosition)) continue;
      if (_lockedTiles.contains(index)) continue;

      selectedIndexes.add(index);
      _swipePath.add(index);
      _swipePoints.add(globalPosition);
      break;
    }

    final word = _swipePath.map((i) => _tiles[i]).join();

    // Clean up state
    selectedIndexes.clear();
    _swipePath.clear();
    _swipePoints.clear();
    _hoveredTileIndex = null;
    _hoveredSelectedTile = null;
    _lockedTiles.clear();
    _downPressed = false;
    _dwellTimer.cancel();

    return word;
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

    double deflation = rect.width / 10;
    if (rect.height / 10 < deflation) {
      deflation = rect.height / 10;
    }

    return angle > 69 && rect.deflate(deflation).contains(c);
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
    _dwellTimer.cancel();
  }
}