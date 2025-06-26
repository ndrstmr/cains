// lib/navigation/app_router.dart
import 'package:firebase_auth/firebase_auth.dart'; // Required for User type
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/screens/splash_screen.dart';
import 'package:myapp/screens/auth/login_screen.dart';
import 'package:myapp/screens/auth/registration_screen.dart';
import 'package:myapp/screens/home_screen.dart';
import 'package:myapp/models/topic_model.dart'; // Import Topic model
import 'package:myapp/screens/wordgrid_screen.dart';
import 'package:myapp/screens/research_screen.dart';
import 'package:myapp/screens/scan_screen.dart';
import 'package:myapp/l10n/app_localizations.dart'; // Import AppLocalizations

// Application specific error screen
class ErrorScreen extends StatelessWidget {
  final Exception? error;
  const ErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(localizations.pageNotFoundScreenTitle)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(localizations.pageNotFoundGenericMessage),
            const SizedBox(height: 10),
            Text(
              error != null
                  ? '${localizations.pageNotFoundErrorMessagePrefix}${error.toString()}'
                  : localizations.pageNotFoundGenericMessage,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:myapp/screens/ai_research_screen.dart'; // Import AIResearchScreen

// Enum for route names for type safety and easy access
import 'package:myapp/screens/image_scan_screen.dart'; // Import ImageScanScreen

enum AppRoute {
  splash('/splash'),
  login('/login'),
  register('/register'),
  home('/home'),
  wordgrid('/wordgrid'),
  research('/research'),
  scan('/scan'),
  aiResearch('/ai-research'),
  imageScan('/image-scan'); // New route for Image Scan

  const AppRoute(this.path);
  final String path;
}

// Provider to expose the GoRouter instance.
final goRouterProvider = Provider<GoRouter>((ref) {
  // ValueNotifier to hold the latest auth state for the redirect logic.
  // It's updated by ref.listen.
  final authStateListenable = ValueNotifier<AsyncValue<User?>>(
    const AsyncValue.loading(),
  );

  ref.listen<AsyncValue<User?>>(
    authStateChangesProvider, // The stream provider for auth state
    (previous, next) {
      authStateListenable.value =
          next; // Update the notifier on new auth states
    },
  );

  return GoRouter(
    initialLocation: AppRoute.splash.path,
    debugLogDiagnostics: true, // Log routing diagnostics
    refreshListenable:
        authStateListenable, // Re-evaluate routes when authStateListenable changes
    routes: <RouteBase>[
      GoRoute(
        path: AppRoute.splash.path,
        name: AppRoute.splash.name, // Using enum name as route name
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoute.login.path,
        name: AppRoute.login.name,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoute.register.path,
        name: AppRoute.register.name,
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: AppRoute.home.path,
        name: AppRoute.home.name,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoute.wordgrid.path, // Keep the base path
        name: AppRoute.wordgrid.name,
        builder: (context, state) {
          // Expect a Topic object to be passed as an extra
          final topic = state.extra as Topic?;
          if (topic != null) {
            return WordGridScreen(topic: topic);
          }
          // If topic is null, redirect to home or show an error.
          // For simplicity, redirecting to home. Consider a specific error page.
          // This scenario should ideally be prevented by how you navigate.
          return const HomeScreen(); // Or an ErrorScreen
        },
        // TODO: Add redirect logic here or protect globally if all sub-routes need protection
      ),
      GoRoute(
        path: AppRoute.research.path,
        name: AppRoute.research.name,
        builder: (context, state) => const ResearchScreen(),
      ),
      GoRoute(
        path: AppRoute.scan.path,
        name: AppRoute.scan.name,
        builder: (context, state) => const ScanScreen(),
      ),
      GoRoute(
        path: AppRoute.aiResearch.path,
        name: AppRoute.aiResearch.name,
        builder: (context, state) => const AIResearchScreen(),
        // This route should also be protected, ensuring user is logged in.
        // The global redirect logic already handles redirecting to login if not authenticated
        // and not on an auth flow page. So, specific protection here might be redundant
        // if all non-auth pages should be protected.
      ),
      GoRoute(
        path: AppRoute.imageScan.path,
        name: AppRoute.imageScan.name,
        builder: (context, state) => const ImageScanScreen(),
        // This route will also be protected by the global redirect logic.
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
    redirect: (BuildContext context, GoRouterState state) {
      final authStateAsync = authStateListenable.value;

      final loggedIn = authStateAsync.maybeWhen(
        data: (user) => user != null,
        orElse: () =>
            false, // Treat loading/error as not logged in for redirect decision
      );

      final currentPath =
          state.uri.path; // Use state.uri.path for accurate path
      final onAuthFlow =
          currentPath == AppRoute.login.path ||
          currentPath == AppRoute.register.path;
      final onSplash = currentPath == AppRoute.splash.path;

      if (onSplash) {
        // Let SplashScreen handle its own logic based on auth state.
        // It might navigate away after checking auth status.
        return null;
      }

      // If not logged in and not on an auth page (login/register), redirect to login.
      if (!loggedIn && !onAuthFlow) {
        return AppRoute.login.path;
      }

      // If logged in and trying to access login or register, redirect to home.
      if (loggedIn && onAuthFlow) {
        return AppRoute.home.path;
      }

      // TODO: Implement protection for other specific routes if needed
      // Example:
      // final protectedPaths = [AppRoute.wordgrid.path, AppRoute.research.path, AppRoute.scan.path];
      // if (!loggedIn && protectedPaths.contains(currentPath)) {
      //   return AppRoute.login.path;
      // }

      return null; // No redirect needed
    },
  );
});

// Note for updating main.dart:
// The MaterialApp.router's routerConfig should be set to ref.watch(goRouterProvider).
// Example:
// class MyApp extends ConsumerWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final goRouter = ref.watch(goRouterProvider);
//     return MaterialApp.router(
//       routerConfig: goRouter,
//       // ... other MaterialApp properties
//     );
//   }
// }
