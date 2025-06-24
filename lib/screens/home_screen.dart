// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/providers/auth_provider.dart'; // For authNotifierProvider
import 'package:myapp/navigation/app_router.dart'; // For AppRoute enum
// TODO: Import AppLocalizations
// TODO: Import theme provider if needed for theme toggle

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final localizations = AppLocalizations.of(context)!; // TODO: Uncomment and use
    // final themeMode = ref.watch(themeModeProvider); // Example Riverpod theme usage

    // Listen to the AuthNotifier for error states from sign-out attempts
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.error != null && next.error!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!), // TODO: i18n for error messages
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        // Clear the error in the notifier once shown
        ref.read(authNotifierProvider.notifier).clearError();
      }
      // Successful sign-out will trigger authStateChangesProvider,
      // and GoRouter's redirect logic will navigate to the login screen.
    });

    final authState = ref.watch(authNotifierProvider); // For isLoading on sign-out button

    return Scaffold(
      appBar: AppBar(
        // title: Text(localizations.homePageTitle), // TODO: Use i18n
        title: const Text('Home'), // Placeholder
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              print("HomeScreen: Settings button pressed - TODO: Implement");
            },
          ),
          // Sign Out Button
          authState.isLoading && ModalRoute.of(context)?.isCurrent == true // Check if current route to avoid showing loading for other auth actions
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 24, // Consistent size with IconButton
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.logout),
                  // tooltip: localizations.signOutButtonTooltip, // TODO: Use i18n
                  tooltip: 'Sign Out', // Placeholder
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).signOut();
                    // Navigation will be handled by GoRouter redirect based on auth state change
                  },
                ),
          // TODO: Add theme toggle button if desired
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // const Text(localizations.welcomeMessage, style: TextStyle(fontSize: 20)), // TODO
            const Text(
              'Welcome to CAINS App!',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                GoRouter.of(context).go(AppRoute.wordgrid.path);
              },
              // child: Text(localizations.wordGridGameButton), // TODO
              child: const Text('WordGrid Game'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                GoRouter.of(context).go(AppRoute.research.path);
              },
              // child: Text(localizations.aiWordResearchButton), // TODO
              child: const Text('AI Word Research'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                GoRouter.of(context).go(AppRoute.scan.path);
              },
              // child: Text(localizations.scanTextButton), // TODO
              child: const Text('Scan Text'),
            ),
          ],
        ),
      ),
    );
  }
}
