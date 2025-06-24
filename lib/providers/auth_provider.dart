// lib/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/services/auth_service.dart'; // Adjust import path if needed

// 1. Provider for AuthService
// This makes AuthService available to other providers and widgets.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance);
});

// 2. StreamProvider for Authentication State (User?)
// This provider streams the current authentication state (User object or null).
// Widgets can listen to this provider to reactively update based on auth status.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// 3. StateNotifierProvider for Authentication Actions (Login, Register, Logout)

// Define a state class for the AuthNotifier
// This state will hold information about loading status and potential errors.
@immutable
class AuthState {
  final bool isLoading;
  final String? error;

  const AuthState({this.isLoading = false, this.error});

  AuthState copyWith({bool? isLoading, String? error}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// The StateNotifier that will manage authentication actions
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final Reader _read; // Or Ref if using NotifierProvider

  AuthNotifier(this._authService, this._read) : super(const AuthState());

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      // User state will be updated by authStateChangesProvider automatically.
      // No need to update User object here.
      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message ?? 'Login failed');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An unexpected error occurred.');
    }
  }

  Future<void> createUserWithEmailAndPassword(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.createUserWithEmailAndPassword(email, password);
      // User state will be updated by authStateChangesProvider automatically.
      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message ?? 'Registration failed');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An unexpected error occurred.');
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.signOut();
      // User state will be updated by authStateChangesProvider automatically.
      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message ?? 'Sign out failed');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An unexpected error occurred.');
    }
  }

  /// Call this to clear any displayed error messages.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// The StateNotifierProvider for AuthNotifier
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService, ref.read); // Pass ref.read or ref for Notifier
});
