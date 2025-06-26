// Provider for managing the state of the AI Research Screen.
// Handles user input, loading states, error messages, and AI-generated results.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cains/models/vocabulary_item.dart';
import 'package:cains/services/functions_service.dart';
import 'package:cains/services/firestore_service.dart';
import 'package:cains/providers/auth_provider.dart'; // To get current user
import 'package:firebase_auth/firebase_auth.dart'; // For FirebaseAuth instance

// Represents the state of the AI Research screen.
@immutable
class AIResearchState {
  final String currentWord;
  final bool isLoading;
  final String? errorMessage;
  final VocabularyItem? result;
  final bool isSaving; // For "Add to vocabulary" loading state
  final String? successMessage; // For "Add to vocabulary" success

  const AIResearchState({
    this.currentWord = '',
    this.isLoading = false,
    this.errorMessage,
    this.result,
    this.isSaving = false,
    this.successMessage,
  });

  AIResearchState copyWith({
    String? currentWord,
    bool? isLoading,
    String? errorMessage,
    VocabularyItem? result,
    bool? clearResult, // To explicitly set result to null
    bool? isSaving,
    String? successMessage,
    bool? clearSuccessMessage, // To explicitly set successMessage to null
    bool? clearErrorMessage, // To explicitly set errorMessage to null
  }) {
    return AIResearchState(
      currentWord: currentWord ?? this.currentWord,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage == true ? null : errorMessage ?? this.errorMessage,
      result: clearResult == true ? null : result ?? this.result,
      isSaving: isSaving ?? this.isSaving,
      successMessage: clearSuccessMessage == true ? null : successMessage ?? this.successMessage,
    );
  }
}

// StateNotifier for the AI Research screen.
class AIResearchNotifier extends StateNotifier<AIResearchState> {
  final FunctionsService _functionsService;
  final FirestoreService? _firestoreService; // Nullable if user is not logged in
  final String? _userId; // Nullable if user is not logged in

  final TextEditingController wordController = TextEditingController();

  AIResearchNotifier(this._functionsService, this._firestoreService, this._userId)
      : super(const AIResearchState()) {
        wordController.addListener(() {
          // Sync controller's text with state.currentWord if needed, or drive from state.
          // For now, onWordChanged is used when submitting/searching.
          if (state.currentWord != wordController.text) {
             // If typing directly, update currentWord.
             // This might cause excessive rebuilds if not careful.
             // A dedicated method or debounce might be better.
             // For now, let's assume currentWord is mainly set by onSearch.
          }
        });
      }

  void onWordChanged(String word) {
    // This method is called by the TextFormField's onChanged.
    // We can update a temporary input state here if we don't want to trigger
    // full state updates on every keystroke for 'currentWord' used in fetch.
    // For simplicity, let's assume wordController.text is the source of truth at search time.
    // If we want instant validation or other effects, this needs more thought.
    // For now, this method might not be strictly necessary if wordController is used directly.
    // However, if we want to clear results immediately on typing, it is useful.
    if (word != state.currentWord) {
        state = state.copyWith(currentWord: word, clearResult: true, clearErrorMessage: true, clearSuccessMessage: true);
    }
  }

  Future<void> fetchAiResults() async {
    final wordToSearch = wordController.text.trim();
    if (wordToSearch.isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter a word.');
      return;
    }
    // Update currentWord to reflect what's being searched, and clear previous results/errors.
    state = state.copyWith(isLoading: true, currentWord: wordToSearch, errorMessage: null, clearResult: true, clearSuccessMessage: true);

    try {
      final result = await _functionsService.callGenerateAiDefinition(wordToSearch);
      state = state.copyWith(isLoading: false, result: result, currentWord: wordToSearch);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error fetching results: ${e.toString()}', currentWord: wordToSearch);
    }
  }

