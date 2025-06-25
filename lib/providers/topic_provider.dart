// lib/providers/topic_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // For FirebaseFirestore instance
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/models/topic_model.dart';
import 'package:myapp/services/firestore_service.dart';

// Provider for FirestoreService
// This makes FirestoreService available to other providers.
// It's similar to authServiceProvider but for Firestore.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  // Note: If you already have a generic firestoreServiceProvider defined elsewhere
  // (e.g., from Iteration 0 or 1 if it was made then), you might not need to redefine it here.
  // However, the Iteration 1 plan focused on AuthService and didn't explicitly create one for FirestoreService.
  // So, creating it here for clarity and completeness for topic handling.
  return FirestoreService(FirebaseFirestore.instance);
});

// StreamProvider for the list of topics
// This provider will stream the list of topics from Firestore
// and make it available to the UI, handling loading/error states automatically.
final topicsStreamProvider = StreamProvider<List<Topic>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getTopicsStream();
});

// Optional: Provider to trigger adding dummy topics
// This could be a FutureProvider or a method on another notifier.
// For simplicity, keeping it separate for now.
// The actual call to addDummyTopics might be done from SplashScreen or HomeScreen logic.

// Example of a FutureProvider if you want to expose the addDummyTopics action
// final addDummyTopicsProvider = FutureProvider<void>((ref) async {
//   final firestoreService = ref.watch(firestoreServiceProvider);
//   await firestoreService.addDummyTopics();
// });
