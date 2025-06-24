// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/providers/auth_provider.dart'; // Ensure this path is correct
import 'package:myapp/navigation/app_router.dart'; // For AppRoute enum

// TODO: Import AppLocalizations for text

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to the auth state.
    // This listener will handle navigation once the auth state is determined.
    // It's important to handle navigation *after* the first frame is built,
    // which ref.listen helps with by default for navigation side effects.
    ref.listen(authStateChangesProvider, (previous, next) {
      // The next value is an AsyncValue<User?>
      next.when(
        data: (user) {
          if (user != null) {
            // User is logged in
            // Check if we are currently on the splash screen to avoid navigation loops
            // if GoRouter's current route is already somewhere else due to fast auth state resolution.
            final currentRoute = GoRouter.of(context).routeInformationProvider.value.uri.path;
            if (currentRoute == AppRoute.splash.path) {
               GoRouter.of(context).go(AppRoute.home.path);
            }
          } else {
            // User is logged out
            final currentRoute = GoRouter.of(context).routeInformationProvider.value.uri.path;
            if (currentRoute == AppRoute.splash.path) {
              GoRouter.of(context).go(AppRoute.login.path);
            }
          }
        },
        loading: () {
          // Still loading, SplashScreen's UI will show CircularProgressIndicator
        },
        error: (err, stack) {
          // Error fetching auth state, navigate to login or show error
          // For simplicity, navigate to login. A more robust app might show an error.
          final currentRoute = GoRouter.of(context).routeInformationProvider.value.uri.path;
          if (currentRoute == AppRoute.splash.path) {
            GoRouter.of(context).go(AppRoute.login.path);
          }
        },
      );
    });

    // The UI of the splash screen itself.
    // It will be displayed while the auth state is being determined.
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            // Text(AppLocalizations.of(context)?.loading ?? 'Loading...'), // TODO: Use i18n
            Text('Loading...'), // Placeholder
          ],
        ),
      ),
    );
  }
}