  Future<void> saveToVocabulary() async {
    if (state.result == null) {
      state = state.copyWith(errorMessage: "No result to save.");
      return;
    }
    if (_firestoreService == null || _userId == null) {
      state = state.copyWith(errorMessage: "Cannot save: User not logged in or service unavailable.");
      return;
    }

    state = state.copyWith(isSaving: true, clearSuccessMessage: true, clearErrorMessage: true);
    try {
      // Ensure the item has sourceType set to ai_added.
      // The VocabularyItem.fromJson factory already defaults sourceType to ai_added if not specified,
      // and the cloud function mock also sets it.
      // However, explicitly creating a new item or using copyWith ensures it.
      final itemToSave = VocabularyItem(
        id: state.result!.id, // Use existing ID from AI result
        word: state.result!.word,
        definitions: state.result!.definitions,
        synonyms: state.result!.synonyms,
        collocations: state.result!.collocations,
        exampleSentences: state.result!.exampleSentences,
        level: state.result!.level,
        sourceType: SourceType.ai_added, // Explicitly set
        topicId: state.result!.topicId, // Use existing from AI result (e.g., 'ai_researched')
        grammarHint: state.result!.grammarHint,
        contextualText: state.result!.contextualText,
      );

      await _firestoreService!.saveVocabularyItem(_userId!, itemToSave);
      state = state.copyWith(isSaving: false, successMessage: "'${itemToSave.word}' added to your vocabulary list!");
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'Error saving to vocabulary: ${e.toString()}');
    }
  }

  void clearError() {
    state = state.copyWith(clearErrorMessage: true);
  }

  void clearSuccessMessage() {
    state = state.copyWith(clearSuccessMessage: true);
  }

  @override
  void dispose() {
    wordController.dispose();
    super.dispose();
  }
}

// Provider definition for AIResearchNotifier.
// final aiResearchProvider = StateNotifierProvider<AIResearchNotifier, AIResearchState>((ref) {
//   // final functionsService = ref.watch(functionsServiceProvider); // Placeholder
//   // final firestoreService = ref.watch(firestoreServiceProvider); // Placeholder
//   // final userId = ref.watch(authProvider).currentUser?.uid; // Placeholder - ensure user is logged in
//   // if (userId == null) {
//   //   throw Exception('User not logged in. AI Research Provider requires an authenticated user.');
//   // }
//   // return AIResearchNotifier(functionsService, firestoreService, userId);
//   return AIResearchNotifier(); // Placeholder
// });

// Placeholder for functionsServiceProvider
// final functionsServiceProvider = Provider<FunctionsService>((ref) {
//   throw UnimplementedError();
// });

// Placeholder for firestoreServiceProvider
// Provider for FunctionsService if not already globally defined
// This assumes FunctionsService might be used elsewhere and could have its own provider.
// If it's only for AIResearchProvider, direct instantiation in aiResearchProvider is also fine.
final functionsServiceProvider = Provider<FunctionsService>((ref) {
  // FunctionsService requires FirebaseAuth instance.
  // It's better if FirebaseAuth.instance is passed from a common place or via another provider.
  // For now, directly creating it here.
  // Consider if FunctionsService should be a singleton or if FirebaseAuth.instance should be from a provider.
  return FunctionsService(FirebaseAuth.instance);
});

// Provider for FirestoreService (similar to FunctionsService, if not globally available)
// final firestoreServiceProvider = Provider<FirestoreService>((ref) {
//   return FirestoreService(FirebaseFirestore.instance); // Assuming FirebaseFirestore.instance
});

// Provider for FirestoreService (if not already globally available)
// This makes FirestoreService available for injection.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  // Assuming FirebaseFirestore.instance is the way to get the Firestore instance.
  // This should ideally come from a more central Firebase initialization if multiple services need it.
  // For now, direct instantiation is fine for this context.
  return FirestoreService(FirebaseFirestore.instance);
});


// Updated provider definition for AIResearchNotifier.
final aiResearchProvider = StateNotifierProvider<AIResearchNotifier, AIResearchState>((ref) {
  final functionsService = ref.watch(functionsServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final user = ref.watch(authStateChangesProvider).asData?.value;

  // If the user is null, FirestoreService and userId will be null.
  // The AIResearchNotifier is designed to handle nullable _firestoreService and _userId,
  // and its saveToVocabulary method will show an error if they are null when called.
  // The UI should ideally prevent access or disable save functionality if user is not logged in.
  return AIResearchNotifier(functionsService, firestoreService, user?.uid);
});
