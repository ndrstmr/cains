import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'CAINS App'**
  String get appTitle;

  /// Label for the login button
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// Label for the register button
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// Title for the Home Page
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homePageTitle;

  /// Title for the Login Screen AppBar
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginScreenTitle;

  /// Label for email input field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailFieldLabel;

  /// Hint for email input field
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailFieldHint;

  /// Validation error for empty email
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailValidationErrorEmpty;

  /// Validation error for invalid email format
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get emailValidationErrorFormat;

  /// Label for password input field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordFieldLabel;

  /// Hint for password input field
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordFieldHint;

  /// Validation error for empty password
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get passwordValidationErrorEmpty;

  /// Validation error for short password
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters long'**
  String get passwordValidationErrorLength;

  /// Prompt to navigate to registration screen
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get dontHaveAccountPrompt;

  /// Title for the Registration Screen AppBar
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registrationScreenTitle;

  /// Label for confirm password input field
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordFieldLabel;

  /// Hint for confirm password input field
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmPasswordFieldHint;

  /// Validation error for empty confirm password
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordValidationErrorEmpty;

  /// Validation error when passwords do not match
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get confirmPasswordValidationErrorMatch;

  /// Prompt to navigate to login screen
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccountPrompt;

  /// Text displayed during loading states, e.g. on Splash Screen
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingText;

  /// Title for the Page Not Found error screen
  ///
  /// In en, this message translates to:
  /// **'Page Not Found'**
  String get pageNotFoundScreenTitle;

  /// Generic message for page not found error
  ///
  /// In en, this message translates to:
  /// **'Oops! Something went wrong or the page doesn\'t exist.'**
  String get pageNotFoundGenericMessage;

  /// Prefix for displaying a specific error message on page not found screen
  ///
  /// In en, this message translates to:
  /// **'Error: '**
  String get pageNotFoundErrorMessagePrefix;

  /// Welcome message on the Home Screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to CAINS App!'**
  String get welcomeMessage;

  /// Button text for WordGrid Game on Home Screen
  ///
  /// In en, this message translates to:
  /// **'WordGrid Game'**
  String get wordGridGameButton;

  /// Button text for AI Word Research on Home Screen
  ///
  /// In en, this message translates to:
  /// **'AI Word Research'**
  String get aiWordResearchButton;

  /// Button text for Scan Text on Home Screen
  ///
  /// In en, this message translates to:
  /// **'Scan Text'**
  String get scanTextButton;

  /// Tooltip for the Sign Out button
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutButtonTooltip;

  /// Tooltip for the language menu icon button in AppBar
  ///
  /// In en, this message translates to:
  /// **'Language options'**
  String get languageMenuTooltip;

  /// Tooltip for the settings icon button in AppBar
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsMenuTooltip;

  /// Title for the logout confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get logoutDialogTitle;

  /// Content/message of the logout confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get logoutDialogContent;

  /// Label for the cancel button, typically in dialogs
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButtonLabel;

  /// Label for the logout button, typically in dialogs or menus
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutButtonLabel;

  /// Label for the menu item to switch to light theme
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get switchToLightModeLabel;

  /// Label for the menu item to switch to dark theme
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get switchToDarkModeLabel;

  /// Label showing the user's points total.
  ///
  /// In en, this message translates to:
  /// **'{points, plural, =0{0 points} one{1 point} other{{points} points}}'**
  String pointsLabel(int points);

  /// Label for the overall progress bar on the Home Screen
  ///
  /// In en, this message translates to:
  /// **'Overall Progress'**
  String get overallProgressLabel;

  /// Status indicator for an open daily challenge
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get challengeStatusOpen;

  /// Status indicator for a completed daily challenge
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get challengeStatusCompleted;

  /// Label for the button to start a daily challenge
  ///
  /// In en, this message translates to:
  /// **'Start Challenge'**
  String get startChallengeButtonLabel;

  /// Message displayed on HomeScreen when no topics are found
  ///
  /// In en, this message translates to:
  /// **'No topics available yet. Check back later!'**
  String get noTopicsAvailableMessage;

  /// Message displayed on HomeScreen when topics fail to load
  ///
  /// In en, this message translates to:
  /// **'Could not load topics. Please try again.'**
  String get errorLoadingTopicsMessage;

  /// Title for the Word Grid game screen
  ///
  /// In en, this message translates to:
  /// **'Word Grid'**
  String get wordGridScreenTitle;

  /// Prefix text displayed before the currently selected word in the grid game
  ///
  /// In en, this message translates to:
  /// **'Selected: '**
  String get selectedWordPrefix;

  /// Placeholder text shown before the grid is loaded or if it's empty
  ///
  /// In en, this message translates to:
  /// **'Grid will appear here...'**
  String get gridLoadingPlaceholder;

  /// Prefix text displayed before the list of found words in the grid game
  ///
  /// In en, this message translates to:
  /// **'Found Words: '**
  String get foundWordsPrefix;

  /// Tooltip for a button that resets the current word selection in the grid game
  ///
  /// In en, this message translates to:
  /// **'Reset Selection'**
  String get resetSelectionTooltip;

  /// Feedback message when a word is successfully found.
  ///
  /// In en, this message translates to:
  /// **'Word Found: {word}!'**
  String feedbackWordFound(String word);

  /// Feedback message when a word selected was already found.
  ///
  /// In en, this message translates to:
  /// **'Already found: {word}'**
  String feedbackWordAlreadyFound(String word);

  /// Feedback message when the selected letters do not form a valid hidden word.
  ///
  /// In en, this message translates to:
  /// **'Not a valid word: {word}'**
  String feedbackWordNotValid(String word);

  /// Feedback message if the word selection path is not a straight line.
  ///
  /// In en, this message translates to:
  /// **'Selection must be a straight line.'**
  String get feedbackSelectionNotStraight;

  /// Message displayed in WordGridScreen when no words have been found by the user yet.
  ///
  /// In en, this message translates to:
  /// **'No words found yet.'**
  String get noWordsFoundYet;

  /// Message displayed when the daily challenge fails to load
  ///
  /// In en, this message translates to:
  /// **'Could not load today\'s challenge.'**
  String get errorLoadingChallengeMessage;

  /// Label for a button to retry an action, typically after an error
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButtonLabel;

  /// Label for a button to fetch today's daily challenge
  ///
  /// In en, this message translates to:
  /// **'Get Today\'s Challenge'**
  String get getTodaysChallengeButtonLabel;

  /// Fallback text when a piece of information is not available.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailableFallback;

  /// Title for the definition section in vocabulary detail.
  ///
  /// In en, this message translates to:
  /// **'Definition'**
  String get definitionSectionTitle;

  /// Title for the synonyms section in vocabulary detail.
  ///
  /// In en, this message translates to:
  /// **'Synonyms'**
  String get synonymsSectionTitle;

  /// Title for the collocations section in vocabulary detail.
  ///
  /// In en, this message translates to:
  /// **'Collocations'**
  String get collocationsSectionTitle;

  /// Title for the example sentences section in vocabulary detail.
  ///
  /// In en, this message translates to:
  /// **'Example Sentences'**
  String get exampleSentencesSectionTitle;

  /// Message shown when no example sentences are available for the selected language.
  ///
  /// In en, this message translates to:
  /// **'No example sentences available for the selected language.'**
  String get noExamplesAvailable;

  /// Abbreviation for German language.
  ///
  /// In en, this message translates to:
  /// **'DE'**
  String get languageCodeDe;

  /// Abbreviation for English language.
  ///
  /// In en, this message translates to:
  /// **'EN'**
  String get languageCodeEn;

  /// Abbreviation for Spanish language.
  ///
  /// In en, this message translates to:
  /// **'ES'**
  String get languageCodeEs;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
