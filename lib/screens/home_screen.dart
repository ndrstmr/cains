// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart'; // For navigation
import 'package:flutter_riverpod/flutter_riverpod.dart'; // For services or theme
// import '../l10n/app_localizations.dart'; // For i10n
// import '../theme/app_theme.dart'; // For themeModeProvider if used directly

class HomeScreen extends ConsumerWidget {
  // Or StatelessWidget
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Add WidgetRef if ConsumerWidget
    // final localizations = AppLocalizations.of(context)!;
    // final themeMode = ref.watch(themeModeProvider); // Example Riverpod usage

    return Scaffold(
      appBar: AppBar(
        // title: Text(localizations.homePageTitle), // Example i18n
        title: const Text('Startseite'), // Placeholder
        actions: [
          IconButton(
            icon: const Icon(Icons.settings), // Example: Settings icon
            onPressed: () {
              // TODO: Navigate to a settings screen or show a dialog
              print("HomeScreen: Settings button pressed - TODO: Implement");
            },
          ),
          // Example: Theme toggle button
          // IconButton(
          //   icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
          //   onPressed: () {
          //     ref.read(themeModeProvider.notifier).state =
          //         themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
          //   },
          // ),
        ],
      ),
      body: Center(
        // Cannot be const because Column child contains non-const ElevatedButton
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              // This Text widget itself is const
              'Willkommen zur CAINS App!', // TODO: Localize
              style: TextStyle(fontSize: 20), // Inner const removed
            ),
            const SizedBox(height: 20), // This SizedBox is const
            ElevatedButton(
              // ElevatedButton is NOT const due to onPressed
              onPressed: () {
                // context.go('/wordgrid'); // Example navigation
                print("HomeScreen: Navigate to WordGrid - TODO");
              },
              child: const Text('Wortgitter Spiel'), // Child Text is const
            ),
            const SizedBox(height: 10), // This SizedBox is const
            ElevatedButton(
              // ElevatedButton is NOT const
              onPressed: () {
                // context.go('/research'); // Example navigation
                print("HomeScreen: Navigate to Research - TODO");
              },
              child: const Text('KI Wortrecherche'), // Child Text is const
            ),
            const SizedBox(height: 10), // This SizedBox is const
            ElevatedButton(
              // ElevatedButton is NOT const
              onPressed: () {
                // context.go('/scan'); // Example navigation
                print("HomeScreen: Navigate to Scan Text - TODO");
              },
              child: const Text('Text Scannen'), // Child Text is const
            ),
          ],
        ),
      ),
    );
  }
}
