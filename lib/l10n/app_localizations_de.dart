// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'CAINS App';

  @override
  String get loginButton => 'Anmelden';

  @override
  String get registerButton => 'Registrieren';

  @override
  String get homePageTitle => 'Startseite';

  @override
  String get loginScreenTitle => 'Anmelden';

  @override
  String get emailFieldLabel => 'E-Mail';

  @override
  String get emailFieldHint => 'Geben Sie Ihre E-Mail-Adresse ein';

  @override
  String get emailValidationErrorEmpty => 'Bitte geben Sie Ihre E-Mail-Adresse ein';

  @override
  String get emailValidationErrorFormat => 'Bitte geben Sie eine gültige E-Mail-Adresse ein';

  @override
  String get passwordFieldLabel => 'Passwort';

  @override
  String get passwordFieldHint => 'Geben Sie Ihr Passwort ein';

  @override
  String get passwordValidationErrorEmpty => 'Bitte geben Sie Ihr Passwort ein';

  @override
  String get passwordValidationErrorLength => 'Das Passwort muss mindestens 6 Zeichen lang sein';

  @override
  String get dontHaveAccountPrompt => 'Kein Konto? Registrieren';

  @override
  String get registrationScreenTitle => 'Registrieren';

  @override
  String get confirmPasswordFieldLabel => 'Passwort bestätigen';

  @override
  String get confirmPasswordFieldHint => 'Bestätigen Sie Ihr Passwort';

  @override
  String get confirmPasswordValidationErrorEmpty => 'Bitte bestätigen Sie Ihr Passwort';

  @override
  String get confirmPasswordValidationErrorMatch => 'Die Passwörter stimmen nicht überein';

  @override
  String get alreadyHaveAccountPrompt => 'Bereits ein Konto? Anmelden';

  @override
  String get loadingText => 'Wird geladen...';

  @override
  String get pageNotFoundScreenTitle => 'Seite nicht gefunden';

  @override
  String get pageNotFoundGenericMessage => 'Hoppla! Etwas ist schiefgelaufen oder die Seite existiert nicht.';

  @override
  String get pageNotFoundErrorMessagePrefix => 'Fehler: ';

  @override
  String get welcomeMessage => 'Willkommen bei der CAINS App!';

  @override
  String get wordGridGameButton => 'Wortgitter Spiel';

  @override
  String get aiWordResearchButton => 'KI Wortrecherche';

  @override
  String get scanTextButton => 'Text Scannen';

  @override
  String get signOutButtonTooltip => 'Abmelden';

  @override
  String get languageMenuTooltip => 'Sprachoptionen';

  @override
  String get settingsMenuTooltip => 'Einstellungen';

  @override
  String get logoutDialogTitle => 'Abmeldung bestätigen';

  @override
  String get logoutDialogContent => 'Möchten Sie sich wirklich abmelden?';

  @override
  String get cancelButtonLabel => 'Abbrechen';

  @override
  String get logoutButtonLabel => 'Abmelden';

  @override
  String get switchToLightModeLabel => 'Heller Modus';

  @override
  String get switchToDarkModeLabel => 'Dunkler Modus';

  @override
  String pointsLabel(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points Punkte',
      one: '$points Punkt',
    );
    return '$_temp0';
  }

  @override
  String get overallProgressLabel => 'Gesamtfortschritt';

  @override
  String get challengeStatusOpen => 'Offen';

  @override
  String get challengeStatusCompleted => 'Abgeschlossen';

  @override
  String get startChallengeButtonLabel => 'Herausforderung starten';

  @override
  String get noTopicsAvailableMessage => 'Derzeit sind keine Themen verfügbar. Schauen Sie später noch einmal vorbei!';

  @override
  String get errorLoadingTopicsMessage => 'Themen konnten nicht geladen werden. Bitte versuchen Sie es erneut.';

  @override
  String get wordGridScreenTitle => 'Wortgitter';

  @override
  String get selectedWordPrefix => 'Ausgewählt: ';

  @override
  String get gridLoadingPlaceholder => 'Gitter erscheint hier...';

  @override
  String get foundWordsPrefix => 'Gefundene Wörter: ';

  @override
  String get resetSelectionTooltip => 'Auswahl zurücksetzen';

  @override
  String feedbackWordFound(String word) {
    return 'Wort gefunden: $word!';
  }

  @override
  String feedbackWordAlreadyFound(String word) {
    return 'Bereits gefunden: $word';
  }

  @override
  String feedbackWordNotValid(String word) {
    return 'Ungültiges Wort: $word';
  }

  @override
  String get feedbackSelectionNotStraight => 'Auswahl muss eine gerade Linie sein.';

  @override
  String get noWordsFoundYet => 'Noch keine Wörter gefunden.';

  @override
  String get errorLoadingChallengeMessage => 'Die heutige Herausforderung konnte nicht geladen werden.';

  @override
  String get retryButtonLabel => 'Wiederholen';

  @override
  String get getTodaysChallengeButtonLabel => 'Heutige Herausforderung holen';

  @override
  String get notAvailableFallback => 'N.V.';

  @override
  String get definitionSectionTitle => 'Definition';

  @override
  String get synonymsSectionTitle => 'Synonyme';

  @override
  String get collocationsSectionTitle => 'Kollokationen';

  @override
  String get exampleSentencesSectionTitle => 'Beispielsätze';

  @override
  String get noExamplesAvailable => 'Keine Beispielsätze für die ausgewählte Sprache verfügbar.';

  @override
  String get languageCodeDe => 'DE';

  @override
  String get languageCodeEn => 'EN';

  @override
  String get languageCodeEs => 'ES';
}
