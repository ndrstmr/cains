// lib/providers/daily_challenge_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/models/challenge_model.dart';
import 'package:myapp/providers/user_progress_provider.dart'; // For currentUserIdProvider, firestoreServiceProvider
// For FirestoreService type, if needed directly
import 'package:myapp/services/functions_service.dart'; // For FunctionsService and its provider
import 'package:flutter/foundation.dart'; // For kDebugMode

// Assume functionsServiceProvider is defined, e.g., in lib/services/functions_service.dart or a central providers file.
// If not, it would look something like this:
// final functionsServiceProvider = Provider<FunctionsService>((ref) {
//   final firebaseAuth = ref.watch(authStateProvider).asData?.value != null
//       ? FirebaseAuth.instance
//       : throw Exception("FirebaseAuth instance needed and user not available"); // Or handle more gracefully
//   return FunctionsService(firebaseAuth);
// });
// For this file, we'll assume functionsServiceProvider is correctly defined elsewhere and provides FunctionsService.
// Placeholder if not defined elsewhere (ensure it's properly initialized in your app)
final functionsServiceProvider = Provider<FunctionsService>((ref) {
  throw UnimplementedError('functionsServiceProvider must be overridden with a real instance.');
  // Example:
  // final auth = ref.watch(authStateProvider).valueOrNull == null ? null : FirebaseAuth.instance;
  // if (auth == null) throw Exception("User not authenticated - cannot create FunctionsService");
  // return FunctionsService(auth);
});


/// Provides a stream of all daily challenges for the current user.
///
/// This stream directly reflects the `users/{userId}/daily_challenges` subcollection.
/// It might return multiple challenges if old ones are not cleared.
/// Consider filtering or limiting if only today's challenge is desired at all times via this stream.
final dailyChallengesStreamProvider = StreamProvider.autoDispose<List<ChallengeModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  if (userId != null && userId.isNotEmpty) {
    return firestoreService.getDailyChallengesStream(userId);
  } else {
    return Stream.value([]); // No user, no challenges
  }
});

/// A provider that attempts to fetch or generate today's daily challenge.
///
/// It calls the `generateAndGetDailyChallenge` cloud function.
/// This can be refreshed to try again.
/// The result is the [ChallengeModel] for today, or null if none could be provided.
final todayDailyChallengeProvider = FutureProvider.autoDispose<ChallengeModel?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final functionsService = ref.read(functionsServiceProvider); // Use read for one-time call

  if (userId == null || userId.isEmpty) {
    if (kDebugMode) {
      print("todayDailyChallengeProvider: No user ID, cannot fetch/generate challenge.");
    }
    return null; // No user, no challenge
  }

  try {
    if (kDebugMode) {
      print("todayDailyChallengeProvider: Attempting to generate/fetch challenge for user $userId.");
    }
    // This call goes to the cloud function, which itself checks if a challenge for today exists
    // and returns it, or generates a new one.
    final challenge = await functionsService.generateAndGetDailyChallenge();

    if (challenge != null && kDebugMode) {
      print("todayDailyChallengeProvider: Successfully received challenge: ${challenge.id} - ${challenge.title}");
    } else if (challenge == null && kDebugMode) {
      print("todayDailyChallengeProvider: No challenge returned from function for user $userId.");
    }
    return challenge;
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print("todayDailyChallengeProvider: Error fetching/generating daily challenge for user $userId: $e");
      print(stackTrace);
    }
    // Propagate the error so UI can handle it, or return null
    // Depending on how you want to show errors, you might rethrow or handle here.
    // For a FutureProvider, rethrowing allows .when() to catch it in the error state.
    rethrow;
  }
});

/// A more specific provider that filters the stream from `dailyChallengesStreamProvider`
/// to return only today's challenge, if available.
/// It uses the `todayDateString` to identify the challenge.
final currentDayChallengeProvider = Provider.autoDispose<ChallengeModel?>((ref) {
  final allChallengesAsyncValue = ref.watch(dailyChallengesStreamProvider);
  final today = DateTime.now();
  final todayDateString = "${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}";

  return allChallengesAsyncValue.when(
    data: (challenges) {
      try {
        return challenges.firstWhere((challenge) => challenge.id == todayDateString);
      } catch (e) {
        // firstWhere throws StateError if no element found
        return null; // No challenge found for today's date string ID
      }
    },
    loading: () => null, // Or some specific loading state object
    error: (e, st) => null, // Or some specific error state object
  );
});
