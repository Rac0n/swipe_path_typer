# Changelog

All notable changes to this project will be documented in this file.

## 1.1.1
- Added the onLetterSelected event, as well as changed the onWordCompleted one to onSwipeCompleted as it is clearer

## 1.1.0
- Added the pan start event (fixing cases when the pan start event does not allow the tile tap down event to be called)

## 1.0.6

- Fixed a bug with the swipe feature

## 1.0.5

- Fixed a problem with the custom tileBuilder feature

## 1.0.4

- Fixed a padding issue

## 1.0.3

- Added alignment option and removed certain debug logs

## 1.0.2

- Formatted files to adhere to the standard style used in Dart and Flutter projects

## 1.0.1

- Additional documenation in the different classes

## 1.0.0

### Added

- Initial release of `swipe_path_typer`
- Gesture-based letter selection
- Sharp turn detection with angle and distance threshold
- Tap-to-complete (simpleTapMode)
- Customizable tile builder
- Configurable swipe trail (color, thickness)
- Support for mouse interaction and custom cursors
- HitTestBehavior customization
- Padding, spacing, and column layout control
