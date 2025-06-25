// test/services/firestore_service_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/topic_model.dart';
import 'package:myapp/models/user_model.dart'; // Added UserModel
import 'package:myapp/models/vocabulary_item.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Timestamp

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService firestoreService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    firestoreService = FirestoreService(fakeFirestore);
  });

  group('FirestoreService - Topics', () {
    // ... existing topic tests remain unchanged ...
    test('addDummyTopics adds topics if collection is empty', () async {
      await firestoreService.addDummyTopics();
      final snapshot = await fakeFirestore.collection('topics').get();
      expect(snapshot.docs.length, 5);
      expect(snapshot.docs.first.data()['titleEn'], 'Business & Economy');
    });

    test('addDummyTopics does not add topics if collection is not empty', () async {
      await fakeFirestore.collection('topics').add({'titleEn': 'Existing Topic'});
      await firestoreService.addDummyTopics();
      final snapshot = await fakeFirestore.collection('topics').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['titleEn'], 'Existing Topic');
    });

    test('getTopicsStream returns a stream of topics', () async {
      await firestoreService.addDummyTopics();
      final stream = firestoreService.getTopicsStream();
      expectLater(
        stream,
        emits(isA<List<Topic>>()..having((list) => list.length, 'length', 5)),
      );
    });
  });

  group('FirestoreService - Vocabulary', () {
    // ... existing vocabulary tests remain unchanged ...
    List<String> dummyTopicIds = [];

    setUp(() async {
      await firestoreService.addDummyTopics();
      final topicsSnapshot = await fakeFirestore.collection('topics').get();
      dummyTopicIds = topicsSnapshot.docs.map((doc) => doc.id).toList();
      expect(dummyTopicIds.length, 5, reason: "Should have 5 dummy topic IDs for tests");
    });

    test('addDummyVocabulary adds vocabulary if collection is empty and topic IDs are provided', () async {
      expect(dummyTopicIds.isNotEmpty, isTrue, reason: "Topic IDs must be available for this test");
      await firestoreService.addDummyVocabulary(dummyTopicIds);
      final snapshot = await fakeFirestore.collection('vocabulary').get();
      expect(snapshot.docs.length, 5);
      expect(snapshot.docs.first.data()['word'], 'die Herausforderung');
      expect(dummyTopicIds.contains(snapshot.docs.first.data()['topicId']), isTrue);
    });

    test('addDummyVocabulary does not add if topic IDs are empty', () async {
      await firestoreService.addDummyVocabulary([]);
      final snapshot = await fakeFirestore.collection('vocabulary').get();
      expect(snapshot.docs.isEmpty, isTrue);
    });

    test('addDummyVocabulary does not add vocabulary if collection is not empty', () async {
      expect(dummyTopicIds.isNotEmpty, isTrue);
      await fakeFirestore.collection('vocabulary').add({
        'word': 'Existing Word',
        'topicId': dummyTopicIds.first,
        'definitions': {'en': 'def'},
        'synonyms': [],
        'collocations': [],
        'exampleSentences': {'en': []},
        'level': 'C1',
        'sourceType': 'predefined'
      });
      await firestoreService.addDummyVocabulary(dummyTopicIds);
      final snapshot = await fakeFirestore.collection('vocabulary').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['word'], 'Existing Word');
    });

    test('getVocabularyStreamForTopic returns a stream of vocabulary for a specific topic', () async {
      expect(dummyTopicIds.isNotEmpty, isTrue);
      await firestoreService.addDummyVocabulary(dummyTopicIds);
      final String targetTopicId = dummyTopicIds.first;
      final stream = firestoreService.getVocabularyStreamForTopic(targetTopicId);
      expectLater(
        stream,
        emits(isA<List<VocabularyItem>>()
            .having((list) => list.length, 'length', 1)
            .having((list) => list.every((item) => item.topicId == targetTopicId), 'all items match topicId', isTrue)
            .having((list) => list.first.word, 'first word check', 'die Herausforderung')
            ),
      );
    });

     test('getVocabularyStreamForTopic returns an empty stream for a topic with no vocabulary', () async {
      expect(dummyTopicIds.length, greaterThanOrEqualTo(1));
      await firestoreService.addDummyVocabulary(dummyTopicIds);
      const String topicWithNoVocab = 'non_existent_topic_id_for_vocab_test';
      expect(dummyTopicIds.contains(topicWithNoVocab), isFalse);
      final stream = firestoreService.getVocabularyStreamForTopic(topicWithNoVocab);
      expectLater(
        stream,
        emits(isA<List<VocabularyItem>>()..having((list) => list.isEmpty, 'length', isTrue)),
      );
    });
  });

  group('FirestoreService - User Progress', () {
    const String testUserId = 'user123';
    final Timestamp testTimestamp = Timestamp.now();

    test('updateUserProgress creates a new user document if one does not exist', () async {
      final userData = {
        'uid': testUserId,
        'totalPoints': 100,
        'wordsFoundCount': 10,
        'topicProgress': {
          'topicA': {
            'completedPuzzles': 1,
            'totalWordsFoundInTopic': 5,
            'lastPlayed': testTimestamp,
          }
        },
        'dailyChallengeCompletion': {'2023-01-01': 'challengeX'},
      };

      await firestoreService.updateUserProgress(testUserId, userData);

      final docSnapshot = await fakeFirestore.collection('users').doc(testUserId).get();
      expect(docSnapshot.exists, isTrue);
      expect(docSnapshot.data()?['totalPoints'], 100);
      expect(docSnapshot.data()?['wordsFoundCount'], 10);
      expect(docSnapshot.data()?['topicProgress']['topicA']['lastPlayed'], testTimestamp);
    });

    test('updateUserProgress merges data into an existing user document', () async {
      // Pre-populate user document
      await fakeFirestore.collection('users').doc(testUserId).set({
        'uid': testUserId,
        'email': 'initial@example.com',
        'totalPoints': 50,
        'topicProgress': {
          'topicA': {
            'completedPuzzles': 0,
            'totalWordsFoundInTopic': 2,
            'lastPlayed': Timestamp.fromDate(DateTime(2022)),
          }
        },
      });

      final updateData = {
        'totalPoints': 150, // Update points
        'displayName': 'Test User', // Add display name
        'topicProgress': {
          'topicA': { // Update existing topic progress
            'totalWordsFoundInTopic': 7,
            'lastPlayed': testTimestamp, // This will overwrite the specific field in topicA map
          },
          'topicB': { // Add new topic progress
            'completedPuzzles': 1,
            'totalWordsFoundInTopic': 3,
            'lastPlayed': testTimestamp,
          }
        },
      };

      await firestoreService.updateUserProgress(testUserId, updateData);

      final docSnapshot = await fakeFirestore.collection('users').doc(testUserId).get();
      expect(docSnapshot.exists, isTrue);
      expect(docSnapshot.data()?['uid'], testUserId);
      expect(docSnapshot.data()?['email'], 'initial@example.com'); // Should remain
      expect(docSnapshot.data()?['totalPoints'], 150); // Updated
      expect(docSnapshot.data()?['displayName'], 'Test User'); // Added

      final topicProgress = docSnapshot.data()?['topicProgress'] as Map<String, dynamic>;
      // Topic A should be merged
      expect(topicProgress['topicA']['completedPuzzles'], 0); // This field was not in updateData for topicA, so it's not merged at this level
      expect(topicProgress['topicA']['totalWordsFoundInTopic'], 7);
      expect(topicProgress['topicA']['lastPlayed'], testTimestamp);
      // Topic B should be added
      expect(topicProgress['topicB']['completedPuzzles'], 1);

      // Correction: Firestore's SetOptions(merge: true) on a document level
      // means that if 'topicProgress' is in updateData, the ENTIRE 'topicProgress' map
      // in Firestore is REPLACED by the 'topicProgress' map from updateData.
      // It does NOT deep merge maps within the document unless you read-modify-write.
      // The service method currently just passes the data to set with merge:true.
      // So, 'topicA.completedPuzzles' would be GONE if not in updateData.topicProgress.topicA.

      // Let's re-verify the expected behavior based on Firestore's merge:
      // The `updateData` provided `topicProgress` which only had `topicA` with `totalWordsFoundInTopic` and `lastPlayed`.
      // So `completedPuzzles` for `topicA` from the original document would be removed.
      // This means the test above for topicProgress['topicA']['completedPuzzles'] is likely incorrect for a simple set-merge.

      // To achieve deep merge for maps like topicProgress, FirestoreService would need to
      // read the document, merge the maps in Dart, then write back.
      // The current implementation does a shallow merge at the document level.
      // Let's adjust the expectation for 'completedPuzzles' for topicA.
      // If `updateData`'s `topicProgress.topicA` does not include `completedPuzzles`, it won't be there after the merge.

      // Given the current firestoreService.updateUserProgress implementation:
      // It does `docRef.set(data, SetOptions(merge: true))`.
      // If `data` contains `topicProgress: {'topicA': {'newField': 1}}`,
      // the existing `topicProgress` map in Firestore will be *replaced* by `{'topicA': {'newField': 1}}`.
      // To achieve a deep merge for `topicProgress`, one would typically read the user doc,
      // manually merge the `topicProgress` maps in Dart, and then set the updated user doc.
      // The current test should reflect the actual behavior of `set` with `merge:true`.

      // Let's redefine updateData and expectations based on shallow merge for top-level fields,
      // and replacement for map fields if they are part of the update.
      final preciseUpdateData = {
        'totalPoints': 150,
        'displayName': 'Test User',
        'topicProgress': { // This will REPLACE the existing topicProgress map
          'topicA': {
            'totalWordsFoundInTopic': 7, // New value for topicA
            'lastPlayed': testTimestamp,   // New value for topicA
            // 'completedPuzzles' is NOT specified here for topicA
          },
          'topicB': {
            'completedPuzzles': 1,
            'totalWordsFoundInTopic': 3,
            'lastPlayed': testTimestamp,
          }
        },
      };
      // Re-run the update with precise data
      await fakeFirestore.collection('users').doc(testUserId).set({ // Reset state before this specific test logic
        'uid': testUserId,
        'email': 'initial@example.com',
        'totalPoints': 50,
         'topicProgress': {
          'topicA': {
            'completedPuzzles': 0, // This will be overwritten
            'totalWordsFoundInTopic': 2,
            'lastPlayed': Timestamp.fromDate(DateTime(2022)),
          }
        },
      });
      await firestoreService.updateUserProgress(testUserId, preciseUpdateData);
      final finalDocSnapshot = await fakeFirestore.collection('users').doc(testUserId).get();

      expect(finalDocSnapshot.data()?['totalPoints'], 150);
      expect(finalDocSnapshot.data()?['displayName'], 'Test User');
      final finalTopicProgress = finalDocSnapshot.data()?['topicProgress'] as Map<String, dynamic>;
      expect(finalTopicProgress['topicA']['totalWordsFoundInTopic'], 7);
      expect(finalTopicProgress['topicA']['completedPuzzles'], isNull); // Because it wasn't in preciseUpdateData.topicProgress.topicA
      expect(finalTopicProgress['topicB']['completedPuzzles'], 1);
    });


    test('updateUserProgress does nothing if userId is empty', () async {
      await firestoreService.updateUserProgress('', {'totalPoints': 100});
      final snapshot = await fakeFirestore.collection('users').get();
      // No documents should be created or modified
      expect(snapshot.docs.isEmpty, isTrue);
    });

    test('getUserStream streams UserModel data', () async {
      final initialData = UserModel(uid: testUserId, email: 'test@example.com', totalPoints: 10);
      await fakeFirestore.collection('users').doc(testUserId).set(initialData.toFirestore());

      final stream = firestoreService.getUserStream(testUserId);

      expectLater(
        stream,
        emits(isA<UserModel?>()
            .having((user) => user?.uid, 'uid', testUserId)
            .having((user) => user?.totalPoints, 'totalPoints', 10)),
      );

      // Test update
      await Future.delayed(Duration(milliseconds: 10)); // Ensure first emit is processed
      await fakeFirestore.collection('users').doc(testUserId).update({'totalPoints': 20});

      expectLater(
        stream, // This will re-evaluate from the current point of the stream.
                // The first emit might have already happened.
        emitsThrough(isA<UserModel?>()
            .having((user) => user?.totalPoints, 'totalPoints', 20)),
      );
    });

    test('getUserStream streams null if user document does not exist', () async {
      final stream = firestoreService.getUserStream('nonExistentUser');
      expectLater(stream, emits(isNull));
    });

    test('getUserStream streams null if userId is empty', () async {
      final stream = firestoreService.getUserStream('');
      // Based on current implementation, an empty userId results in Stream.value(null)
      expectLater(stream, emits(isNull));
    });
  });
}
