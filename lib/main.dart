// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/navigation/app_router.dart'; // Provides goRouterProvider
import 'package:myapp/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:myapp/l10n/app_localizations.dart'; // Generated localizations

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Actual Firebase initialization should be configured by the developer
  // with their Firebase project credentials.
  // For this prototype, we assume it would be initialized here.
  // Example:
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform, // From firebase_flutter_cli
  // );
  print("Firebase Initialization Placeholder: Ensure Firebase is properly initialized for Auth to work.");

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final goRouter = ref.watch(goRouterProvider); // Watch the goRouterProvider

    return MaterialApp.router(
      title: 'CAINS App', // Will be overridden by onGenerateTitle if implemented
      debugShowCheckedModeBanner: false,

      // Theme configuration
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      // Router configuration
      routerConfig: goRouter, // Use the goRouter instance from the provider

      // Localization configuration
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,

      // TODO: Implement onGenerateTitle for localized app title
      // onGenerateTitle: (BuildContext context) {
      //   // Ensure AppLocalizations is available
      //   // return AppLocalizations.of(context)?.appTitle ?? 'CAINS App';
      //   return 'CAINS App'; // Placeholder
      // },
    );
  }
}
