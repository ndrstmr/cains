// Screen for AI-powered word research.
// Allows users to input a word and get AI-generated information.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cains/utils/app_localizations.dart'; // Will be used later
import 'package:cains/providers/ai_research_provider.dart';
import 'package:cains/models/vocabulary_item.dart';

class AIResearchScreen extends ConsumerWidget {
  const AIResearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final state = ref.watch(aiResearchProvider);
    final notifier = ref.read(aiResearchProvider.notifier);

    // Use a listener for one-off actions like showing SnackBars for errors/successes
    // that are not part of the declarative UI build.
    ref.listen<AIResearchState>(aiResearchProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        // Clear any existing snackbars first
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        // Optionally clear the error from state after showing it,
        // so it doesn't reappear on rebuild if not handled by another action.
        // notifier.clearError(); // Or handle clearing in provider
      }
      if (next.successMessage != null && next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        // notifier.clearSuccessMessage(); // Or handle clearing in provider
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.aiResearchScreenTitle ?? 'AI Word Research'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Text form field for word input
              TextFormField(
                controller: notifier.wordController,
                decoration: InputDecoration(
                  labelText: localizations?.enterWordLabel ?? 'Enter word',
                  hintText: localizations?.enterWordHint ?? 'e.g. Demography',
                  border: const OutlineInputBorder(),
                  // Show error directly on the text field if it's about empty input,
                  // or rely on SnackBar for other errors.
                  errorText: state.errorMessage == (localizations?.pleaseEnterWordMessage ?? 'Please enter a word.')
                      ? state.errorMessage // Show specific error on field
                      : null,
                  // errorText: state.errorMessage != null && state.currentWord.isEmpty ? state.errorMessage : null,
                ),
                onChanged: (value) {
                   notifier.onWordChanged(value);
                },
                onFieldSubmitted: (_) {
                  if (!state.isLoading) {
                    FocusScope.of(context).unfocus(); // Hide keyboard
                    notifier.fetchAiResults();
                  }
                },
              ),
              const SizedBox(height: 16.0),

              // Search button
              ElevatedButton(
                onPressed: state.isLoading ? null : () {
                  FocusScope.of(context).unfocus(); // Hide keyboard
                  notifier.fetchAiResults();
                },
                child: state.isLoading
                       ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white))
                       : Text(localizations?.searchButtonLabel ?? 'Search'),
              ),
              const SizedBox(height: 24.0),

              // Loading indicator for page content (if search button has its own)
              // if (state.isLoading)
              //   const Center(child: CircularProgressIndicator()),
              // SnackBar is used for general error messages now.
              // if (state.errorMessage != null && !state.isLoading)
              //   Padding(
              //     padding: const EdgeInsets.only(bottom: 16.0),
              //     child: Text(
              //       state.errorMessage!,
              //       style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16),
              //       textAlign: TextAlign.center,
              //     ),
              //   ),

              // Results display area
              if (state.result != null && !state.isLoading)
                _buildResultsDisplay(context, localizations, state.result!),
              else if (!state.isLoading &&
                       state.errorMessage == null &&
                       notifier.wordController.text.isEmpty && // Show initial message if input is empty
                       state.result == null)
                 Center(child: Text(localizations?.noResultsMessage ?? 'AI results will be displayed here.')),
              else if (!state.isLoading &&
                       state.errorMessage == null &&
                       notifier.wordController.text.isNotEmpty && // Show prompt to search if input has text but no search yet or cleared
                       state.result == null)
                 Center(child: Text(localizations?.enterWordAndSearchMessage ?? 'Enter a word and press Search.')),


              const SizedBox(height: 16.0),

              // "Add to vocabulary" button
              if (state.result != null && !state.isLoading)
                ElevatedButton.icon(
                  icon: state.isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.0))
                        : const Icon(Icons.add_circle_outline),
                  label: Text(state.isSaving
                                ? (localizations?.savingButtonLabel ?? 'Saving...')
                                : (localizations?.addToVocabularyButtonLabel ?? 'Add to Vocabulary List')),
                  onPressed: state.isSaving ? null : () {
                    notifier.saveToVocabulary();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsDisplay(BuildContext context, AppLocalizations? localizations, VocabularyItem result) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2.0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.word, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16.0),

            _buildSectionTitle(context, localizations?.definitionTitleDe ?? 'Definition (DE)'),
            Text(result.definitions['de'] ?? result.definitions.values.firstOrNull ?? localizations?.notAvailableFallback ?? 'N/A'),
            if (result.definitions['en'] != null) ...[
                 const SizedBox(height: 8.0),
                _buildSectionTitle(context, localizations?.definitionTitleEn ?? 'Definition (EN)'),
                 Text(result.definitions['en']!),
            ],
            if (result.definitions['es'] != null) ...[
                 const SizedBox(height: 8.0),
                _buildSectionTitle(context, localizations?.definitionTitleEs ?? 'Definition (ES)'),
                 Text(result.definitions['es']!),
            ],
            const SizedBox(height: 16.0),

            _buildSectionTitle(context, localizations?.exampleSentencesTitleDe ?? 'Example Sentences (DE)'),
            ...(result.exampleSentences['de'] ?? [localizations?.notAvailableFallback ?? 'N/A']).map((s) => Text('• $s', style: textTheme.bodyMedium)),
             if (result.exampleSentences['en'] != null && result.exampleSentences['en']!.isNotEmpty) ...[
                const SizedBox(height: 8.0),
                _buildSectionTitle(context, localizations?.exampleSentencesTitleEn ?? 'Example Sentences (EN)'),
                ...result.exampleSentences['en']!.map((s) => Text('• $s', style: textTheme.bodyMedium)),
            ],
            if (result.exampleSentences['es'] != null && result.exampleSentences['es']!.isNotEmpty) ...[
                const SizedBox(height: 8.0),
                _buildSectionTitle(context, localizations?.exampleSentencesTitleEs ?? 'Example Sentences (ES)'),
                ...result.exampleSentences['es']!.map((s) => Text('• $s', style: textTheme.bodyMedium)),
            ],
            const SizedBox(height: 16.0),

            _buildSectionTitle(context, localizations?.synonymsTitle ?? 'Synonyms'),
            Text(result.synonyms.isNotEmpty ? result.synonyms.join(', ') : localizations?.notAvailableFallback ?? 'N/A'),
            const SizedBox(height: 16.0),

            _buildSectionTitle(context, localizations?.collocationsTitle ?? 'Collocations'),
            Text(result.collocations.isNotEmpty ? result.collocations.join('; ') : localizations?.notAvailableFallback ?? 'N/A'),
            const SizedBox(height: 16.0),

            if (result.grammarHint != null && result.grammarHint!.isNotEmpty) ...[
              _buildSectionTitle(context, localizations?.grammarHintTitle ?? 'Grammar Hint'),
              Text(result.grammarHint!),
              const SizedBox(height: 16.0),
            ],

            if (result.contextualText != null && result.contextualText!.isNotEmpty) ...[
              _buildSectionTitle(context, localizations?.contextualTextTitle ?? 'Contextual Text'),
              Text(result.contextualText!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
