// lib/utils/app_localizations.dart
import 'package:flutter/material.dart';

// This is a simplified mock for AppLocalizations.
// A real implementation would use flutter_localizations and .arb files.

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // General
  String get appTitle => locale.languageCode == 'de' ? 'Wortschatz Meister' : 'Vocabulary Master';
  String get cancelButtonLabel => locale.languageCode == 'de' ? 'Abbrechen' : 'Cancel';

  // HomeScreen
  String get homePageTitle => locale.languageCode == 'de' ? 'Startseite' : 'Home';
  String get languageMenuTooltip => locale.languageCode == 'de' ? 'Sprache ändern' : 'Change Language';
  String get settingsMenuTooltip => locale.languageCode == 'de' ? 'Einstellungen' : 'Settings';
  String get switchToLightModeLabel => locale.languageCode == 'de' ? 'Heller Modus' : 'Switch to Light Mode';
  String get switchToDarkModeLabel => locale.languageCode == 'de' ? 'Dunkler Modus' : 'Switch to Dark Mode';
  String get logoutButtonLabel => locale.languageCode == 'de' ? 'Abmelden' : 'Logout';
  String get logoutDialogTitle => locale.languageCode == 'de' ? 'Abmelden Bestätigen' : 'Confirm Logout';
  String get logoutDialogContent => locale.languageCode == 'de' ? 'Möchten Sie sich wirklich abmelden?' : 'Are you sure you want to log out?'; // Corrected locale.language_code to locale.languageCode
  String get noTopicsAvailableMessage => locale.languageCode == 'de' ? 'Keine Themen verfügbar.' : 'No topics available.';
  String get errorLoadingTopicsMessage => locale.languageCode == 'de' ? 'Fehler beim Laden der Themen.' : 'Error loading topics.';

  // Progress related
  String pointsLabel(int points) {
    if (locale.languageCode == 'de') {
      return '$points Punkte';
    }
    return '$points Points';
  }
  String get overallProgressLabel => locale.languageCode == 'de' ? 'Gesamtfortschritt' : 'Overall Progress';

  // WordGridScreen
  String get wordGridScreenTitle => locale.languageCode == 'de' ? 'Wortgitter' : 'Word Grid';
  String get topicProgressLabel => locale.languageCode == 'de' ? 'Themenfortschritt' : 'Topic Progress';
  String get wordsFoundInTopicLabel => locale.languageCode == 'de' ? 'Wörter im Thema gefunden' : 'Words found in topic';
  String get noWordsInPuzzleLabel => locale.languageCode == 'de' ? 'Keine Wörter für dieses Puzzle geladen.' : 'No words loaded for this puzzle.';
  String puzzleCompletedBonusLabel(int points) {
    if (locale.languageCode == 'de') {
      return 'Puzzle abgeschlossen! +$points Bonus';
    }
    return 'Puzzle Complete! +$points Bonus';
  }

  // Daily Challenges (HomeScreen)
  String get dailyChallengeSectionTitle => locale.languageCode == 'de' ? 'Tägliche Herausforderung' : 'Daily Challenge';
  String get challengeStatusOpen => locale.languageCode == 'de' ? 'Offen' : 'Open';
  String get challengeStatusCompleted => locale.languageCode == 'de' ? 'Abgeschlossen' : 'Completed';
  String get startChallengeButtonLabel => locale.languageCode == 'de' ? 'Herausforderung starten' : 'Start Challenge';
  String get errorLoadingChallengeMessage => locale.languageCode == 'de' ? 'Heutige Herausforderung konnte nicht geladen werden.' : 'Could not load today\'s challenge.';
  String get retryButtonLabel => locale.languageCode == 'de' ? 'Erneut versuchen' : 'Retry';
  String get getTodaysChallengeButtonLabel => locale.languageCode == 'de' ? 'Heutige Herausforderung abrufen' : 'Get Today\'s Challenge';


  // Add other strings as needed by your application
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'de', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
