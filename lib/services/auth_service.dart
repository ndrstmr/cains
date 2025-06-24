// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

/// A service to handle Firebase Authentication.
class AuthService {
  final FirebaseAuth _firebaseAuth;

  /// Creates an [AuthService] instance.
  /// Requires a [FirebaseAuth] instance. Consider passing FirebaseAuth.instance.
  AuthService(this._firebaseAuth);

  /// Stream of authentication state changes from Firebase.
  /// Emits the current [User] if logged in, or `null` if logged out.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Gets the current Firebase [User] if one is authenticated, otherwise `null`.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Signs in a user with the given [email] and [password].
  ///
  /// Returns a [UserCredential] on success.
  /// Throws a [FirebaseAuthException] on failure, which should be caught
  /// and handled by the caller (e.g., in the auth provider/notifier).
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      if (kDebugMode) {
        print('AuthService: Attempting to sign in with email: $email');
      }
      final UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('AuthService: FirebaseAuthException during sign in: ${e.code} - ${e.message}');
      }
      // Re-throw the exception to be handled by the UI layer (e.g., auth provider)
      // This allows displaying specific error messages to the user.
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('AuthService: Generic exception during sign in: $e');
      }
      // For other types of exceptions, re-throw as a generic FirebaseAuthException
      // or handle as appropriate. For simplicity here, we'll rethrow a generic one.
      throw FirebaseAuthException(
          code: 'sign-in-failed', message: 'An unknown error occurred during sign in.');
    }
  }

  /// Registers a new user with the given [email] and [password].
  /// (Corresponds to createUserWithEmailAndPassword in Firebase)
  ///
  /// Returns a [UserCredential] on success.
  /// Throws a [FirebaseAuthException] on failure, which should be caught
  /// and handled by the caller.
  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      if (kDebugMode) {
        print('AuthService: Attempting to register with email: $email');
      }
      final UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // You might want to send a verification email here or update the user's profile.
      // e.g., await userCredential.user?.sendEmailVerification();
      // e.g., await userCredential.user?.updateDisplayName('New User');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('AuthService: FirebaseAuthException during registration: ${e.code} - ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('AuthService: Generic exception during registration: $e');
      }
      throw FirebaseAuthException(
          code: 'registration-failed',
          message: 'An unknown error occurred during registration.');
    }
  }

  /// Signs out the current user.
  ///
  /// Throws a [FirebaseAuthException] on failure during sign out,
  /// though this is less common for sign-out operations.
  Future<void> signOut() async {
    try {
      if (kDebugMode) {
        print('AuthService: Attempting to sign out user: ${currentUser?.email}');
      }
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('AuthService: FirebaseAuthException during sign out: ${e.code} - ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('AuthService: Generic exception during sign out: $e');
      }
      throw FirebaseAuthException(
          code: 'sign-out-failed', message: 'An unknown error occurred during sign out.');
    }
  }
}

// Note: The Riverpod provider for this service will be defined elsewhere,
// typically in a separate providers file (e.g., lib/providers/auth_provider.dart)
// like:
// final authServiceProvider = Provider<AuthService>((ref) {
//   return AuthService(FirebaseAuth.instance);
// });
