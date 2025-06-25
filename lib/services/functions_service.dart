// lib/services/functions_service.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:http/http.dart' as http;
import 'package:myapp/models/challenge_model.dart'; // Assuming ChallengeModel is here

// Provider for FunctionsService (optional, but good practice for dependency injection)
// final functionsServiceProvider = Provider<FunctionsService>((ref) {
//   return FunctionsService(FirebaseAuth.instance);
// });

class FunctionsService {
  final FirebaseAuth _firebaseAuth;
  // TODO: Replace with your actual cloud function region and project ID, or use FirebaseFunctions SDK for callable.
  // For https.onRequest, the URL is typically:
  // https://<REGION>-<PROJECT_ID>.cloudfunctions.net/<FUNCTION_NAME>
  // Example: "https://us-central1-your-project-id.cloudfunctions.net/generateDailyChallenge"
  // It's best to make this configurable or discoverable if possible.
  final String _cloudFunctionBaseUrl;

  FunctionsService(this._firebaseAuth, {String? cloudFunctionBaseUrl})
    : _cloudFunctionBaseUrl = cloudFunctionBaseUrl ?? _getDefaultBaseUrl();

  static String _getDefaultBaseUrl() {
    // This is a placeholder. In a real app, you'd get this from config.
    // Or, if you know your project ID and region, you can hardcode it during development.
    // For demonstration, let's assume a common region.
    // IMPORTANT: Replace 'YOUR_PROJECT_ID' and ensure 'us-central1' is correct.
    const String projectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'YOUR_PROJECT_ID');
    if (projectId == 'YOUR_PROJECT_ID' && kDebugMode) {
      print("FunctionsService: FIREBASE_PROJECT_ID environment variable not set. Using placeholder. Function calls will likely fail.");
    }
    return "https://us-central1-$projectId.cloudfunctions.net";
  }

  /// Calls the 'generateDailyChallenge' Firebase Cloud Function.
  ///
  /// Returns a [ChallengeModel] if successful, otherwise null.
  /// Throws an exception if the user is not authenticated or if there's a network/server error.
  Future<ChallengeModel?> generateAndGetDailyChallenge() async {
    final User? currentUser = _firebaseAuth.currentUser;

    if (currentUser == null) {
      if (kDebugMode) {
        print('FunctionsService: User not authenticated. Cannot call generateDailyChallenge.');
      }
      throw Exception('User not authenticated.'); // Or return null based on desired error handling
    }

    try {
      final String token = await currentUser.getIdToken(true); // Force refresh token
      final Uri url = Uri.parse('$_cloudFunctionBaseUrl/generateDailyChallenge');

      if (kDebugMode) {
        print('FunctionsService: Calling generateDailyChallenge at $url');
      }

      final response = await http.post( // Using POST, can be GET if function designed for it
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json', // Important if sending a body, good practice anyway
        },
        // body: jsonEncode({}), // Send an empty JSON body or specific parameters if your function expects them
      );

      if (kDebugMode) {
        print('FunctionsService: generateDailyChallenge response status: ${response.statusCode}');
        print('FunctionsService: generateDailyChallenge response body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['challenge'] != null) {
          // Assuming the function returns { "message": "...", "challenge": { ... } }
          return ChallengeModel.fromJson(responseData['challenge'] as Map<String, dynamic>);
        } else {
          // Handle cases where the challenge might not be in the expected format
           if (kDebugMode) {
            print('FunctionsService: Challenge data not found in response: ${responseData}');
          }
          // If the function returns just the challenge directly without a wrapper:
          // return ChallengeModel.fromJson(responseData as Map<String, dynamic>);
          return null;
        }
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error'] as String? ?? 'Failed to generate daily challenge.';
        if (kDebugMode) {
          print('FunctionsService: Error calling generateDailyChallenge: ${response.statusCode} - $errorMessage');
        }
        throw Exception(errorMessage);
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FunctionsService: FirebaseAuthException while getting ID token: ${e.code} - ${e.message}');
      }
      rethrow; // Rethrow to be caught by the caller
    } catch (e) {
      if (kDebugMode) {
        print('FunctionsService: Exception in generateAndGetDailyChallenge: $e');
      }
      rethrow; // Rethrow for UI to handle
    }
  }
}
