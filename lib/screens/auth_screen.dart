// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart'; // For navigation
import 'package:flutter_riverpod/flutter_riverpod.dart'; // For auth service
// import 'package:myapp/l10n/app_localizations.dart'; // For i18n - adjust import path as needed

class AuthScreen extends ConsumerWidget {
  // Or StatelessWidget if not using Riverpod here yet
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Add WidgetRef if ConsumerWidget
    // final localizations = AppLocalizations.of(context)!; // For i18n

    return Scaffold(
      // Cannot be const due to AppBar/Body potentially not being fully const yet
      appBar: AppBar(
        // title: Text(localizations.loginButton), // Example i18n
        title: const Text('Anmelden / Registrieren'), // Placeholder
      ),
      body: Center(
        // Cannot be const because Column child contains non-const ElevatedButton
        child: Padding(
          // Cannot be const for the same reason
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // TODO: Add Email and Password TextFields
              TextField(
                // TextField cannot be const
                decoration: const InputDecoration(labelText: 'E-Mail'),
              ),
              const SizedBox(height: 10),
              TextField(
                // TextField cannot be const
                decoration: const InputDecoration(labelText: 'Passwort'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                // Cannot be const because of onPressed
                onPressed: () {
                  // TODO: Implement Login Logic
                  // context.go('/home'); // Example navigation
                  print("AuthScreen: Login button pressed - TODO: Implement");
                },
                // child: Text(localizations.loginButton), // Example i18n
                child: const Text('Anmelden'),
              ),
              const SizedBox(height: 10),
              TextButton(
                // Cannot be const because of onPressed
                onPressed: () {
                  // TODO: Implement Registration Logic
                  print(
                    "AuthScreen: Register button pressed - TODO: Implement",
                  );
                },
                // child: Text(localizations.registerButton), // Example i18n
                child: const Text('Registrieren'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
