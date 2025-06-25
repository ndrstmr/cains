// lib/providers/user_progress_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For User type
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/firestore_service.dart'; // Assuming firestoreServiceProvider is defined here or elsewhere

// Assume firestoreServiceProvider is defined, e.g., in lib/services/firestore_service.dart or a specific providers file.
// If not, it would look something like this:
// final firestoreServiceProvider = Provider<FirestoreService>((ref) {
//   return FirestoreService(FirebaseFirestore.instance);
// });

// Assume authProvider is defined, e.g., in lib/providers/auth_provider.dart
// It would typically provide the current Firebase user state:
// final authProvider = StreamProvider<User?>((ref) {
//   return FirebaseAuth.instance.authStateChanges();
// });

/// Provider for the [FirestoreService].
/// Ensure this is initialized in your app, perhaps in main.dart or a providers setup file.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  // This assumes you have FirebaseFirestore.instance available.
  // You might need to import 'package:cloud_firestore/cloud_firestore.dart';
  // if not already imported where this provider is truly defined.
  // For now, this is a placeholder to make the userProgressProvider work.
  throw UnimplementedError(
      'firestoreServiceProvider must be overridden with a real instance.');
  // Example: return FirestoreService(FirebaseFirestore.instance);
});

/// Provider for the current authentication state (Firebase User).
/// Ensure this is initialized in your app.
final authStateProvider = StreamProvider<User?>((ref) {
  // This assumes you have FirebaseAuth.instance available.
  // You might need to import 'package:firebase_auth/firebase_auth.dart';
  // if not already imported where this provider is truly defined.
  // For now, this is a placeholder.
  throw UnimplementedError(
      'authStateProvider must be overridden with a real instance of FirebaseAuth.instance.authStateChanges().');
  // Example: return FirebaseAuth.instance.authStateChanges();
});


/// Provides a stream of the current user's [UserModel] data from Firestore.
///
/// This provider depends on [firestoreServiceProvider] to access Firestore
/// and [authStateProvider] to get the current user's ID.
///
/// It returns `null` if the user is not authenticated or if their data
/// doesn't exist in Firestore yet.
final userProgressProvider = StreamProvider<UserModel?>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final authState = ref.watch(authStateProvider);

  final firebaseUser = authState.asData?.value;

  if (firebaseUser != null && firebaseUser.uid.isNotEmpty) {
    return firestoreService.getUserStream(firebaseUser.uid);
  } else {
    // If user is not logged in, or uid is not available, return a stream of null.
    // This indicates no user progress data is available.
    return Stream.value(null);
  }
});

/// A specific provider to get just the UID of the currently authenticated user.
/// Returns null if no user is authenticated.
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.asData?.value?.uid;
});
