// lib/services/functions_service.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:http/http.dart' as http;
import 'package:myapp/models/challenge_model.dart'; // Assuming ChallengeModel is here

// Provider for FunctionsService (optional, but good practice for dependency injection)
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Uncomment if using Riverpod provider
final functionsServiceProvider = Provider<FunctionsService>((ref) { // Uncomment if using Riverpod provider
  // It's often better to get FirebaseAuth instance from an authProvider if it exists,
  // to ensure consistency and testability.
  // For example: final auth = ref.watch(firebaseAuthProvider);
  // However, direct use is also common for simplicity.
  return FunctionsService(FirebaseAuth.instance);
});

import 'package:cains/models/vocabulary_item.dart'; // Import VocabularyItem
import 'package:firebase_functions/firebase_functions.dart';
import 'dart:ui'; // For Rect

// Represents a single word recognized by OCR, along with its bounding box.
class RecognizedWord {
  final String text;
  final Rect bounds; // Using dart:ui Rect for convenience in Flutter

  RecognizedWord({required this.text, required this.bounds});

  factory RecognizedWord.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> boundsMap = json['bounds'] as Map<String, dynamic>;
    return RecognizedWord(
      text: json['text'] as String,
      bounds: Rect.fromLTWH(
        (boundsMap['x'] as num).toDouble(),
        (boundsMap['y'] as num).toDouble(),
        (boundsMap['width'] as num).toDouble(),
        (boundsMap['height'] as num).toDouble(),
      ),
    );
  }

  @override
  String toString() {
    return 'RecognizedWord(text: $text, bounds: $bounds)';
  }
}

class FunctionsService {
  final FirebaseAuth _firebaseAuth;
  // TODO: Replace with your actual cloud function region and project ID.
  // For https.onRequest, the URL is typically:
  // https://<REGION>-<PROJECT_ID>.cloudfunctions.net/<FUNCTION_NAME>
  // Example: "https://us-central1-your-project-id.cloudfunctions.net/generateDailyChallenge"
  // It's best to make this configurable or discoverable if possible.
  final String _cloudFunctionBaseUrl;
  final http.Client _httpClient;

  FunctionsService(this._firebaseAuth, {String? cloudFunctionBaseUrl, http.Client? httpClient})
    : _cloudFunctionBaseUrl = cloudFunctionBaseUrl ?? _getDefaultBaseUrl(),
      _httpClient = httpClient ?? http.Client();

  static String _getDefaultBaseUrl() {
    // Reads configuration from --dart-define values.
    // Example during build or run:
    // flutter run --dart-define=FIREBASE_PROJECT_ID=your-project-id \
    //             --dart-define=FIREBASE_REGION=europe-west1

    const String projectId =
        String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
    const String region =
        String.fromEnvironment('FIREBASE_REGION', defaultValue: 'us-central1');

    if (projectId.isEmpty) {
      if (kDebugMode) {
        print(
            'FunctionsService: FIREBASE_PROJECT_ID not provided. Cloud function calls will fail.');
      }
      return '';
    }

    return 'https://$region-$projectId.cloudfunctions.net';
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
            print('FunctionsService: Challenge data not found in response: $responseData');
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

  /// Calls the 'generateAiDefinition' Firebase Cloud Function.
  ///
  /// [word]: The word to get a definition for.
  /// Returns a [VocabularyItem] if successful.
  /// Throws an exception if the user is not authenticated, if there's a network/server error,
  /// or if the function returns an error.
  Future<VocabularyItem> callGenerateAiDefinition(String word) async {
    final User? currentUser = _firebaseAuth.currentUser;

    if (currentUser == null) {
      if (kDebugMode) {
        print('FunctionsService: User not authenticated. Cannot call generateAiDefinition.');
      }
      throw Exception('User not authenticated. Please sign in.');
    }

    if (word.trim().isEmpty) {
      if (kDebugMode) {
        print('FunctionsService: Word cannot be empty for generateAiDefinition.');
      }
      throw Exception('Word cannot be empty.');
    }

    try {
      final String token = await currentUser.getIdToken(true); // Force refresh token
      final Uri url = Uri.parse('$_cloudFunctionBaseUrl/generateAiDefinition');

      if (kDebugMode) {
        print('FunctionsService: Calling generateAiDefinition at $url for word: "$word"');
      }

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'word': word.trim()}),
      );

