// test/models/user_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_mocks/cloud_firestore_mocks.dart';
import 'package:myapp/models/user_model.dart';

void main() {
  group('UserModel', () {
    final Timestamp testTimestamp = Timestamp.fromDate(DateTime(2023, 1, 15, 10, 30));
    const String testUserId = 'test_user_123';

    // Helper to create a valid UserModel instance with all fields
    UserModel createTestUserModel({
      String uid = testUserId,
      String? email = 'test@example.com',
      String? displayName = 'Test User',
      int totalPoints = 100,
      int wordsFoundCount = 10,
      Map<String, Map<String, dynamic>>? topicProgress,
      Map<String, String>? dailyChallengeCompletion,
    }) {
      return UserModel(
        uid: uid,
        email: email,
        displayName: displayName,
        totalPoints: totalPoints,
        wordsFoundCount: wordsFoundCount,
        topicProgress: topicProgress ??
            {
              'topic1': {
                'completedPuzzles': 1,
                'totalWordsFoundInTopic': 5,
                'lastPlayed': testTimestamp,
              },
            },
        dailyChallengeCompletion: dailyChallengeCompletion ??
            {
              '2023-01-15': 'challengeId1',
            },
      );
    }

    // Helper to create a Map representation similar to what Firestore would store/return
    Map<String, dynamic> createFirestoreDataMap({
      String uid = testUserId,
      String? email = 'test@example.com',
      String? displayName = 'Test User',
      int totalPoints = 100,
      int wordsFoundCount = 10,
      Map<String, Map<String, dynamic>>? topicProgress,
      Map<String, String>? dailyChallengeCompletion,
    }) {
      return {
        'uid': uid,
        if (email != null) 'email': email,
        if (displayName != null) 'displayName': displayName,
        'totalPoints': totalPoints,
        'wordsFoundCount': wordsFoundCount,
        'topicProgress': topicProgress ??
            {
              'topic1': {
                'completedPuzzles': 1,
                'totalWordsFoundInTopic': 5,
                'lastPlayed': testTimestamp, // Firestore Timestamps are handled directly
              },
            },
        'dailyChallengeCompletion': dailyChallengeCompletion ??
            {
              '2023-01-15': 'challengeId1',
            },
      };
    }

    test('toFirestore correctly serializes UserModel', () {
      final userModel = createTestUserModel();
      final firestoreData = userModel.toFirestore();
      final expectedData = createFirestoreDataMap();

      expect(firestoreData, equals(expectedData));
    });

    test('toFirestore handles null optional fields', () {
      final userModel = createTestUserModel(email: null, displayName: null);
      final firestoreData = userModel.toFirestore();

      expect(firestoreData['email'], isNull);
      expect(firestoreData['displayName'], isNull);
      // Ensure other fields are still present
      expect(firestoreData['uid'], testUserId);
      expect(firestoreData['totalPoints'], 100);
    });

    test('fromFirestore correctly deserializes data to UserModel', () async {
      final firestoreData = createFirestoreDataMap();
      // Use MockFirestoreInstance to create a DocumentSnapshot
      final instance = MockFirestoreInstance();
      await instance.collection('users').doc(testUserId).set(firestoreData);
      final snapshot = await instance.collection('users').doc(testUserId).get();

      final userModel = UserModel.fromFirestore(snapshot);

      expect(userModel.uid, testUserId);
      expect(userModel.email, 'test@example.com');
      expect(userModel.displayName, 'Test User');
      expect(userModel.totalPoints, 100);
      expect(userModel.wordsFoundCount, 10);
      expect(userModel.topicProgress['topic1']?['completedPuzzles'], 1);
      expect(userModel.topicProgress['topic1']?['totalWordsFoundInTopic'], 5);
      expect(userModel.topicProgress['topic1']?['lastPlayed'], testTimestamp);
      expect(userModel.dailyChallengeCompletion['2023-01-15'], 'challengeId1');
    });

    test('fromFirestore handles missing optional fields with defaults', () async {
       final firestoreData = {
        'uid': testUserId,
        // email and displayName are missing
        'totalPoints': 50,
        // wordsFoundCount is missing
        // topicProgress is missing
        // dailyChallengeCompletion is missing
      };
      final instance = MockFirestoreInstance();
      await instance.collection('users').doc(testUserId).set(firestoreData);
      final snapshot = await instance.collection('users').doc(testUserId).get();
      final userModel = UserModel.fromFirestore(snapshot);

      expect(userModel.uid, testUserId);
      expect(userModel.email, isNull);
      expect(userModel.displayName, isNull);
      expect(userModel.totalPoints, 50);
      expect(userModel.wordsFoundCount, 0); // Default value
      expect(userModel.topicProgress, isEmpty); // Default value
      expect(userModel.dailyChallengeCompletion, isEmpty); // Default value
    });

    test('fromFirestore handles topicProgress with non-Timestamp lastPlayed (simulating bad data or old format)', () async {
      final firestoreDataWithSerializedTimestamp = createFirestoreDataMap(
        topicProgress: {
          'topicBadTimestamp': {
            'completedPuzzles': 2,
            'totalWordsFoundInTopic': 8,
            // Simulating Timestamp being stored as a map (e.g., from a manual JSON import)
            'lastPlayed': {'_seconds': testTimestamp.seconds, '_nanoseconds': testTimestamp.nanoseconds},
          },
        },
      );
      final instance = MockFirestoreInstance();
      await instance.collection('users').doc(testUserId).set(firestoreDataWithSerializedTimestamp);
      final snapshot = await instance.collection('users').doc(testUserId).get();
      final userModel = UserModel.fromFirestore(snapshot);

      expect(userModel.topicProgress['topicBadTimestamp']?['lastPlayed'], isA<Timestamp>());
      expect(userModel.topicProgress['topicBadTimestamp']?['lastPlayed'].seconds, testTimestamp.seconds);
    });


    test('copyWith creates a new instance with updated values', () {
      final originalUser = createTestUserModel();
      final updatedTimestamp = Timestamp.now();

      final updatedUser = originalUser.copyWith(
        displayName: 'Updated Name',
        totalPoints: 150,
        topicProgress: {
          'topic2': {
            'completedPuzzles': 1,
            'totalWordsFoundInTopic': 3,
            'lastPlayed': updatedTimestamp,
          }
        },
      );

      expect(updatedUser.uid, originalUser.uid); // UID should be the same unless explicitly changed
      expect(updatedUser.email, originalUser.email);
      expect(updatedUser.displayName, 'Updated Name');
      expect(updatedUser.totalPoints, 150);
      expect(updatedUser.wordsFoundCount, originalUser.wordsFoundCount);
      expect(updatedUser.topicProgress.containsKey('topic1'), isFalse); // Old topicProgress should be replaced
      expect(updatedUser.topicProgress['topic2']?['lastPlayed'], updatedTimestamp);
      expect(updatedUser.dailyChallengeCompletion, originalUser.dailyChallengeCompletion);
    });

    test('copyWith with no arguments returns an identical instance (new object)', () {
      final originalUser = createTestUserModel();
      final copiedUser = originalUser.copyWith();

      expect(copiedUser, isNot(same(originalUser))); // Different objects
      expect(copiedUser.uid, originalUser.uid);
      expect(copiedUser.email, originalUser.email);
      expect(copiedUser.displayName, originalUser.displayName);
      expect(copiedUser.totalPoints, originalUser.totalPoints);
      expect(copiedUser.wordsFoundCount, originalUser.wordsFoundCount);
      expect(copiedUser.topicProgress, originalUser.topicProgress);
      expect(copiedUser.dailyChallengeCompletion, originalUser.dailyChallengeCompletion);
    });
  });
}
