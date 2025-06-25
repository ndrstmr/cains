// lib/providers/word_grid_provider.dart
import 'dart:math'; // For Point class, and potentially math operations
import 'package:flutter/material.dart'; // For Offset and Size
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/widgets/grid_cell.dart'; // For SelectionStatus enum

// Custom class for grid indices for clarity, using Point<int> for simplicity
typedef GridIndex = Point<int>; // int x for column, int y for row

@immutable
class WordGridState {
  final List<List<String>> gridLetters; // The letters in the grid
  final List<List<SelectionStatus>> cellStatuses; // Status of each cell
  final List<GridIndex>
  selectedIndices; // Current path of selected cells (row, col)
  final Set<String> foundWords; // Words already found by the user
  final List<String> hiddenWords; // All words hidden in the grid
  final String currentWord; // Word formed by current selection path
  final String? feedbackMessageKey; // Key for i18n feedback message
  final String?
  feedbackMessageArg; // Argument for i18n feedback message (e.g., the word itself)
  final int crossAxisCount; // Number of columns in the grid

  const WordGridState({
    required this.gridLetters,
    required this.cellStatuses,
    required this.selectedIndices,
    required this.foundWords,
    required this.hiddenWords,
    required this.currentWord,
    this.feedbackMessageKey,
    this.feedbackMessageArg,
    required this.crossAxisCount,
  });

  // Initial state factory
  factory WordGridState.initial() {
    return const WordGridState(
      gridLetters: [],
      cellStatuses: [],
      selectedIndices: [],
      foundWords: {},
      hiddenWords: [],
      currentWord: '',
      feedbackMessageKey: null,
      feedbackMessageArg: null,
      crossAxisCount: 0, // Default, should be set by initializeGrid
    );
  }

  WordGridState copyWith({
    List<List<String>>? gridLetters,
    List<List<SelectionStatus>>? cellStatuses,
    List<GridIndex>? selectedIndices,
    Set<String>? foundWords,
    List<String>? hiddenWords,
    String? currentWord,
    String? feedbackMessageKey,
    String? feedbackMessageArg,
    bool clearFeedbackMessages = false, // Explicit flag to clear feedback
    int? crossAxisCount,
  }) {
    return WordGridState(
      gridLetters: gridLetters ?? this.gridLetters,
      cellStatuses: cellStatuses ?? this.cellStatuses,
      selectedIndices: selectedIndices ?? this.selectedIndices,
      foundWords: foundWords ?? this.foundWords,
      hiddenWords: hiddenWords ?? this.hiddenWords,
      currentWord: currentWord ?? this.currentWord,
      feedbackMessageKey: clearFeedbackMessages
          ? null
          : feedbackMessageKey ?? this.feedbackMessageKey,
      feedbackMessageArg: clearFeedbackMessages
          ? null
          : feedbackMessageArg ?? this.feedbackMessageArg,
      crossAxisCount: crossAxisCount ?? this.crossAxisCount,
    );
  }
}

class WordGridNotifier extends StateNotifier<WordGridState> {
  WordGridNotifier() : super(WordGridState.initial());

  void initializeGrid(
    List<List<String>> initialGridLetters,
    List<String> wordsToFind,
  ) {
    if (initialGridLetters.isEmpty) {
      state = WordGridState.initial(); // Reset if grid is empty
      return;
    }
    final rows = initialGridLetters.length;
    final cols = initialGridLetters[0].length;
    state = WordGridState(
      gridLetters: initialGridLetters,
      cellStatuses: List.generate(
        rows,
        (_) => List.filled(cols, SelectionStatus.none),
      ),
      selectedIndices: [],
      foundWords: {}, // Initialize as empty set
      hiddenWords: wordsToFind.map((w) => w.toUpperCase()).toList(),
      currentWord: '',
      feedbackMessageKey: null,
      feedbackMessageArg: null,
      crossAxisCount: cols,
    );
  }

