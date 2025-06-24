import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase Core
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod
import 'package:myapp/navigation/app_router.dart'; // GoRouter configuration
import 'package:myapp/theme/app_theme.dart'; // AppTheme and themeModeProvider
import 'package:flutter_localizations/flutter_localizations.dart'; // Localizations
import 'package:myapp/l10n/app_localizations.dart'; // Generated localizations

Future<void> main() async {
  // Made main async for potential Firebase init
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Initialize Firebase here (actual initialization)
  // For now, this is just a placeholder print statement.
  // In a real app, you would call:
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform, // If using firebase_cli
  // );
  print(
    "Firebase Initialization Placeholder: Call Firebase.initializeApp() here.",
  );

  runApp(
    const ProviderScope(
      // Wrap with ProviderScope for Riverpod
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      themeModeProvider,
    ); // Watch the themeModeProvider

    return MaterialApp.router(
      title:
          'CAINS App', // This will be overridden by AppLocalizations.appTitle if used
      debugShowCheckedModeBanner: false, // Optional: hide debug banner
      // Theme configuration
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      // Router configuration
      routerConfig: AppRouter.router,

      // Localization configuration
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // Optionally, set a fallback locale or locale resolution callback
      // locale: const Locale('de'), // Example: Force German locale

      // TODO: Potentially use onGenerateTitle to use AppLocalizations.appTitle
      // onGenerateTitle: (BuildContext context) {
      //   return AppLocalizations.of(context)?.appTitle ?? 'CAINS App';
      // },
    );
  }
}
