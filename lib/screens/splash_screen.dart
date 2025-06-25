// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/l10n/app_localizations.dart'; // Import AppLocalizations
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/providers/topic_provider.dart'; // For firestoreServiceProvider
import 'package:myapp/navigation/app_router.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;

    ref.listen(authStateChangesProvider, (previous, next) {
      next.when(
        data: (user) async {
          // Make the callback async
          final currentRoute = GoRouter.of(
            context,
          ).routeInformationProvider.value.uri.path;
          if (currentRoute != AppRoute.splash.path) {
            return; // Avoid navigation if not on splash
          }

          if (user != null) {
            // User is logged in
            try {
              // Attempt to add dummy topics. This method should be idempotent or check if topics exist.
              // It's called here as a one-time setup after login if needed.
              // Consider if this should only run for new users or if the check inside addDummyTopics is sufficient.
              final firestoreService = ref.read(firestoreServiceProvider);
              await firestoreService.addDummyTopics();
              print("SplashScreen: Checked/Added dummy topics.");
            } catch (e) {
              // Log error if adding dummy topics fails, but proceed with navigation.
              print("SplashScreen: Error trying to add dummy topics: $e");
            }
            GoRouter.of(context).go(AppRoute.home.path);
          } else {
            // User is logged out
            GoRouter.of(context).go(AppRoute.login.path);
          }
        },
        loading: () {
          // Still loading, SplashScreen's UI will show CircularProgressIndicator
        },
        error: (err, stack) {
          // Error fetching auth state, navigate to login or show error
          // For simplicity, navigate to login. A more robust app might show an error.
          final currentRoute = GoRouter.of(
            context,
          ).routeInformationProvider.value.uri.path;
          if (currentRoute == AppRoute.splash.path) {
            GoRouter.of(context).go(AppRoute.login.path);
          }
        },
      );
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(localizations.loadingText),
          ],
        ),
      ),
    );
  }
}