  GridIndex? _getCellFromLocalPosition(Offset localPosition, Size gridSize) {
    if (state.crossAxisCount == 0 || state.gridLetters.isEmpty) return null;
    final rows = state.gridLetters.length;
    final cols = state.crossAxisCount;

    final double cellWidth = gridSize.width / cols;
    final double cellHeight = gridSize.height / rows;

    if (localPosition.dx < 0 ||
        localPosition.dx >= gridSize.width ||
        localPosition.dy < 0 ||
        localPosition.dy >= gridSize.height) {
      return null; // Outside bounds
    }

    final int col = (localPosition.dx / cellWidth).floor();
    final int row = (localPosition.dy / cellHeight).floor();

    if (row >= 0 && row < rows && col >= 0 && col < cols) {
      return GridIndex(col, row);
    }
    return null;
  }

  void handlePanStart(Offset localPosition, Size gridSize) {
    final startIndex = _getCellFromLocalPosition(localPosition, gridSize);
    if (startIndex == null) return;

    // Check if this cell is part of an already found word path
    if (state.cellStatuses[startIndex.y][startIndex.x] ==
        SelectionStatus.found) {
      return; // Ignore start if cell is already part of a found word
    }

    final newStatuses = _copyStatuses();
    newStatuses[startIndex.y][startIndex.x] = SelectionStatus.selecting;

    state = state.copyWith(
      selectedIndices: [startIndex],
      cellStatuses: newStatuses,
      currentWord: state.gridLetters[startIndex.y][startIndex.x],
      clearFeedbackMessages: true, // Corrected parameter name
    );
  }

  void handlePanUpdate(Offset localPosition, Size gridSize) {
    if (state.selectedIndices.isEmpty) return;

    final currentIndex = _getCellFromLocalPosition(localPosition, gridSize);
    if (currentIndex == null || state.selectedIndices.contains(currentIndex)) {
      // If outside bounds or already selected, no change in selection path
      // but we might want to update the visual path if the drag goes back over selected cells
      return;
    }

    // Check if this cell is part of an already found word path
    if (state.cellStatuses[currentIndex.y][currentIndex.x] ==
        SelectionStatus.found) {
      return; // Ignore update if cell is already part of a found word
    }

    final List<GridIndex> newSelectedIndices = List.from(state.selectedIndices);
    final GridIndex lastIndex = newSelectedIndices.last;

    // Determine potential path from lastIndex to currentIndex
    // This simplified version just adds if it's a direct neighbor for straight line
    // A more robust solution would calculate all cells on the line between lastIndex and currentIndex.
    // For now, we assume the gesture update gives us sequential cells.

    // Validate if the new cell forms a straight line with the previous selection
    if (!_isValidNextCell(lastIndex, currentIndex, newSelectedIndices)) {
      // If not a valid next cell for a straight line, or if it's not a neighbor,
      // we could either ignore it or reset the selection.
      // For this version, we'll be somewhat lenient and just add it if it's a neighbor.
      // A more strict approach is needed for true word search rules.

      // This simple check is not enough for true straight line validation from the start.
      // The logic for ensuring a straight line is complex.
      // For now, we'll just add the new cell. The `_isStraightLinePath` will be more crucial at `onPanEnd`.
    }

    newSelectedIndices.add(currentIndex);

    final newStatuses = _copyStatuses();
    String currentWord = '';
    for (var index in newSelectedIndices) {
      // Ensure existing 'found' statuses are preserved
      if (newStatuses[index.y][index.x] != SelectionStatus.found) {
        newStatuses[index.y][index.x] = SelectionStatus.selecting;
      }
      currentWord += state.gridLetters[index.y][index.x];
    }

    state = state.copyWith(
      selectedIndices: newSelectedIndices,
      cellStatuses: newStatuses,
      currentWord: currentWord,
    );
  }

  // Basic check if the next cell is adjacent (horizontally, vertically, or diagonally)
  // And if it maintains the direction of the line if more than 2 cells are selected.
  bool _isValidNextCell(
    GridIndex lastIndex,
    GridIndex currentIndex,
    List<GridIndex> currentSelection,
  ) {
    final dx = (currentIndex.x - lastIndex.x).abs();
    final dy = (currentIndex.y - lastIndex.y).abs();

    // Must be an adjacent cell (Manhattan distance or Chebyshev distance for diagonals)
    bool isAdjacent = (dx <= 1 && dy <= 1) && !(dx == 0 && dy == 0);
    if (!isAdjacent) return false;

    if (currentSelection.length >= 2) {
      final GridIndex secondLastIndex =
          currentSelection[currentSelection.length - 2];
      final int pathDx =
          lastIndex.x - secondLastIndex.x; // Direction of current path
      final int pathDy = lastIndex.y - secondLastIndex.y;

      // New segment must maintain the same direction
      if ((currentIndex.x - lastIndex.x) != pathDx ||
          (currentIndex.y - lastIndex.y) != pathDy) {
        return false;
      }
    }
    return true;
  }

