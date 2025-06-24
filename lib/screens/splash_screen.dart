// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart'; // For navigation after splash

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // TODO: Implement logic to check auth status or perform initial setup
    // For now, navigate to /auth after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      // if (mounted) { // Ensure widget is still in the tree
      //   context.go('/auth'); // Example navigation
      // }
      print(
        "SplashScreen: TODO: Navigate to /auth or /home based on auth state.",
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text('Lade CAINS App...'), // TODO: Localize this text
          ],
        ),
      ),
    );
  }
}
