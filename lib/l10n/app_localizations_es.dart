// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'CAINS App';

  @override
  String get loginButton => 'Iniciar sesión';

  @override
  String get registerButton => 'Registrarse';

  @override
  String get homePageTitle => 'Inicio';

  @override
  String get loginScreenTitle => 'Iniciar sesión';

  @override
  String get emailFieldLabel => 'Correo electrónico';

  @override
  String get emailFieldHint => 'Ingrese su correo electrónico';

  @override
  String get emailValidationErrorEmpty => 'Por favor ingrese su correo electrónico';

  @override
  String get emailValidationErrorFormat => 'Por favor ingrese un correo electrónico válido';

  @override
  String get passwordFieldLabel => 'Contraseña';

  @override
  String get passwordFieldHint => 'Ingrese su contraseña';

  @override
  String get passwordValidationErrorEmpty => 'Por favor ingrese su contraseña';

  @override
  String get passwordValidationErrorLength => 'La contraseña debe tener al menos 6 caracteres';

  @override
  String get dontHaveAccountPrompt => '¿No tienes cuenta? Registrarse';

  @override
  String get registrationScreenTitle => 'Registrarse';

  @override
  String get confirmPasswordFieldLabel => 'Confirmar contraseña';

  @override
  String get confirmPasswordFieldHint => 'Confirme su contraseña';

  @override
  String get confirmPasswordValidationErrorEmpty => 'Por favor confirme su contraseña';

  @override
  String get confirmPasswordValidationErrorMatch => 'Las contraseñas no coinciden';

  @override
  String get alreadyHaveAccountPrompt => '¿Ya tienes eine cuenta? Iniciar sesión';

  @override
  String get loadingText => 'Cargando...';

  @override
  String get pageNotFoundScreenTitle => 'Página no encontrada';

  @override
  String get pageNotFoundGenericMessage => '¡Ups! Algo salió mal o la página no existe.';

  @override
  String get pageNotFoundErrorMessagePrefix => 'Error: ';

  @override
  String get welcomeMessage => '¡Bienvenido a la App CAINS!';

  @override
  String get wordGridGameButton => 'Juego de Sopa de Letras';

  @override
  String get aiWordResearchButton => 'Investigación de Palabras con IA';

  @override
  String get scanTextButton => 'Escanear Texto';

  @override
  String get signOutButtonTooltip => 'Cerrar sesión';

  @override
  String get languageMenuTooltip => 'Opciones de idioma';

  @override
  String get settingsMenuTooltip => 'Configuración';

  @override
  String get logoutDialogTitle => 'Confirmar cierre de sesión';

  @override
  String get logoutDialogContent => '¿Está seguro de que desea cerrar sesión?';

  @override
  String get cancelButtonLabel => 'Cancelar';

  @override
  String get logoutButtonLabel => 'Cerrar sesión';

  @override
  String get switchToLightModeLabel => 'Modo claro';

  @override
  String get switchToDarkModeLabel => 'Modo oscuro';

  @override
  String get noTopicsAvailableMessage => 'No hay temas disponibles todavía. ¡Vuelve más tarde!';

  @override
  String get errorLoadingTopicsMessage => 'No se pudieron cargar los temas. Inténtalo de nuevo.';

  @override
  String get wordGridScreenTitle => 'Sopa de Letras';

  @override
  String get selectedWordPrefix => 'Seleccionado: ';

  @override
  String get gridLoadingPlaceholder => 'La cuadrícula aparecerá aquí...';

  @override
  String get foundWordsPrefix => 'Palabras encontradas: ';

  @override
  String get resetSelectionTooltip => 'Restablecer selección';

  @override
  String feedbackWordFound(String word) {
    return '¡Palabra encontrada: $word!';
  }

  @override
  String feedbackWordAlreadyFound(String word) {
    return 'Ya encontrada: $word';
  }

  @override
  String feedbackWordNotValid(String word) {
    return 'Palabra no válida: $word';
  }

  @override
  String get feedbackSelectionNotStraight => 'La selección debe ser una línea recta.';

  @override
  String get noWordsFoundYet => 'Aún no se han encontrado palabras.';

  @override
  String get notAvailableFallback => 'N/D';

  @override
  String get definitionSectionTitle => 'Definición';

  @override
  String get synonymsSectionTitle => 'Sinónimos';

  @override
  String get collocationsSectionTitle => 'Colocaciones';

  @override
  String get exampleSentencesSectionTitle => 'Frases de Ejemplo';

  @override
  String get noExamplesAvailable => 'No hay frases de ejemplo disponibles para el idioma seleccionado.';

  @override
  String get languageCodeDe => 'DE';

  @override
  String get languageCodeEn => 'EN';

  @override
  String get languageCodeEs => 'ES';
}