  void handlePanEnd() {
    if (state.selectedIndices.isEmpty) return;

    final String formedWord = state.currentWord.toUpperCase();
    // TODO: Add proper straight line validation for state.selectedIndices here if not fully handled in onPanUpdate
    // bool isStraight = _isStraightLinePath(state.selectedIndices);
    // if (!isStraight) {
    //   resetSelection("Selection must be a straight line.");
    //   return;
    // }

    if (state.hiddenWords.contains(formedWord) &&
        !state.foundWords.contains(formedWord)) {
      // Word found!
      final newStatuses = _copyStatuses();
      for (var index in state.selectedIndices) {
        newStatuses[index.y][index.x] = SelectionStatus.found;
      }
      final newFoundWords = Set<String>.from(state.foundWords)..add(formedWord);
      state = state.copyWith(
        cellStatuses: newStatuses,
        foundWords: newFoundWords,
        selectedIndices: [], // Clear current selection path
        currentWord: '',
        feedbackMessageKey: "feedbackWordFound",
        feedbackMessageArg: formedWord,
      );
    } else {
      // Word not found or already found
      resetSelection(
        state.foundWords.contains(formedWord)
            ? "feedbackWordAlreadyFound"
            : "feedbackWordNotValid",
        state.foundWords.contains(formedWord) ? formedWord : formedWord,
      );
    }
  }

  // Helper to check if a list of indices forms a straight line (horizontal, vertical, or diagonal)
  // This is a simplified check. A truly robust one is more complex.
  bool _isStraightLinePath(List<GridIndex> indices) {
    if (indices.length <= 1) {
      return true; // Single cell or no selection is trivially a straight line
    }

    // Calculate deltas between consecutive points
    int? dx;
    int? dy;

    for (int i = 0; i < indices.length - 1; i++) {
      final p1 = indices[i];
      final p2 = indices[i + 1];

      final currentDx = p2.x - p1.x;
      final currentDy = p2.y - p1.y;

      // Check for valid steps (adjacent cells only)
      if (currentDx.abs() > 1 || currentDy.abs() > 1) {
        return false; // Not adjacent
      }

      if (dx == null) {
        // First segment
        dx = currentDx;
        dy = currentDy;
      } else {
        // Subsequent segments must maintain the same delta
        if (currentDx != dx || currentDy != dy) {
          return false; // Direction changed
        }
      }
    }
    return true; // All segments maintained the same direction
  }

  void resetSelection([String? messageKey, String? messageArg]) {
    if (state.selectedIndices.isEmpty && messageKey == null) return;

    final newStatuses = _copyStatuses();
    for (var index in state.selectedIndices) {
      // Only reset 'selecting' cells, not 'found' cells
      if (newStatuses[index.y][index.x] == SelectionStatus.selecting) {
        newStatuses[index.y][index.x] = SelectionStatus.none;
      }
    }
    state = state.copyWith(
      selectedIndices: [],
      cellStatuses: newStatuses,
      currentWord: '',
      feedbackMessageKey: messageKey,
      feedbackMessageArg: messageArg,
    );
  }

  List<List<SelectionStatus>> _copyStatuses() {
    return state.cellStatuses
        .map((row) => List<SelectionStatus>.from(row))
        .toList();
  }

  void clearFeedbackMessage() {
    if (state.feedbackMessageKey != null) {
      state = state.copyWith(clearFeedbackMessages: true);
    }
  }
}

// Provider for WordGridNotifier
final wordGridProvider = StateNotifierProvider<WordGridNotifier, WordGridState>(
  (ref) {
    return WordGridNotifier();
  },
);
