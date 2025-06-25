// lib/screens/word_grid_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/l10n/app_localizations.dart';
import 'package:myapp/models/topic_model.dart'; // For passing Topic
import 'package:myapp/models/vocabulary_item.dart';
import 'package:myapp/providers/word_grid_provider.dart';
import 'package:myapp/providers/vocabulary_provider.dart'; // Import vocabulary providers
import 'package:myapp/widgets/grid_cell.dart'; // For GridCell and SelectionStatus
import 'package:myapp/widgets/vocabulary_detail_card.dart'; // Import the detail card

class WordGridScreen extends ConsumerStatefulWidget {
  final Topic topic; // Accept the current topic

  const WordGridScreen({super.key, required this.topic});

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
    // Set the current topic ID for vocabulary loading when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(currentTopicIdForVocabularyProvider.notifier).state = widget.topic.id;
        // Initialize the grid with some default letters or fetch dynamically
        // For now, we keep the static initialization for the grid itself.
        // Vocabulary words will be loaded separately and used for validation.
        ref
            .read(wordGridProvider.notifier)
            .initializeGrid(_initialGridLetters, _hiddenWords);

        // Potentially, _hiddenWords could be derived from the vocabulary for the topic
        // For example:
        // final vocabularyAsyncValue = ref.read(currentVocabularyListProvider);
        // vocabularyAsyncValue.whenData((vocabulary) {
        //   final wordsFromVocab = vocabulary.map((item) => item.word.toUpperCase()).toList();
        //   ref.read(wordGridProvider.notifier).initializeGrid(_initialGridLetters, wordsFromVocab);
        // });
      }
    });
  }

  // Method to show vocabulary details
  void _showVocabularyDetails(BuildContext context, VocabularyItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Important for taller content
      builder: (BuildContext bc) {
        return FractionallySizedBox(
          heightFactor: 0.75, // Adjust as needed, e.g., 75% of screen height
          child: VocabularyDetailCard(vocabularyItem: item),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final wordGridState = ref.watch(wordGridProvider);
    final wordGridNotifier = ref.read(wordGridProvider.notifier);
    final vocabularyAsyncValue = ref.watch(currentVocabularyListProvider);

    // Listen to feedback messages from WordGridProvider
    ref.listen<WordGridState>(wordGridProvider, (previous, next) {
      if (next.feedbackMessageKey != null && next.feedbackMessageKey!.isNotEmpty) {
        // Ensure message is shown only once
        if (previous?.feedbackMessageKey != next.feedbackMessageKey ||
            previous?.feedbackMessageArg != next.feedbackMessageArg) {
          String message;
          final key = next.feedbackMessageKey!;
          final arg = next.feedbackMessageArg;

          if (key == "feedbackWordFound" && arg != null) {
            message = localizations.feedbackWordFound(arg);
            // Find the VocabularyItem and show details
            vocabularyAsyncValue.whenData((vocabList) {
              final foundItem = vocabList.firstWhere(
                (item) => item.word.toUpperCase() == arg.toUpperCase(),
                orElse: () => VocabularyItem( // Dummy item if not found, though it should be.
                  id: '', word: arg, definitions: {}, synonyms: [], collocations: [],
                  exampleSentences: {}, sourceType: SourceType.predefined, topicId: widget.topic.id
                ),
              );
              // Check if a valid item was found (not the dummy)
              if (foundItem.id.isNotEmpty || vocabList.any((item) => item.word.toUpperCase() == arg.toUpperCase())) {
                 // Update the selected item for the detail card
                ref.read(selectedVocabularyItemProvider.notifier).state = foundItem;
                _showVocabularyDetails(context, foundItem);
              }
            });
          } else if (key == "feedbackWordAlreadyFound" && arg != null) {
            message = localizations.feedbackWordAlreadyFound(arg);
          } else if (key == "feedbackWordNotValid" && arg != null) {
            message = localizations.feedbackWordNotValid(arg);
          } else if (key == "feedbackSelectionNotStraight") {
            message = localizations.feedbackSelectionNotStraight;
          } else {
            message = key; // Fallback
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
          );
          wordGridNotifier.clearFeedbackMessage(); // Clear after showing
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topic.title(localizations.localeName)), // Use topic title
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Display current selection
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              alignment: Alignment.center,
              child: Text(
                "${localizations.selectedWordPrefix}${wordGridState.currentWord.toUpperCase()}",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 10),

            // Word Grid
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final Size gridSize = Size(constraints.maxWidth, constraints.maxHeight);
                  if (wordGridState.gridLetters.isEmpty || wordGridState.crossAxisCount == 0) {
                    return Center(child: Text(localizations.gridLoadingPlaceholder));
                  }
                  return GestureDetector(
                    onPanStart: (details) => wordGridNotifier.handlePanStart(details.localPosition, gridSize),
                    onPanUpdate: (details) => wordGridNotifier.handlePanUpdate(details.localPosition, gridSize),
                    onPanEnd: (_) => wordGridNotifier.handlePanEnd(),
                    child: Container(
                      key: _gridKey,
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: wordGridState.gridLetters.length * wordGridState.crossAxisCount,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: wordGridState.crossAxisCount,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 2.0,
                          mainAxisSpacing: 2.0,
                        ),
                        itemBuilder: (context, index) {
                          final int row = index ~/ wordGridState.crossAxisCount;
                          final int col = index % wordGridState.crossAxisCount;
                          return GridCell(
                            letter: wordGridState.gridLetters[row][col],
                            status: wordGridState.cellStatuses[row][col],
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Found Words Chips (clickable to show details again)
            SizedBox(
              height: 60, // Increased height for better touchability
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.foundWordsPrefix,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Expanded(
                    child: vocabularyAsyncValue.when(
                      data: (vocabList) {
                        // Filter found words that are actual vocabulary items
                        final foundVocabularyWords = wordGridState.foundWords.where((foundWord) =>
                            vocabList.any((vocabItem) => vocabItem.word.toUpperCase() == foundWord.toUpperCase())
                        ).toList();

                        if (foundVocabularyWords.isEmpty) {
                          return Center(
                            child: Text(
                              localizations.noWordsFoundYet, // Add this to AppLocalizations
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        }
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Wrap(
                            spacing: 8.0,
                            children: foundVocabularyWords.map((word) {
                              final vocabItem = vocabList.firstWhere(
                                (item) => item.word.toUpperCase() == word.toUpperCase()
                              );
                              return ActionChip(
                                label: Text(word),
                                onPressed: () {
                                  ref.read(selectedVocabularyItemProvider.notifier).state = vocabItem;
                                  _showVocabularyDetails(context, vocabItem);
                                },
                              );
                            }).toList(),
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Vocabulary List for the current topic (for debugging/verification)
            // This can be removed or placed in a different screen/tab later.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text("Vocabulary for this Topic:", style: Theme.of(context).textTheme.titleSmall),
            ),
            Expanded(
              flex: 0, // Takes minimum space needed
              child: vocabularyAsyncValue.when(
                data: (vocabulary) {
                  if (vocabulary.isEmpty) {
                    return const Center(child: Text("No vocabulary items for this topic."));
                  }
                  return SizedBox( // Constrain height if it becomes too long
                    height: 100, // Example fixed height
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: vocabulary.length,
                      itemBuilder: (context, index) {
                        final item = vocabulary[index];
                        return ListTile(
                          title: Text(item.word),
                          subtitle: Text(item.definitions[ref.watch(vocabularyDetailLanguageProvider)] ?? 'No definition'),
                          dense: true,
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator.adaptive()),
                error: (err, stack) => Center(child: Text('Error loading vocabulary: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
