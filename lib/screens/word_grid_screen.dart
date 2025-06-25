// lib/screens/word_grid_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp
import 'package:myapp/models/topic_model.dart';
import 'package:myapp/providers/user_progress_provider.dart';
import 'package:myapp/providers/word_grid_provider.dart'; // For WordGridState and wordGridProvider
// For firestoreServiceProvider
// Corrected path based on where app_localizations.dart was created
import 'package:myapp/utils/app_localizations.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

class WordGridScreen extends ConsumerWidget {
  final Topic topic;

  const WordGridScreen({super.key, required this.topic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final userProgressAsyncValue = ref.watch(userProgressProvider);
    final wordGridState = ref.watch(wordGridProvider); // Watch the game state

    // Listener for when words are found
    ref.listen<WordGridState>(wordGridProvider, (previousState, newState) {
      // Ensure previousState is not null and both states are valid
      if (previousState == null || newState.gridLetters.isEmpty) {
        if (kDebugMode && previousState != null && newState.gridLetters.isEmpty && previousState.gridLetters.isNotEmpty) {
          // This might happen if the grid is re-initialized to an empty state.
          // print("WordGridScreen Listener: Grid seems to have been reset or emptied.");
        }
        return;
      }

      final newlyFoundWords = newState.foundWords.difference(previousState.foundWords);

      if (newlyFoundWords.isNotEmpty) {
        final userId = ref.read(currentUserIdProvider);
        final firestoreService = ref.read(firestoreServiceProvider);
        final currentUserModel = ref.read(userProgressProvider).asData?.value;

        if (userId != null && userId.isNotEmpty && currentUserModel != null) {
          int cumulativeNewPoints = currentUserModel.totalPoints;
          int cumulativeWordsFoundCount = currentUserModel.wordsFoundCount;
          // Deep copy topicProgress to avoid modifying the original state directly
          Map<String, Map<String, dynamic>> cumulativeTopicProgress = Map.from(currentUserModel.topicProgress).map(
            (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
          );

          bool puzzleConsideredCompletedThisUpdate = false;

          for (final word in newlyFoundWords) {
            cumulativeNewPoints += 10; // +10 points per word
            cumulativeWordsFoundCount += 1;

            Map<String, dynamic> currentTopicData = cumulativeTopicProgress[topic.id] ?? {};
            currentTopicData['totalWordsFoundInTopic'] = (currentTopicData['totalWordsFoundInTopic'] as int? ?? 0) + 1;
            currentTopicData['lastPlayed'] = Timestamp.now();

            // Check for puzzle completion (all hidden words found)
            // This check should happen once per update cycle if multiple words are found in one go.
            if (!puzzleConsideredCompletedThisUpdate && newState.foundWords.length == newState.hiddenWords.length && newState.hiddenWords.isNotEmpty) {
               currentTopicData['completedPuzzles'] = (currentTopicData['completedPuzzles'] as int? ?? 0) + 1;
               cumulativeNewPoints += 50; // Bonus points for puzzle completion
               puzzleConsideredCompletedThisUpdate = true; // Avoid multiple bonuses if multiple words complete the puzzle simultaneously
               if (kDebugMode) {
                 print("Puzzle completed for topic ${topic.id}! +50 bonus points.");
               }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.puzzleCompletedBonusLabel(50))) // Example: "Puzzle Complete! +50 Bonus"
                );
            }
            cumulativeTopicProgress[topic.id] = Map<String, dynamic>.from(currentTopicData); // Ensure it's a new map instance

            if (kDebugMode) {
              print('Found "$word"! +10 points. User: $userId, Topic: ${topic.id}');
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${localizations.pointsLabel(10)}: $word'))
            );
          }

          Map<String, dynamic> updateData = {
            'totalPoints': cumulativeNewPoints,
            'wordsFoundCount': cumulativeWordsFoundCount,
            'topicProgress': cumulativeTopicProgress,
          };

          firestoreService.updateUserProgress(userId, updateData).catchError((e) {
            if (kDebugMode) {
              print("Error updating user progress for $userId: $e. Data: $updateData");
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving progress: $e')) // TODO: Localize this error
            );
          });
        } else {
          if (kDebugMode) {
            print("User not logged in or user model not available. Cannot update progress.");
            if(userId == null || userId.isEmpty) print("Reason: userId is null or empty.");
            if(currentUserModel == null) print("Reason: currentUserModel is null.");
          }
        }
      }
    });

    double currentTopicProgressPercent = 0.0;
    int wordsFoundInTopicForUI = 0;
    final int totalWordsInPuzzle = wordGridState.hiddenWords.length;

    final userDisplayProgress = userProgressAsyncValue.asData?.value;
    if (userDisplayProgress != null && userDisplayProgress.topicProgress.containsKey(topic.id)) {
      final progressData = userDisplayProgress.topicProgress[topic.id]!;
      wordsFoundInTopicForUI = progressData['totalWordsFoundInTopic'] as int? ?? 0;
      if (totalWordsInPuzzle > 0) {
        currentTopicProgressPercent = (wordsFoundInTopicForUI / totalWordsInPuzzle).clamp(0.0, 1.0);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(topic.titleEn),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.topicProgressLabel,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (totalWordsInPuzzle > 0) ...[
              LinearProgressIndicator(
                value: currentTopicProgressPercent,
                minHeight: 10,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${(currentTopicProgressPercent * 100).toStringAsFixed(0)}% ($wordsFoundInTopicForUI / $totalWordsInPuzzle ${localizations.wordsFoundInTopicLabel})',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ] else ...[
              Text(localizations.noWordsInPuzzleLabel),
            ],
            const SizedBox(height: 20),

            Expanded(
              child: Center(
                child: wordGridState.gridLetters.isEmpty && wordGridState.hiddenWords.isEmpty
                ? Column( // If grid is empty AND no hidden words, probably not initialized for this topic yet
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Loading puzzle..."), // TODO: Localize
                      const SizedBox(height: 10),
                      const CircularProgressIndicator(),
                      // TODO: Add a button or logic in initState/didChangeDependencies to call wordGridProvider.notifier.initializeGrid(...)
                      // For now, this screen assumes the grid is initialized elsewhere or via user action.
                    ],
                  )
                : (wordGridState.gridLetters.isEmpty && wordGridState.hiddenWords.isNotEmpty
                    ? const Text("Grid data is missing but words are expected.") // Should not happen if initialized correctly
                    : Text( // Replace with actual WordGridView widget when available
                        '${localizations.wordGridScreenTitle} for ${topic.titleEn} \n (Grid: ${wordGridState.gridLetters.length}x${wordGridState.crossAxisCount}, Words: ${wordGridState.hiddenWords.length})',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      )
                  )
              ),
            ),
            // Debug: Display hidden words and found words
            // if (kDebugMode) ...[
            //   Text("Words to find: ${wordGridState.hiddenWords.join(', ')}", style: TextStyle(fontSize: 10)),
            //   Text("Found words: ${wordGridState.foundWords.join(', ')}", style: TextStyle(fontSize: 10)),
            // ]
          ],
        ),
      ),
    );
  }
}

// Add to lib/utils/app_localizations.dart:
// String get noWordsInPuzzleLabel => locale.languageCode == 'de' ? 'Keine Wörter für dieses Puzzle geladen.' : 'No words loaded for this puzzle.';
// String puzzleCompletedBonusLabel(int points) => locale.languageCode == 'de' ? 'Puzzle abgeschlossen! +$points Bonus' : 'Puzzle Complete! +$points Bonus';
