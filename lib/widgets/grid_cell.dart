// lib/widgets/grid_cell.dart
import 'package:flutter/material.dart';

// Enum to represent the selection status of a grid cell
enum SelectionStatus {
  none, // Default state, not selected
  selecting, // Currently part of the user's active drag/selection path
  selected, // Part of a successfully selected word (but not yet confirmed as 'found') - might not be used if directly going to 'found'
  found, // Part of a correctly identified word that has been submitted
}

@immutable
class GridCell extends StatelessWidget {
  final String letter;
  final SelectionStatus status;
  final VoidCallback? onTap; // Optional: if direct tap on cell has a function

  const GridCell({
    super.key,
    required this.letter,
    this.status = SelectionStatus.none,
    this.onTap,
  });

  Color _getBackgroundColor(BuildContext context, SelectionStatus status) {
    final colors = Theme.of(context).colorScheme;
    switch (status) {
      case SelectionStatus.selecting:
        return colors.primary.withOpacity(0.7); // Active selection path
      case SelectionStatus
          .selected: // Might be same as selecting or a temporary highlight
        return colors.secondary.withOpacity(0.7);
      case SelectionStatus.found:
        return colors.tertiary.withOpacity(
          0.7,
        ); // Or a distinct 'found' color like green
      case SelectionStatus.none:
      default:
        return colors.surfaceContainerHighest.withOpacity(
          0.5,
        ); // Default cell background
    }
  }

  Color _getTextColor(BuildContext context, SelectionStatus status) {
    final colors = Theme.of(context).colorScheme;
    switch (status) {
      case SelectionStatus.selecting:
        return colors.onPrimary;
      case SelectionStatus.selected:
        return colors.onSecondary;
      case SelectionStatus.found:
        return colors
            .onTertiary; // Ensure this is legible on the tertiary color
      case SelectionStatus.none:
      default:
        return colors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor(context, status);
    final textColor = _getTextColor(context, status);

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        // Ensures the cell is square
        aspectRatio: 1.0,
        child: Container(
          margin: const EdgeInsets.all(
            2.0,
          ), // Small margin for spacing between cells
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.all(
              Radius.circular(8.0),
            ), // Made const
            border: Border.all(
              // Optional: add a subtle border
              color: Theme.of(context).colorScheme.outline.withAlpha(
                (255 * 0.3).round(),
              ), // Using withAlpha
              width: 0.5,
            ),
            // TODO: Consider adding a subtle shadow or different elevation based on status
          ),
          child: Center(
            child: Text(
              letter.toUpperCase(), // Display letter in uppercase
              style: TextStyle(
                fontSize: 18.0, // Adjust font size as needed
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
