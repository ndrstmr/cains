// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CAINS App';

  @override
  String get loginButton => 'Login';

  @override
  String get registerButton => 'Register';

  @override
  String get homePageTitle => 'Home';

  @override
  String get loginScreenTitle => 'Login';

  @override
  String get emailFieldLabel => 'Email';

  @override
  String get emailFieldHint => 'Enter your email';

  @override
  String get emailValidationErrorEmpty => 'Please enter your email';

  @override
  String get emailValidationErrorFormat => 'Please enter a valid email address';

  @override
  String get passwordFieldLabel => 'Password';

  @override
  String get passwordFieldHint => 'Enter your password';

  @override
  String get passwordValidationErrorEmpty => 'Please enter your password';

  @override
  String get passwordValidationErrorLength =>
      'Password must be at least 6 characters long';

  @override
  String get dontHaveAccountPrompt => 'Don\'t have an account? Register';

  @override
  String get registrationScreenTitle => 'Register';

  @override
  String get confirmPasswordFieldLabel => 'Confirm Password';

  @override
  String get confirmPasswordFieldHint => 'Confirm your password';

  @override
  String get confirmPasswordValidationErrorEmpty =>
      'Please confirm your password';

  @override
  String get confirmPasswordValidationErrorMatch => 'Passwords do not match';

  @override
  String get alreadyHaveAccountPrompt => 'Already have an account? Login';

  @override
  String get loadingText => 'Loading...';

  @override
  String get pageNotFoundScreenTitle => 'Page Not Found';

  @override
  String get pageNotFoundGenericMessage =>
      'Oops! Something went wrong or the page doesn\'t exist.';

  @override
  String get pageNotFoundErrorMessagePrefix => 'Error: ';

  @override
  String get welcomeMessage => 'Welcome to CAINS App!';

  @override
  String get wordGridGameButton => 'WordGrid Game';

  @override
  String get aiWordResearchButton => 'AI Word Research';

  @override
  String get scanTextButton => 'Scan Text';

  @override
  String get signOutButtonTooltip => 'Sign Out';

  @override
  String get languageMenuTooltip => 'Language options';

  @override
  String get settingsMenuTooltip => 'Settings';

  @override
  String get logoutDialogTitle => 'Confirm Logout';

  @override
  String get logoutDialogContent => 'Are you sure you want to sign out?';

  @override
  String get cancelButtonLabel => 'Cancel';

  @override
  String get logoutButtonLabel => 'Logout';

  @override
  String get switchToLightModeLabel => 'Light Mode';

  @override
  String get switchToDarkModeLabel => 'Dark Mode';

  @override
  String get noTopicsAvailableMessage =>
      'No topics available yet. Check back later!';

  @override
  String get errorLoadingTopicsMessage =>
      'Could not load topics. Please try again.';

  @override
  String get wordGridScreenTitle => 'Word Grid';

  @override
  String get selectedWordPrefix => 'Selected: ';

  @override
  String get gridLoadingPlaceholder => 'Grid will appear here...';

  @override
  String get foundWordsPrefix => 'Found Words: ';

  @override
  String get resetSelectionTooltip => 'Reset Selection';

  @override
  String feedbackWordFound(String word) {
    return 'Word Found: $word!';
  }

  @override
  String feedbackWordAlreadyFound(String word) {
    return 'Already found: $word';
  }

  @override
  String feedbackWordNotValid(String word) {
    return 'Not a valid word: $word';
  }

  @override
  String get feedbackSelectionNotStraight =>
      'Selection must be a straight line.';
}
