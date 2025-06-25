// lib/providers/vocabulary_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Required for FirestoreService
import 'package:myapp/models/vocabulary_item.dart';
import 'package:myapp/services/firestore_service.dart';

// Provider for FirestoreService instance
// This assumes you have a way to provide FirebaseFirestore.instance
// For example, you might have a general firebaseProvider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(FirebaseFirestore.instance);
});

// StreamProvider for vocabulary items of a specific topic.
// It takes a topicId as a family argument.
final vocabularyForTopicProvider =
    StreamProvider.family<List<VocabularyItem>, String>((ref, topicId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  if (topicId.isEmpty) {
    // Return an empty stream if topicId is empty to avoid querying with an empty string,
    // which might lead to errors or unintended behavior depending on Firestore rules.
    return Stream.value([]);
  }
  return firestoreService.getVocabularyStreamForTopic(topicId);
});

// Provider to hold the currently selected topicId for vocabulary display.
// This can be used by UI components to set which topic's vocabulary to load.
// Initially, it can be null or an empty string if no topic is selected.
final currentTopicIdForVocabularyProvider = StateProvider<String?>((ref) => null);

// A combined provider that watches the currentTopicIdForVocabularyProvider
// and then fetches the vocabulary for that topic.
// This simplifies watching vocabulary in the UI.
final currentVocabularyListProvider = StreamProvider<List<VocabularyItem>>((ref) {
  final currentTopicId = ref.watch(currentTopicIdForVocabularyProvider);
  if (currentTopicId == null || currentTopicId.isEmpty) {
    return Stream.value([]); // Return empty list if no topic is selected
  }
  // Depend on vocabularyForTopicProvider with the currentTopicId
  return ref.watch(vocabularyForTopicProvider(currentTopicId).stream);
});

// Example of how to use addDummyVocabulary.
// This is more of a utility function and might be called from somewhere during app initialization
// or a debug screen.
// It's not a "provider" in the sense of providing ongoing state, but uses providers.
//
// Note: This provider/function should be called carefully, e.g., once during app setup.
// Consider how and when `topicIds` are fetched. This example assumes they are passed.
// You might need a more sophisticated approach for production.
final addDummyVocabularyProvider = FutureProvider.autoDispose.family<void, List<String>>((ref, topicIds) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  // First, ensure dummy topics are added if needed.
  // This might be redundant if called after topics are already ensured.
  // Consider the overall app initialization flow.
  await firestoreService.addDummyTopics(); // Assuming this creates topics and their IDs are somehow available

  // Then add dummy vocabulary, associating them with the provided topicIds.
  // In a real scenario, you'd fetch actual topic IDs after they are created.
  // For this example, we assume topicIds are correctly passed.
  if (topicIds.isNotEmpty) {
    await firestoreService.addDummyVocabulary(topicIds);
  } else {
    // Handle the case where no topic IDs are available, perhaps log or skip.
    print("No topic IDs provided to addDummyVocabularyProvider, skipping dummy vocabulary addition.");
  }
});

// Provider to manage the currently selected VocabularyItem for detail view
final selectedVocabularyItemProvider = StateProvider<VocabularyItem?>((ref) => null);

// Provider to manage the selected language for displaying definitions and examples
// Defaults to 'de' (German). Other options: 'en', 'es'.
final vocabularyDetailLanguageProvider = StateProvider<String>((ref) => 'de');
