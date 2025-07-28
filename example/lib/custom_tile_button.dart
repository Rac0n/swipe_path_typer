import 'package:flutter/material.dart';

class CustomTileButton extends StatelessWidget {
  final String letter;
  final bool isSelected;

  const CustomTileButton({
    super.key,
    required this.letter,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.outline,
          width: 3,
        ),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        child: Text(
          letter.toUpperCase(),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
