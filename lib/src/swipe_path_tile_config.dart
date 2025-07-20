import 'package:flutter/material.dart';

class SwipePathTile extends StatelessWidget {
  final String letter;
  final bool isSelected;

  const SwipePathTile({
    super.key,
    required this.letter,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
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
