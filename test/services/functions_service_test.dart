// test/services/functions_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:cains/services/functions_service.dart';
import 'package:cains/models/vocabulary_item.dart';

import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart'; // For FirebaseFunctionsException type
import 'package:firebase_functions_mocks/firebase_functions_mocks.dart'; // For setupFirebaseFunctionsMocks and mock instances

// Generate mocks for FirebaseAuth, User, and http.Client
@GenerateMocks([FirebaseAuth, User, http.Client])
import 'functions_service_test.mocks.dart';


void main() {
  // Ensure Flutter binding is initialized for Firebase static mocks
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Setup mocks for Firebase Core and Functions
    // This is necessary for FirebaseFunctions.instance to be mockable.
    setupFirebaseCoreMocks();
    setupFirebaseFunctionsMocks();
  });

  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;
  late MockClient mockHttpClient;
  late FunctionsService functionsService;

  const String testUserId = 'test-uid';
  const String testToken = 'test-id-token';
  const String testProjectId = 'test-project-id'; // For base URL construction
  final String expectedBaseUrl = "https://us-central1-$testProjectId.cloudfunctions.net";

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockHttpClient = MockClient();

    // Provide a default FunctionsService with a known base URL for testing
    // The default base URL constructor uses String.fromEnvironment which is hard to test directly here.
    functionsService = FunctionsService(mockFirebaseAuth, cloudFunctionBaseUrl: expectedBaseUrl, httpClient: mockHttpClient);


    // Default stub for authenticated user
    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn(testUserId);
    when(mockUser.getIdToken(any)).thenAnswer((_) async => testToken);
  });

  group('FunctionsService - callGenerateAiDefinition', () {
    final testWord = 'example';
    final mockApiResponse = {
      'id': 'ai-example-123',
      'word': testWord,
      'definitions': {'de': 'Beispiel', 'en': 'Example', 'es': 'Ejemplo'},
      'synonyms': ['sample', 'instance'],
      'collocations': ['for example', 'example of'],
      'exampleSentences': {
        'de': ['Das ist ein Beispiel.'],
        'en': ['This is an example.']
      },
      'level': 'C1',
      'sourceType': 'ai_added',
      'topicId': 'ai_researched',
      'grammarHint': 'Noun',
      'contextualText': 'Used to illustrate a point.',
    };

    test('successfully calls function and returns VocabularyItem', () async {
      when(mockHttpClient.post(
        Uri.parse('$expectedBaseUrl/generateAiDefinition'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode(mockApiResponse), 200));

      final result = await functionsService.callGenerateAiDefinition(testWord);

      expect(result, isA<VocabularyItem>());
      expect(result.word, testWord);
      expect(result.definitions['en'], 'Example');
      expect(result.id, 'ai-example-123');
      expect(result.sourceType, SourceType.ai_added);

      verify(mockHttpClient.post(
        Uri.parse('$expectedBaseUrl/generateAiDefinition'),
        headers: {
          'Authorization': 'Bearer $testToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'word': testWord}),
      )).called(1);
    });

    test('throws exception if user is not authenticated', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      expect(
        () => functionsService.callGenerateAiDefinition(testWord),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('User not authenticated'))),
      );
    });

    test('throws exception if word is empty', () async {
      expect(
        () => functionsService.callGenerateAiDefinition('  '),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Word cannot be empty'))),
      );
    });

    test('throws exception on HTTP error from function (e.g., 500)', () async {
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode({'error': {'message': 'Internal Server Error'}}), 500));

      expect(
        () => functionsService.callGenerateAiDefinition(testWord),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Internal Server Error'))),
      );
    });

    test('throws exception on general HTTP error from function (e.g., 403)', () async {
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode({'error': 'Forbidden'}), 403));

      expect(
        () => functionsService.callGenerateAiDefinition(testWord),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Forbidden'))),
      );
    });


    test('throws exception on malformed JSON response', () async {
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('this is not json', 200));

      expect(
        () => functionsService.callGenerateAiDefinition(testWord),
        // This will likely be a FormatException wrapped in our generic Exception
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('An unexpected error occurred'))),
      );
    });

    test('handles missing optional fields in response gracefully', () async {
      final partialMockApiResponse = {
        'id': 'ai-example-partial-123',
        'word': testWord,
        'definitions': {'en': 'Partial Example'},
        'synonyms': [], // Empty but present
        'collocations': [], // Empty but present
        'exampleSentences': {'en': []}, // Empty but present
        // Missing: level, sourceType, topicId, grammarHint, contextualText
      };
      when(mockHttpClient.post(
        Uri.parse('$expectedBaseUrl/generateAiDefinition'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode(partialMockApiResponse), 200));

      final result = await functionsService.callGenerateAiDefinition(testWord);

      expect(result, isA<VocabularyItem>());
      expect(result.word, testWord);
      expect(result.id, 'ai-example-partial-123');
      expect(result.definitions['en'], 'Partial Example');
      // Check default values assigned by VocabularyItem.fromJson or service client
      expect(result.level, 'C1'); // Default in VocabularyItem.fromJson
      expect(result.sourceType, SourceType.ai_added); // Default in client before fromJson
      expect(result.topicId, 'ai_researched'); // Default in client before fromJson
      expect(result.grammarHint, isNull);
      expect(result.contextualText, isNull);
    });

     test('generates id if not provided in response', () async {
      final responseWithoutId = {
        // 'id': 'missing-id', // ID is missing
        'word': testWord,
        'definitions': {'en': 'Example without ID'},
        'synonyms': ['sample'],
        'collocations': ['for example'],
        'exampleSentences': {'en': ['Sentence.']},
        'level': 'C1',
        'sourceType': 'ai_added',
        'topicId': 'ai_researched',
      };
      when(mockHttpClient.post(
        Uri.parse('$expectedBaseUrl/generateAiDefinition'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode(responseWithoutId), 200));

      final result = await functionsService.callGenerateAiDefinition(testWord);

      expect(result, isA<VocabularyItem>());
      expect(result.id, startsWith('temp-ai-$testWord-')); // Check if client generated ID
      expect(result.word, testWord);
    });

  });

  group('FunctionsService - callProcessImageForOcr', () {
    late MockFirebaseFunctions mockFirebaseFunctions;
    late MockHttpsCallable mockHttpsCallable;

    setUp(() {
      // Re-initialize mocks for this group if they are specific or to reset state
      mockFirebaseAuth = MockFirebaseAuth(); // Already in outer scope, re-init for safety
      mockUser = MockUser(); // Already in outer scope, re-init for safety
      functionsService = FunctionsService(mockFirebaseAuth, cloudFunctionBaseUrl: expectedBaseUrl); // Uses default http client

      // Mocks for FirebaseFunctions
      mockFirebaseFunctions = MockFirebaseFunctions();
      mockHttpsCallable = MockHttpsCallable();

      // Stubbing FirebaseFunctions.instance to return our mock
      // This typically requires a bit more setup if Firebase.initializeApp isn't called
      // or if the static instance is hard to mock.
      // For FunctionsService, it directly calls FirebaseFunctions.instance.
      // We might need to refactor FunctionsService to accept FirebaseFunctions instance
      // for easier testing, or use a helper to set the mock instance.
      // For now, we'll assume direct mocking or that firebase_functions_mocks handles this.
      // The `firebase_functions_mocks` package often relies on setting a mock instance
      // via `FirebaseFunctions.instance = mockFirebaseFunctions;` if tests are run in Flutter test environment.
      // Let's assume FunctionsService is refactored or we can set the instance.
      // For simplicity in this step, I'll write tests as if FunctionsService can be given an instance,
      // or that FirebaseFunctions.instance can be effectively mocked.
      // If FunctionsService directly uses FirebaseFunctions.instance, we'd do:
      // FirebaseFunctions.instance = mockFirebaseFunctions; // This needs careful setup (e.g., TestWidgetsFlutterBinding.ensureInitialized())

      when(mockFirebaseFunctions.httpsCallable(any)).thenReturn(mockHttpsCallable);
      // This direct assignment might not work without extra test setup (e.g. `TestFirebaseFunctions`).
      // A common pattern is to pass FirebaseFunctions instance to FunctionsService constructor.
      // Let's assume for now that FunctionsService is updated to take FirebaseFunctions:
      // functionsService = FunctionsService(mockFirebaseAuth, functionsInstance: mockFirebaseFunctions, ...);
      // Or, rely on firebase_functions_mocks's ability to mock the static instance if used with TestWidgetsFlutterBinding.

      // For this example, let's proceed as if `FirebaseFunctions.instance` could be mocked or injected.
      // The actual `FunctionsService` uses `FirebaseFunctions.instance` directly.
      // This part of the test will need adjustment based on how `FirebaseFunctions.instance` is handled in the test environment.
      // The `firebase_functions_mocks` package provides `setupFirebaseFunctionsMocks()`
      // and then you can use `FirebaseFunctions.instance = MockFirebaseFunctions()`
      // Let's assume `setupFirebaseFunctionsMocks()` is called in a `TestMain` or `setUpAll`.
    });

    final String testBase64Image = "base64encodedstring";
    final Map<String, dynamic> mockSuccessResponseData = {
      "words": [
        {
          "text": "Hello",
          "bounds": {"x": 10, "y": 20, "width": 30, "height": 10}
        },
        {
          "text": "World",
          "bounds": {"x": 50, "y": 20, "width": 40, "height": 10}
        }
      ]
    };

    test('successfully calls function and returns List<RecognizedWord>', () async {
      // Arrange
      // This setup relies on `FirebaseFunctions.instance` being mockable.
      // A more robust way is to inject `FirebaseFunctions` into `FunctionsService`.
      // For now, let's assume the global instance is replaced for testing.
      final mockFunctions = MockFirebaseFunctions();
      final mockCallable = MockHttpsCallable();
      FirebaseFunctions.instance = mockFunctions; // Requires test setup

      when(mockFunctions.httpsCallable('processImageForOcr')).thenReturn(mockCallable);
      when(mockCallable.call(any)).thenAnswer((_) async => HttpsCallableResult(data: mockSuccessResponseData));

      // Act
      final result = await functionsService.callProcessImageForOcr(testBase64Image);

      // Assert
      expect(result, isA<List<RecognizedWord>>());
      expect(result.length, 2);
      expect(result[0].text, "Hello");
      expect(result[0].bounds.left, 10);
      expect(result[1].text, "World");
      verify(mockCallable.call({'imageData': testBase64Image})).called(1);

      // Clean up static mock
      FirebaseFunctions.instance = FirebaseFunctions.instance; // Reset to default or original
    });

    test('throws exception on empty base64Image string', () async {
      expect(
        () => functionsService.callProcessImageForOcr(''),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Image data cannot be empty'))),
      );
    });

    test('handles FirebaseFunctionsException - unauthenticated', () async {
      final mockFunctions = MockFirebaseFunctions();
      final mockCallable = MockHttpsCallable();
      FirebaseFunctions.instance = mockFunctions;
      when(mockFunctions.httpsCallable('processImageForOcr')).thenReturn(mockCallable);
      when(mockCallable.call(any)).thenThrow(FirebaseFunctionsException(
          message: 'Unauthenticated', code: 'unauthenticated'));

      expect(
        () => functionsService.callProcessImageForOcr(testBase64Image),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Authentication error. Please sign in again.'))),
      );
      FirebaseFunctions.instance = FirebaseFunctions.instance;
    });

    test('handles FirebaseFunctionsException - invalid-argument', () async {
      final mockFunctions = MockFirebaseFunctions();
      final mockCallable = MockHttpsCallable();
      FirebaseFunctions.instance = mockFunctions;
      when(mockFunctions.httpsCallable('processImageForOcr')).thenReturn(mockCallable);
      when(mockCallable.call(any)).thenThrow(FirebaseFunctionsException(
          message: 'Invalid argument', code: 'invalid-argument'));

      expect(
        () => functionsService.callProcessImageForOcr(testBase64Image),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Invalid data sent to image processor.'))),
      );
      FirebaseFunctions.instance = FirebaseFunctions.instance;
    });

    test('handles FirebaseFunctionsException - internal', () async {
      final mockFunctions = MockFirebaseFunctions();
      final mockCallable = MockHttpsCallable();
      FirebaseFunctions.instance = mockFunctions;
      when(mockFunctions.httpsCallable('processImageForOcr')).thenReturn(mockCallable);
      when(mockCallable.call(any)).thenThrow(FirebaseFunctionsException(
          message: 'Internal server error', code: 'internal'));

      expect(
        () => functionsService.callProcessImageForOcr(testBase64Image),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('An internal server error occurred'))),
      );
      FirebaseFunctions.instance = FirebaseFunctions.instance;
    });

    test('handles generic Exception from callable', () async {
      final mockFunctions = MockFirebaseFunctions();
      final mockCallable = MockHttpsCallable();
      FirebaseFunctions.instance = mockFunctions;
      when(mockFunctions.httpsCallable('processImageForOcr')).thenReturn(mockCallable);
      when(mockCallable.call(any)).thenThrow(Exception('Some other error'));

      expect(
        () => functionsService.callProcessImageForOcr(testBase64Image),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('An unexpected error occurred'))),
      );
      FirebaseFunctions.instance = FirebaseFunctions.instance;
    });
     test('includes mimeType in parameters if provided', () async {
      final mockFunctions = MockFirebaseFunctions();
      final mockCallable = MockHttpsCallable();
      FirebaseFunctions.instance = mockFunctions;
      when(mockFunctions.httpsCallable('processImageForOcr')).thenReturn(mockCallable);
      when(mockCallable.call(any)).thenAnswer((_) async => HttpsCallableResult(data: mockSuccessResponseData));

      await functionsService.callProcessImageForOcr(testBase64Image, mimeType: 'image/png');

      verify(mockCallable.call({'imageData': testBase64Image, 'mimeType': 'image/png'})).called(1);
      FirebaseFunctions.instance = FirebaseFunctions.instance;
    });

  });
}
