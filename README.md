# swipe_path_typer

A swipe-based typing widget for Flutter, mimicking the gesture typing experience of modern mobile keyboards like Gboard or SwiftKey.

Ideal for games, puzzles, and creative UIs that need swipe input on a grid of characters.

---

## ✨ Features

- 📱 Swipe over tiles to form words
- 🔀 Sharp turn detection for smart letter selection
- 👆 Tap support (with optional auto-complete on tap)
- 🎨 Fully customizable tile UI
- 🧱 Adjustable layout, spacing, and interaction
- 🖌️ Painted swipe trail (customizable color and thickness)
- 🖱️ Desktop/web mouse support

---

## 🚀 Usage

### Basic

```dart
SwipePathTyper(
  tiles: ['h', 'e', 'l', 'l', 'o'],
  onSwipeCompleted: (word) {
    print('User typed: $word');
  },
  onLetterSelected: (letter){
    print('User selected $letter')
  }
)
```

---

### Custom Tile Example

```dart
tileBuilder: (context, letter, isSelected) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isSelected ? Colors.blue : Colors.grey[200],
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      letter.toUpperCase(),
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    ),
  );
},
```

---

## ⚙️ Parameters

| Parameter                 | Type                           | Description                                      |
|---------------------------|--------------------------------|--------------------------------------------------|
| `tiles`                   | `List<String>`                 | The list of characters to render as tiles        |
| `onSwipeCompleted`         | `ValueChanged<String>`         | Called when a word is completed via swipe        |
| `onLetterSelected`         | `ValueChanged<String>`         | Called when a letter is selected            |
| `tileBuilder`             | `TileBuilder?`                 | Optional builder to customize tile UI            |
| `columnCount`             | `int`                          | Number of tiles per row (default: 5)             |
| `simpleTapMode`           | `bool`                         | Taps immediately complete a word (default: true) |
| `horizontalTileSpacing`   | `double`                       | Horizontal space between tiles                   |
| `verticalTileSpacing`     | `double`                       | Vertical space between tile rows                 |
| `padding`                 | `EdgeInsets`                   | Padding around the entire widget                 |
| `onPanUpdate`             | `Function(DragUpdateDetails)?` | Called during a swipe                            |
| `onPanEnd`                | `Function(DragEndDetails)?`    | Called when a swipe ends                         |
| `onPanStart`              | `Function(DragEndDetails)?`    | Called when a swipe starts                       |
| `onTapDown`               | `Function(int)?`               | Called when a tile is tapped down                |
| `onTapUp`                 | `Function(int)?`               | Called when a tile is tapped up                  |
| `widgetHitTestBehavior`   | `HitTestBehavior`              | Behavior for the gesture container               |
| `tileHitTestBehavior`     | `HitTestBehavior`              | Behavior for mouse hover on tiles                |
| `tileCursor`              | `SystemMouseCursor`            | Cursor to use on hover (e.g., click)             |
| `swipeTrailColor`         | `Color`                        | Color of the swipe trail                         |
| `swipeTrailStrokeWidth`   | `double`                       | Thickness of the swipe trail line                |

---

## 🧪 Example

A working example is available in [`/example/main.dart`](example/main.dart).

---

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  swipe_path_typer: ^1.1.2
```

---

## 📄 License

MIT © 2025 [Your Name or Studio]
