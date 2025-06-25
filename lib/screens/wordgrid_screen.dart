// lib/screens/word_grid_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/l10n/app_localizations.dart';
import 'package:myapp/providers/word_grid_provider.dart';
import 'package:myapp/widgets/grid_cell.dart'; // For GridCell and SelectionStatus

class WordGridScreen extends ConsumerStatefulWidget {
  const WordGridScreen({super.key});

  @override
  ConsumerState<WordGridScreen> createState() => _WordGridScreenState();
}

class _WordGridScreenState extends ConsumerState<WordGridScreen> {
  final List<List<String>> _initialGridLetters = [
    ['F', 'L', 'U', 'T', 'T', 'E', 'R', 'A', 'B', 'C'],
    ['D', 'A', 'R', 'T', 'X', 'Y', 'Z', 'P', 'Q', 'R'],
    ['H', 'E', 'L', 'L', 'O', 'W', 'O', 'R', 'L', 'D'],
    ['S', 'U', 'N', 'N', 'E', 'S', 'T', 'V', 'W', 'X'],
    ['G', 'R', 'I', 'D', 'A', 'B', 'C', 'D', 'E', 'F'],
    ['J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S'],
    ['T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'A', 'B', 'C'],
    ['D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M'],
    ['N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W'],
    ['X', 'Y', 'Z', 'H', 'A', 'U', 'S', 'B', 'A', 'U'],
  ];
  final List<String> _hiddenWords = [
    'FLUTTER',
    'DART',
    'HELLO',
    'WORLD',
    'SUN',
    'GRID',
    'HAUS',
    'BAUM',
  ];

  final GlobalKey _gridKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(wordGridProvider.notifier)
            .initializeGrid(_initialGridLetters, _hiddenWords);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final wordGridState = ref.watch(wordGridProvider);
    final wordGridNotifier = ref.read(wordGridProvider.notifier);

    ref.listen<WordGridState>(wordGridProvider, (previous, next) {
      if (next.feedbackMessageKey != null &&
          next.feedbackMessageKey!.isNotEmpty) {
        if (previous?.feedbackMessageKey != next.feedbackMessageKey ||
            previous?.feedbackMessageArg != next.feedbackMessageArg) {
          String message;
          final key = next.feedbackMessageKey!;
          final arg = next.feedbackMessageArg;

          if (key == "feedbackWordFound" && arg != null) {
            message = localizations.feedbackWordFound(arg);
          } else if (key == "feedbackWordAlreadyFound" && arg != null) {
            message = localizations.feedbackWordAlreadyFound(arg);
          } else if (key == "feedbackWordNotValid" && arg != null) {
            message = localizations.feedbackWordNotValid(arg);
          } else if (key == "feedbackSelectionNotStraight") {
            message = localizations.feedbackSelectionNotStraight;
          } else {
            message = key; // Fallback, should ideally map all known keys
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 2),
            ),
          );
          wordGridNotifier.clearFeedbackMessage();
        }
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(localizations.wordGridScreenTitle)),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              alignment: Alignment.center,
              child: Text(
                "${localizations.selectedWordPrefix}${wordGridState.currentWord.toUpperCase()}",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final Size gridSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );

                  if (wordGridState.gridLetters.isEmpty ||
                      wordGridState.crossAxisCount == 0) {
                    return Center(
                      child: Text(localizations.gridLoadingPlaceholder),
                    );
                  }

                  return GestureDetector(
                    onPanStart: (details) {
                      wordGridNotifier.handlePanStart(
                        details.localPosition,
                        gridSize,
                      );
                    },
                    onPanUpdate: (details) {
                      wordGridNotifier.handlePanUpdate(
                        details.localPosition,
                        gridSize,
                      );
                    },
                    onPanEnd: (details) {
                      wordGridNotifier.handlePanEnd();
                    },
                    child: Container(
                      key: _gridKey,
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(0.1),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount:
                            wordGridState.gridLetters.length *
                            wordGridState.crossAxisCount,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: wordGridState.crossAxisCount,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 2.0,
                          mainAxisSpacing: 2.0,
                        ),
                        itemBuilder: (context, index) {
                          final int row = index ~/ wordGridState.crossAxisCount;
                          final int col = index % wordGridState.crossAxisCount;
                          final letter = wordGridState.gridLetters[row][col];
                          final status = wordGridState.cellStatuses[row][col];
                          return GridCell(letter: letter, status: status);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(
                  spacing: 8.0,
                  children: [
                    Text(
                      localizations.foundWordsPrefix,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ...wordGridState.foundWords
                        .map((word) => Chip(label: Text(word)))
                        .toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
