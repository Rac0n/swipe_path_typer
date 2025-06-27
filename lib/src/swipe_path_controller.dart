// src/swipe_path_controller.dart
import 'dart:math';

import 'package:flutter/material.dart';

class SwipePathController {
  final List<String> _tiles;
  final Set<int> selectedIndexes = {};
  final Map<int, Rect> _tileRects = {};
  final List<int> _swipePath = [];
  final List<Offset> _swipePoints = [];
  final bool smartDetection;
  final List<DateTime> _swipeTimes = [];

  int? _hoveredTileIndex;
  DateTime? _hoverStartTime;

  Duration dwellThreshold = Duration(milliseconds: 300);

  SwipePathController(this._tiles, {this.smartDetection = true});

  void startSwipe() {
    selectedIndexes.clear();
    _swipePoints.clear();
  }

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

    final angle = _angleBetween(ab, bc);
    final rect = _tileRects[index];

    if (rect == null) return false;
    double deflation = rect.width/10;
    if (rect.height/10 < deflation){
      deflation = rect.height/10;
    }

    return angle > 60 && rect.deflate(deflation).contains(c);
  }


  void onTileTapDown(int index, void Function(VoidCallback) triggerRebuild) {
    selectedIndexes.add(index);
    _swipePath.add(index);
    triggerRebuild(() {});
  }


  void onTileEnter(int index) {
    if(selectedIndexes.isEmpty) return;
    _hoveredTileIndex = index;
    _hoverStartTime = DateTime.now();
  }


  void onTileHover(int index, void Function(VoidCallback) triggerRebuild) {
    if (_hoveredTileIndex == null) return;

    final now = DateTime.now();
    final hoverDuration = now.difference(_hoverStartTime!);

    if (hoverDuration >= dwellThreshold) {
      if (!selectedIndexes.contains(index)) {
        selectedIndexes.add(index);
        _hoveredTileIndex = null;
        _hoverStartTime = null;
        triggerRebuild(() {});
      }
    }
  }


  void onTileTapUp(int index, void Function(VoidCallback) triggerRebuild) {
    if (!selectedIndexes.contains(index)) {
      selectedIndexes.add(index);
      triggerRebuild(() {});
    }
  }


  void updateSwipe(Offset globalPosition, void Function(VoidCallback) triggerRebuild) {
    _swipePoints.add(globalPosition);

    for (var entry in _tileRects.entries) {
      final index = entry.key;
      final rect = entry.value;

      double deflation = rect.width/10;
      if (rect.height/10 < deflation){
        deflation = rect.height/10;
      }

      if (!rect.deflate(deflation).contains(globalPosition)) continue;
      if (selectedIndexes.contains(index)) continue;

        final sharpTurn = smartDetection && _isSharpTurnNear(index);

        final shouldSelect = smartDetection ? (sharpTurn) : true;

        if (shouldSelect) {
          selectedIndexes.add(index);
          _swipePath.add(index);
          _swipePoints.add(globalPosition);
          triggerRebuild(() {});
          break;
        }
      
    }

  }


  String endSwipe() {
    final word = _swipePath.map((i) => _tiles[i]).join();
    selectedIndexes.clear();
    _swipePath.clear();
    _swipePoints.clear();
    _swipeTimes.clear();
    _hoveredTileIndex = null;
    _hoverStartTime = null;

    return word;
  }


  // --- Tile bounds management ---
  void registerTileRect(int index, Rect rect) {
    _tileRects[index] = rect;
  }

  void dispose() {
    _tileRects.clear();
    selectedIndexes.clear();
    _swipePoints.clear();
  }
}