      if (kDebugMode) {
        print('FunctionsService: generateAiDefinition response status: ${response.statusCode}');
        print('FunctionsService: generateAiDefinition response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // The cloud function is expected to return data that directly maps to VocabularyItem fields.
        // It also needs an 'id' and 'topicId', which we might need to generate client-side
        // or the function needs to provide them or suitable defaults.
        // For now, assume the function returns a complete VocabularyItem structure,
        // including a temporary or generated ID if necessary.
        // If 'id' is not provided by the function, we might use word + timestamp or similar,
        // or let Firestore generate it upon saving.
        // For 'topicId', we can use a default like 'ai_researched'.

        // Let's assume the function returns a JSON that can be directly used to create a VocabularyItem.
        // If the function returns the fields of VocabularyItem, but not 'id', 'sourceType', 'topicId',
        // we would need to augment it here.
        // Example:
        // final Map<String, dynamic> itemData = responseData as Map<String, dynamic>;
        // itemData['id'] = responseData['id'] ?? 'temp-${DateTime.now().millisecondsSinceEpoch}'; // Or handle ID generation strategy
        // itemData['sourceType'] = SourceType.ai_added.toString().split('.').last; // Ensure this matches enum storage
        // itemData['topicId'] = responseData['topicId'] ?? 'ai_researched'; // Default topicId
        // itemData['level'] = responseData['level'] ?? 'C1'; // Default level

        // The prompt says: "Ausgabe: JSON-Format entsprechend VocabularyItem Modell"
        // This implies the function should return all necessary fields.
        // The VocabularyItem.fromFirestore expects a DocumentSnapshot, which is not what we have here.
        // We need a factory method like VocabularyItem.fromJson(Map<String, dynamic> json, String id)
        // or the function needs to return an 'id'.

        // For now, let's assume the function returns a JSON that can be directly passed
        // to a hypothetical VocabularyItem.fromJson method or that all fields including a temporary ID are returned.
        // Let's refine VocabularyItem to have a .fromJson constructor.

        // Assuming the function returns data directly usable by a fromJson factory
        // and 'id' might be part of the response or needs to be handled.
        // For now, let's construct it manually based on the expected fields.
        // This part will need adjustment based on the exact JSON structure returned by the cloud function.

        final Map<String, dynamic> data = responseData as Map<String, dynamic>;

        // Ensure 'id' is present in the data from the cloud function, or generate one if necessary.
        // The VocabularyItem.fromJson factory expects 'id'.
        // If the Cloud Function guarantees an 'id', this check can be simpler.
        if (!data.containsKey('id') || data['id'] == null) {
          // If ID is critical and must come from the function, this should be an error.
          // For now, let's generate a temporary one if missing, but flag it.
          if (kDebugMode) {
            print("FunctionsService: 'id' field missing in response from generateAiDefinition. Generating temporary ID.");
          }
          data['id'] = 'temp-ai-${word.trim()}-${DateTime.now().millisecondsSinceEpoch}';
        }

        // The 'sourceType' should ideally be set by the backend or be inferred.
        // If not provided, default to 'ai_added'.
        if (!data.containsKey('sourceType') || data['sourceType'] == null) {
            data['sourceType'] = SourceType.ai_added.toString().split('.').last;
        }

        // Default 'topicId' if not provided.
        if (!data.containsKey('topicId') || data['topicId'] == null) {
            data['topicId'] = 'ai_researched';
        }

        return VocabularyItem.fromJson(data);

      } else {
        String errorMessage = 'Failed to get AI definition.';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['error']?['message'] as String? ?? errorData['message'] as String? ?? errorData['error'] as String? ?? errorMessage;
        } catch (e) {
          // Ignore parsing error, use default message
          if (kDebugMode) {
            print('FunctionsService: Could not parse error response body: ${response.body}');
          }
        }
        if (kDebugMode) {
          print('FunctionsService: Error calling generateAiDefinition: ${response.statusCode} - $errorMessage');
        }
        throw Exception(errorMessage);
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FunctionsService: FirebaseAuthException while getting ID token: ${e.code} - ${e.message}');
      }
      throw Exception('Authentication error: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('FunctionsService: Exception in callGenerateAiDefinition: $e');
      }
      // Avoid rethrowing generic "Exception" if it's already a more specific one from above
      if (e is Exception && e.toString().contains('User not authenticated')) rethrow;
      if (e is Exception && e.toString().contains('Word cannot be empty')) rethrow;
      if (e is Exception && e.toString().contains('Failed to get AI definition')) rethrow;
      if (e is Exception && e.toString().contains('Authentication error')) rethrow;

      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Calls the 'processImageForOcr' Firebase Cloud Function.
  ///
  /// [base64Image]: The Base64 encoded string of the image.
  /// [mimeType]: Optional. The MIME type of the image (e.g., "image/jpeg").
  /// Returns a list of [RecognizedWord] objects.
  /// Throws an exception if the user is not authenticated, if there's a network/server error,
  /// or if the function returns an error.
  Future<List<RecognizedWord>> callProcessImageForOcr(
    String base64Image, {
    String? mimeType,
  }) async {
    // No need to check _firebaseAuth.currentUser here, as HttpsCallable handles authentication implicitly.
    // If the user is not authenticated, FirebaseFunctions will return an error.

    if (base64Image.trim().isEmpty) {
      if (kDebugMode) {
        print('FunctionsService: base64Image cannot be empty for processImageForOcr.');
      }
      throw Exception('Image data cannot be empty.');
    }

    try {
      // It's good practice to specify the region if your functions are not in us-central1
      // FirebaseFunctions.instanceFor(region: 'europe-west1')
      // For now, using the default region.
      final callable = FirebaseFunctions.instance.httpsCallable('processImageForOcr');

      final Map<String, dynamic> params = {
        'imageData': base64Image,
      };
      if (mimeType != null && mimeType.isNotEmpty) {
        params['mimeType'] = mimeType;
      }

      if (kDebugMode) {
        print('FunctionsService: Calling processImageForOcr with image data length: ${base64Image.length}, mimeType: $mimeType');
      }

      final HttpsCallableResult result = await callable.call(params);

      if (kDebugMode) {
        print('FunctionsService: processImageForOcr response data: ${result.data}');
      }

      // The Cloud Function returns a Map: { "words": [ { "text": "...", "bounds": { ... } }, ... ] }
      final Map<String, dynamic> data = result.data as Map<String, dynamic>;
      final List<dynamic> wordsList = data['words'] as List<dynamic>;

      final List<RecognizedWord> recognizedWords = wordsList
          .map((wordData) => RecognizedWord.fromJson(wordData as Map<String, dynamic>))
          .toList();

      if (kDebugMode) {
        print('FunctionsService: Parsed ${recognizedWords.length} words.');
      }
      return recognizedWords;

    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        print('FunctionsService: FirebaseFunctionsException in callProcessImageForOcr:');
        print('Code: ${e.code}');
        print('Message: ${e.message}');
        print('Details: ${e.details}');
      }
      // Provide a more user-friendly message based on the error code
      String userMessage = 'Failed to process image. Please try again.';
      if (e.code == 'unauthenticated') {
        userMessage = 'Authentication error. Please sign in again.';
      } else if (e.code == 'invalid-argument') {
        userMessage = 'Invalid data sent to image processor. Please select a valid image.';
      } else if (e.code == 'internal') {
        userMessage = 'An internal server error occurred while processing the image.';
      }
      throw Exception(userMessage);
    } catch (e) {
      if (kDebugMode) {
        print('FunctionsService: Generic Exception in callProcessImageForOcr: $e');
      }
      throw Exception('An unexpected error occurred while processing the image: ${e.toString()}');
    }
  }
}
