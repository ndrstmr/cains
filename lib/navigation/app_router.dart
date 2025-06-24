// lib/navigation/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart'; // Required for Page builders

// Import screen widgets
import '../screens/splash_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
import '../screens/wordgrid_screen.dart';
import '../screens/research_screen.dart';
import '../screens/scan_screen.dart';

// Placeholder widget for unimplemented screens (can be removed if all screens are implemented)
// class PlaceholderScreen extends StatelessWidget {
//   final String screenName;
//   const PlaceholderScreen({super.key, required this.screenName});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(screenName)),
//       body: Center(child: Text('$screenName is not yet implemented.')),
//     );
//   }
// }

/// Defines the application's routes using GoRouter.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash', // Initial route
    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (BuildContext context, GoRouterState state) {
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (BuildContext context, GoRouterState state) {
          return const AuthScreen();
        },
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: '/wordgrid',
        name: 'wordgrid',
        builder: (BuildContext context, GoRouterState state) {
          return const WordGridScreen();
        },
      ),
      GoRoute(
        path: '/research',
        name: 'research',
        builder: (BuildContext context, GoRouterState state) {
          return const ResearchScreen();
        },
      ),
      GoRoute(
        path: '/scan',
        name: 'scan',
        builder: (BuildContext context, GoRouterState state) {
          return const ScanScreen();
        },
      ),
    ],
    // Optional: Add error handling
    // errorBuilder: (context, state) => ErrorScreen(state.error),
  );
}
