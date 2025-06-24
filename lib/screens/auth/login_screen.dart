// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/navigation/app_router.dart'; // For AppRoute enum
// TODO: Import AppLocalizations

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      // Call login method from authNotifierProvider
      await ref.read(authNotifierProvider.notifier).signInWithEmailAndPassword(email, password);
      // No navigation here, GoRouter's redirect will handle it on auth state change.
      // Error display is handled by the ref.listen below.
    }
  }

  @override
  Widget build(BuildContext context) {
    // final localizations = AppLocalizations.of(context)!; // TODO: Uncomment and use

    // Listen to the AuthNotifier for error states or other side effects
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.error != null && next.error!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        // Clear the error in the notifier once shown
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });

    final authState = ref.watch(authNotifierProvider); // Watch for loading state

    return Scaffold(
      appBar: AppBar(
        // title: Text(localizations.loginButton), // TODO: Use i18n
        title: const Text('Login'), // Placeholder
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // TODO: Add app logo or title widget here eventually

                // Email TextFormField
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    // labelText: localizations.emailFieldLabel, // TODO: Use i18n
                    labelText: 'Email', // Placeholder
                    // hintText: localizations.emailFieldHint, // TODO: Use i18n
                    hintText: 'Enter your email', // Placeholder
                    prefixIcon: const Icon(Icons.email),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      // return localizations.emailValidationErrorEmpty; // TODO: Use i18n
                      return 'Please enter your email'; // Placeholder
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      // return localizations.emailValidationErrorFormat; // TODO: Use i18n
                      return 'Please enter a valid email address'; // Placeholder
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                // Password TextFormField
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    // labelText: localizations.passwordFieldLabel, // TODO: Use i18n
                    labelText: 'Password', // Placeholder
                    // hintText: localizations.passwordFieldHint, // TODO: Use i18n
                    hintText: 'Enter your password', // Placeholder
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: !_passwordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      // return localizations.passwordValidationErrorEmpty; // TODO: Use i18n
                      return 'Please enter your password'; // Placeholder
                    }
                    if (value.length < 6) {
                      // return localizations.passwordValidationErrorLength; // TODO: Use i18n
                      return 'Password must be at least 6 characters'; // TODO: i18n
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),

                // Login Button (conditionally show loading indicator)
                // TODO: Replace with a widget that handles loading state
                authState.isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: _login,
                        // child: Text(localizations.loginButton), // TODO: Use i18n
                        child: const Text('Login'), // Placeholder
                      ),
                const SizedBox(height: 16.0),

                // Switch to Registration Screen
                TextButton(
                  onPressed: authState.isLoading ? null : () { // Disable button when loading
                    // Navigate to RegistrationScreen
                    GoRouter.of(context).go(AppRoute.register.path);
                  },
                  // child: Text(localizations.noAccountPrompt), // TODO: Use i18n
                  child: const Text("Don't have an account? Register"), // Placeholder
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
