// lib/swipe_path_typer.dart

/// A Flutter package for swipe-based typing that mimics gesture typing on mobile keyboards.
///
/// This library provides widgets and controllers for implementing swipe-to-type functionality
/// in Flutter applications. It's ideal for word games, puzzles, or any app requiring
/// gesture-based text input.
///
/// The main components are:
/// - [SwipePathTyper]: The main widget for swipe typing
/// - [SwipePathController]: Controller for managing swipe state
/// - [SwipePathTile]: Default tile widget for letters
/// - [SwipeTrailPainter]: Custom painter for the swipe trail
library swipe_path_typer;

export 'src/swipe_path_typer_widget.dart';
export 'src/swipe_path_controller.dart';
export 'src/swipe_path_tile_config.dart';
export 'src/swipe_path_painter.dart';
