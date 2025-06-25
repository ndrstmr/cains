// test/widgets/vocabulary_detail_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/l10n/app_localizations.dart';
import 'package:myapp/models/vocabulary_item.dart';
import 'package:myapp/providers/vocabulary_provider.dart';
import 'package:myapp/widgets/vocabulary_detail_card.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// A GlobalKey to access the ScaffoldMessengerState
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();


// Helper to pump the widget with necessary providers and localization
Future<void> pumpVocabularyDetailCard(
  WidgetTester tester,
  VocabularyItem item, {
  String initialLanguage = 'de',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vocabularyDetailLanguageProvider.overrideWith((ref) => initialLanguage),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: scaffoldMessengerKey, // For SnackBars if any are triggered by mistake
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          // The VocabularyDetailCard is designed to be in a BottomSheet or similar,
          // but for testing, we can embed it directly or within a minimal structure.
          // Using a SizedBox to constrain its height if needed, or letting it expand.
          body: VocabularyDetailCard(vocabularyItem: item),
        ),
      ),
    ),
  );
  // Ensure all frames are processed, especially for initial state.
  await tester.pumpAndSettle();
}

void main() {
  // Sample VocabularyItem for testing
  final sampleItem = VocabularyItem(
    id: 'vocab1',
    word: 'Beispielwort',
    definitions: {
      'de': 'Deutsche Definition.',
      'en': 'English definition.',
      'es': 'Definición en español.',
    },
    synonyms: ['Synonym1', 'Synonym2'],
    collocations: ['Kollokation A', 'Kollokation B'],
    exampleSentences: {
      'de': ['Deutscher Beispielsatz 1.'],
      'en': ['English example sentence 1.'],
      'es': ['Ejemplo de frase en español 1.'],
    },
    level: 'C1',
    sourceType: SourceType.predefined,
    topicId: 'topic1',
  );

  final sampleItemNoOptional = VocabularyItem(
    id: 'vocab2',
    word: 'TestWortOhneOptional',
    definitions: {
      'de': 'DE Def.',
      'en': 'EN Def.',
    },
    synonyms: [], // Empty
    collocations: [], // Empty
    exampleSentences: { // Only one language, one empty
      'de': ['DE Satz.'],
      'es': [],
    },
    level: 'C1',
    sourceType: SourceType.ai_added,
    topicId: 'topic2',
  );


  group('VocabularyDetailCard Widget Tests', () {
    testWidgets('renders basic vocabulary information correctly', (WidgetTester tester) async {
      await pumpVocabularyDetailCard(tester, sampleItem);

      // Check if the word is displayed
      expect(find.text(sampleItem.word), findsOneWidget);

      // Check if the German definition is displayed (default language)
      expect(find.text(sampleItem.definitions['de']!), findsOneWidget);

      // Check for synonyms
      for (var syn in sampleItem.synonyms) {
        expect(find.widgetWithText(Chip, syn), findsOneWidget);
      }

      // Check for collocations
      for (var col in sampleItem.collocations) {
        expect(find.text('• $col'), findsOneWidget);
      }

      // Check for German example sentence
      expect(find.text(sampleItem.exampleSentences['de']!.first), findsOneWidget);
    });

    testWidgets('language switching changes definition and example sentences', (WidgetTester tester) async {
      await pumpVocabularyDetailCard(tester, sampleItem, initialLanguage: 'de');

      // Initially German
      expect(find.text(sampleItem.definitions['de']!), findsOneWidget, reason: "German definition should be visible initially");
      expect(find.text(sampleItem.exampleSentences['de']!.first), findsOneWidget, reason: "German example sentence should be visible initially");

      // Find the English language button (SegmentedButton segment)
      // The SegmentedButton's segments are ButtonSegment<String> which render a Text widget with the capitalized lang code
      await tester.tap(find.widgetWithText(ButtonSegment, 'EN'));
      await tester.pumpAndSettle(); // Rebuild with new language

      // Check for English definition and example
      expect(find.text(sampleItem.definitions['en']!), findsOneWidget, reason: "English definition should be visible after switching to EN");
      expect(find.text(sampleItem.exampleSentences['en']!.first), findsOneWidget, reason: "English example sentence should be visible after switching to EN");
      expect(find.text(sampleItem.definitions['de']!), findsNothing, reason: "German definition should NOT be visible after switching to EN");


      // Switch to Spanish
      await tester.tap(find.widgetWithText(ButtonSegment, 'ES'));
      await tester.pumpAndSettle();

      // Check for Spanish definition and example
      expect(find.text(sampleItem.definitions['es']!), findsOneWidget, reason: "Spanish definition should be visible after switching to ES");
      expect(find.text(sampleItem.exampleSentences['es']!.first), findsOneWidget, reason: "Spanish example sentence should be visible after switching to ES");
      expect(find.text(sampleItem.definitions['en']!), findsNothing, reason: "English definition should NOT be visible after switching to ES");
    });

    testWidgets('handles items with missing optional data gracefully', (WidgetTester tester) async {
      await pumpVocabularyDetailCard(tester, sampleItemNoOptional, initialLanguage: 'de');

      expect(find.text(sampleItemNoOptional.word), findsOneWidget);
      expect(find.text(sampleItemNoOptional.definitions['de']!), findsOneWidget);

      // Synonyms and Collocations sections might not appear or show "N/A" depending on implementation
      // The current implementation hides the section if the list is empty.
      expect(find.text('Synonyms'), findsNothing); // Assuming section title is "Synonyms" via localization
      expect(find.text('Collocations'), findsNothing); // Assuming section title is "Collocations"

      // Example sentences (German should be there)
      expect(find.text(sampleItemNoOptional.exampleSentences['de']!.first), findsOneWidget);

      // Switch to English - definition should fallback, examples might show "No examples available"
      await tester.tap(find.widgetWithText(ButtonSegment, 'EN'));
      await tester.pumpAndSettle();

      expect(find.text(sampleItemNoOptional.definitions['en']!), findsOneWidget, reason: "EN definition should be present");
      // Check for "No example sentences available for the selected language."
      // This requires AppLocalizations to be loaded.
      final localizations = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(localizations.noExamplesAvailable), findsOneWidget, reason: "Should show 'no examples' for EN");
    });

    testWidgets('fallback for definitions and examples works', (WidgetTester tester) async {
      final itemWithMissingLang = VocabularyItem(
        id: 'vocab3',
        word: 'FallbackWort',
        definitions: {'en': 'English only definition.'}, // No 'de' or 'es'
        synonyms: [],
        collocations: [],
        exampleSentences: {'en': ['English only example.']}, // No 'de' or 'es'
        level: 'C1',
        sourceType: SourceType.predefined,
        topicId: 'topic3',
      );

      await pumpVocabularyDetailCard(tester, itemWithMissingLang, initialLanguage: 'de');
      final localizations = await AppLocalizations.delegate.load(const Locale('de'));


      // Default is 'de'. Since 'de' is missing, it should fallback to 'en' (as per current logic in VocabularyDetailCard)
      expect(find.text(itemWithMissingLang.definitions['en']!), findsOneWidget, reason: "Should fallback to EN definition when DE is missing.");
      expect(find.text(itemWithMissingLang.exampleSentences['en']!.first), findsOneWidget, reason: "Should fallback to EN example when DE is missing.");

      // Switch to Spanish, should also fallback to English
      await tester.tap(find.widgetWithText(ButtonSegment, 'ES'));
      await tester.pumpAndSettle();
      expect(find.text(itemWithMissingLang.definitions['en']!), findsOneWidget, reason: "Should fallback to EN definition when ES is missing.");
      expect(find.text(itemWithMissingLang.exampleSentences['en']!.first), findsOneWidget, reason: "Should fallback to EN example when ES is missing.");

      // Switch to English, should show English
      await tester.tap(find.widgetWithText(ButtonSegment, 'EN'));
      await tester.pumpAndSettle();
      expect(find.text(itemWithMissingLang.definitions['en']!), findsOneWidget);
      expect(find.text(itemWithMissingLang.exampleSentences['en']!.first), findsOneWidget);
    });

     testWidgets('displays "N/A" or "No examples" for completely empty fields', (WidgetTester tester) async {
      final itemWithNoExamplesOrDefForLang = VocabularyItem(
        id: 'vocab4',
        word: 'MinimalWord',
        definitions: {'en': 'Definition here'}, // only 'en'
        synonyms: [],
        collocations: [],
        exampleSentences: {}, // completely empty examples
        level: 'C1',
        sourceType: SourceType.predefined,
        topicId: 'topic4',
      );

      await pumpVocabularyDetailCard(tester, itemWithNoExamplesOrDefForLang, initialLanguage: 'de');
      final deLocalizations = await AppLocalizations.delegate.load(const Locale('de'));

      // Definition for 'de' should fallback to 'en'
      expect(find.text(itemWithNoExamplesOrDefForLang.definitions['en']!), findsOneWidget);

      // Example sentences for 'de' should show "No examples available"
      expect(find.text(deLocalizations.noExamplesAvailable), findsOneWidget);

      // Switch to English
      await tester.tap(find.widgetWithText(ButtonSegment, 'EN'));
      await tester.pumpAndSettle();
      final enLocalizations = await AppLocalizations.delegate.load(const Locale('en'));

      expect(find.text(itemWithNoExamplesOrDefForLang.definitions['en']!), findsOneWidget);
      expect(find.text(enLocalizations.noExamplesAvailable), findsOneWidget);

    });

  });
}
