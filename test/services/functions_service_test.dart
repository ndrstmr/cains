// test/services/functions_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:cains/services/functions_service.dart';
import 'package:cains/models/vocabulary_item.dart';

// Generate mocks for FirebaseAuth, User, and http.Client
@GenerateMocks([FirebaseAuth, User, http.Client])
import 'functions_service_test.mocks.dart';

void main() {
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
}
