// lib/widgets/vocabulary_detail_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/models/vocabulary_item.dart';
import 'package:myapp/providers/vocabulary_provider.dart'; // For vocabularyDetailLanguageProvider
import 'package:myapp/l10n/app_localizations.dart'; // For localizations

class VocabularyDetailCard extends ConsumerWidget {
  final VocabularyItem vocabularyItem;

  const VocabularyDetailCard({super.key, required this.vocabularyItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final selectedLanguage = ref.watch(vocabularyDetailLanguageProvider);
    final languageNotifier = ref.read(vocabularyDetailLanguageProvider.notifier);

    // Helper to get localized text or a fallback
    String getLocalizedText(Map<String, String>? texts, String lang) {
      if (texts == null || texts.isEmpty) return localizations.notAvailableFallback; // Use a localized "N/A"
      return texts[lang] ?? texts['en'] ?? texts.values.first; // Fallback logic
    }

    List<String> getLocalizedList(Map<String, List<String>>? lists, String lang) {
      if (lists == null || lists.isEmpty) return [localizations.notAvailableFallback];
      return lists[lang] ?? lists['en'] ?? lists.values.first;
    }

    final currentDefinition = getLocalizedText(vocabularyItem.definitions, selectedLanguage);
    final currentExampleSentences = getLocalizedList(vocabularyItem.exampleSentences, selectedLanguage);

    return DraggableScrollableSheet(
        initialChildSize: 1.0, // Start fully expanded
        minChildSize: 0.5, // Minimum size when dragging down
        maxChildSize: 1.0, // Can take full screen
        expand: false, // Content drives the size
        builder: (_, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ListView(
              controller: scrollController,
              children: <Widget>[
                // Header: Word and Language Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        vocabularyItem.word,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Language Segmented Button
                    SegmentedButton<String>(
                      segments: <ButtonSegment<String>>[
                        ButtonSegment<String>(
                            value: 'de',
                            label: Text(localizations.languageCodeDe.toUpperCase()), // Use localized language codes
                            icon: null), // Icon can be added if desired
                        ButtonSegment<String>(
                            value: 'en',
                            label: Text(localizations.languageCodeEn.toUpperCase()),
                            icon: null),
                        ButtonSegment<String>(
                            value: 'es',
                            label: Text(localizations.languageCodeEs.toUpperCase()),
                            icon: null),
                      ],
                      selected: {selectedLanguage},
                      onSelectionChanged: (Set<String> newSelection) {
                        languageNotifier.state = newSelection.first;
                      },
                      style: SegmentedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        textStyle: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                const SizedBox(height: 12),

                // Definition
                _buildSectionTitle(context, localizations.definitionSectionTitle),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      currentDefinition,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Synonyms (if any)
                if (vocabularyItem.synonyms.isNotEmpty) ...[
                  _buildSectionTitle(context, localizations.synonymsSectionTitle),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: vocabularyItem.synonyms
                        .map((s) => Chip(
                              label: Text(s),
                              backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.7),
                              labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Collocations (if any)
                if (vocabularyItem.collocations.isNotEmpty) ...[
                  _buildSectionTitle(context, localizations.collocationsSectionTitle),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: vocabularyItem.collocations
                        .map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Text('• $c', style: Theme.of(context).textTheme.bodyMedium),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Example Sentences
                _buildSectionTitle(context, localizations.exampleSentencesSectionTitle),
                if (currentExampleSentences.isNotEmpty && currentExampleSentences.first != localizations.notAvailableFallback)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: currentExampleSentences
                        .map((ex) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.format_quote, size: 16, color: Theme.of(context).colorScheme.secondary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      ex,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  )
                else
                  Text(
                    localizations.noExamplesAvailable, // Use a specific localized string
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                  ),
                const SizedBox(height: 20), // For scroll space at the bottom
              ],
            ),
          );
        });
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.secondary,
            ),
      ),
    );
  }
}

// Add these to your AppLocalizations .arb files:
// "notAvailableFallback": "N/A",
// "definitionSectionTitle": "Definition",
// "synonymsSectionTitle": "Synonyms",
// "collocationsSectionTitle": "Collocations",
// "exampleSentencesSectionTitle": "Example Sentences",
// "noExamplesAvailable": "No example sentences available for the selected language.",
// "languageCodeDe": "DE",
// "languageCodeEn": "EN",
// "languageCodeEs": "ES",
//
// Example for app_en.arb:
// "notAvailableFallback": "N/A",
// "@notAvailableFallback": { "description": "Fallback text when a piece of information is not available." },
// "definitionSectionTitle": "Definition",
// "@definitionSectionTitle": { "description": "Title for the definition section in vocabulary detail." },
// "synonymsSectionTitle": "Synonyms",
// "@synonymsSectionTitle": { "description": "Title for the synonyms section in vocabulary detail." },
// "collocationsSectionTitle": "Collocations",
// "@collocationsSectionTitle": { "description": "Title for the collocations section in vocabulary detail." },
// "exampleSentencesSectionTitle": "Example Sentences",
// "@exampleSentencesSectionTitle": { "description": "Title for the example sentences section in vocabulary detail." },
// "noExamplesAvailable": "No example sentences available for the selected language.",
// "@noExamplesAvailable": { "description": "Message shown when no example sentences are available for the selected language." },
// "languageCodeDe": "DE",
// "@languageCodeDe": { "description": "Abbreviation for German language." },
// "languageCodeEn": "EN",
// "@languageCodeEn": { "description": "Abbreviation for English language." },
// "languageCodeEs": "ES",
// "@languageCodeEs": { "description": "Abbreviation for Spanish language." }
//
// Remember to run `flutter pub run build_runner build --delete-conflicting-outputs` after adding these.
