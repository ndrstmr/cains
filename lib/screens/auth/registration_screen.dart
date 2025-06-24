// lib/screens/auth/registration_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/navigation/app_router.dart'; // For AppRoute enum
// TODO: Import AppLocalizations

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  // bool _isLoading = false; // Will be handled by a StateNotifier

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      // Call registration method from authNotifierProvider
      await ref.read(authNotifierProvider.notifier).createUserWithEmailAndPassword(email, password);
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
        // title: Text(localizations.registerButton), // TODO: Use i18n
        title: const Text('Register'), // Placeholder
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
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
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    // labelText: localizations.confirmPasswordFieldLabel, // TODO: Use i18n
                    labelText: 'Confirm Password', // Placeholder
                    // hintText: localizations.confirmPasswordFieldHint, // TODO: Use i18n
                    hintText: 'Confirm your password', // Placeholder
                    prefixIcon: const Icon(Icons.lock_outline),
                     suffixIcon: IconButton(
                      icon: Icon(
                        _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _confirmPasswordVisible = !_confirmPasswordVisible;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: !_confirmPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      // return localizations.confirmPasswordValidationErrorEmpty; // TODO: Use i18n
                      return 'Please confirm your password'; // Placeholder
                    }
                    if (value != _passwordController.text) {
                      // return localizations.confirmPasswordValidationErrorMatch; // TODO: Use i18n
                      return 'Passwords do not match'; // Placeholder
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),

                // Register Button (conditionally show loading indicator)
                // TODO: Replace with a widget that handles loading state
                authState.isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: _register,
                        // child: Text(localizations.registerButton), // TODO: Use i18n
                        child: const Text('Register'), // Placeholder
                      ),
                const SizedBox(height: 16.0),

                // Switch to Login Screen
                TextButton(
                  onPressed: authState.isLoading ? null : () { // Disable button when loading
                    // Navigate to LoginScreen
                    if (GoRouter.of(context).canPop()) {
                        GoRouter.of(context).pop();
                    } else {
                        GoRouter.of(context).go(AppRoute.login.path);
                    }
                  },
                  // child: Text(localizations.alreadyHaveAccountPrompt), // TODO: Use i18n
                  child: const Text('Already have an account? Login'), // Placeholder
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
