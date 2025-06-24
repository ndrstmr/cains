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
import 'package:myapp/screens/wordgrid_screen.dart';
import 'package:myapp/screens/research_screen.dart';
import 'package:myapp/screens/scan_screen.dart';

// Application specific error screen
class ErrorScreen extends StatelessWidget {
  final Exception? error;
  const ErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    // TODO: Add localization for title and message
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Oops! Something went wrong or the page doesn\'t exist.'),
            const SizedBox(height: 10),
            Text(error != null ? 'Error: ${error.toString()}' : 'No specific error message.'),
          ],
        ),
      ),
    );
  }
}

// Enum for route names for type safety and easy access
enum AppRoute {
  splash('/splash'),
  login('/login'),
  register('/register'),
  home('/home'),
  wordgrid('/wordgrid'),
  research('/research'),
  scan('/scan');

  const AppRoute(this.path);
  final String path;
}

// Provider to expose the GoRouter instance.
final goRouterProvider = Provider<GoRouter>((ref) {
  // ValueNotifier to hold the latest auth state for the redirect logic.
  // It's updated by ref.listen.
  final authStateListenable = ValueNotifier<AsyncValue<User?>>(const AsyncValue.loading());

  ref.listen<AsyncValue<User?>>(
    authStateChangesProvider, // The stream provider for auth state
    (previous, next) {
      authStateListenable.value = next; // Update the notifier on new auth states
    },
  );

  return GoRouter(
    initialLocation: AppRoute.splash.path,
    debugLogDiagnostics: true, // Log routing diagnostics
    refreshListenable: authStateListenable, // Re-evaluate routes when authStateListenable changes
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
        path: AppRoute.wordgrid.path,
        name: AppRoute.wordgrid.name,
        builder: (context, state) => const WordGridScreen(),
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
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
    redirect: (BuildContext context, GoRouterState state) {
      final authStateAsync = authStateListenable.value;

      final loggedIn = authStateAsync.maybeWhen(
        data: (user) => user != null,
        orElse: () => false, // Treat loading/error as not logged in for redirect decision
      );

      final currentPath = state.uri.path; // Use state.uri.path for accurate path
      final onAuthFlow = currentPath == AppRoute.login.path || currentPath == AppRoute.register.path;
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
