import 'package:flutter/material.dart';

class SwipePathTile extends StatelessWidget {
  /// The letter being shown by the tile widget
  final String letter;
  /// A boolean controlling whether the tile is selected or not
  final bool isSelected;

  /// Creates a tile for the swipe path typer.
  const SwipePathTile({
    super.key,

    /// The letter to display in the tile.
    required this.letter,

    /// Whether the tile is currently selected (part of the swipe path).
    required this.isSelected,
  });

  /// Builds the tile widget with the letter and selection state.
  @override
  Widget build(

      /// The build context for the widget.
      BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.outlineVariant,
          width: 3,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
