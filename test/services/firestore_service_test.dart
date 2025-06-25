// test/services/firestore_service_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/topic_model.dart';
import 'package:myapp/models/vocabulary_item.dart';
import 'package:myapp/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService firestoreService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    firestoreService = FirestoreService(fakeFirestore);
  });

  group('FirestoreService - Topics', () {
    test('addDummyTopics adds topics if collection is empty', () async {
      await firestoreService.addDummyTopics();
      final snapshot = await fakeFirestore.collection('topics').get();
      // Expect 5 dummy topics as defined in FirestoreService
      expect(snapshot.docs.length, 5);
      expect(snapshot.docs.first.data()['titleEn'], 'Business & Economy');
    });

    test('addDummyTopics does not add topics if collection is not empty', () async {
      // Pre-add a topic
      await fakeFirestore.collection('topics').add({'titleEn': 'Existing Topic'});
      await firestoreService.addDummyTopics();
      final snapshot = await fakeFirestore.collection('topics').get();
      // Should still be 1, not 1 + 5
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['titleEn'], 'Existing Topic');
    });

    test('getTopicsStream returns a stream of topics', () async {
      await firestoreService.addDummyTopics(); // Add some data

      final stream = firestoreService.getTopicsStream();

      expectLater(
        stream,
        emits(isA<List<Topic>>()..having((list) => list.length, 'length', 5)),
      );
    });
  });

  group('FirestoreService - Vocabulary', () {
    List<String> dummyTopicIds = [];

    setUp(() async {
      // Ensure dummy topics are added to get their IDs for vocabulary association
      await firestoreService.addDummyTopics();
      final topicsSnapshot = await fakeFirestore.collection('topics').get();
      dummyTopicIds = topicsSnapshot.docs.map((doc) => doc.id).toList();
      expect(dummyTopicIds.length, 5, reason: "Should have 5 dummy topic IDs for tests");
    });

    test('addDummyVocabulary adds vocabulary if collection is empty and topic IDs are provided', () async {
      expect(dummyTopicIds.isNotEmpty, isTrue, reason: "Topic IDs must be available for this test");

      await firestoreService.addDummyVocabulary(dummyTopicIds);
      final snapshot = await fakeFirestore.collection('vocabulary').get();
      // Expect 5 dummy vocabulary items as defined in FirestoreService
      expect(snapshot.docs.length, 5);
      expect(snapshot.docs.first.data()['word'], 'die Herausforderung');
      // Check if topicId is one of the dummyTopicIds
      expect(dummyTopicIds.contains(snapshot.docs.first.data()['topicId']), isTrue);
    });

    test('addDummyVocabulary does not add if topic IDs are empty', () async {
      await firestoreService.addDummyVocabulary([]); // Empty list of topic IDs
      final snapshot = await fakeFirestore.collection('vocabulary').get();
      expect(snapshot.docs.isEmpty, isTrue);
    });

    test('addDummyVocabulary does not add vocabulary if collection is not empty', () async {
      expect(dummyTopicIds.isNotEmpty, isTrue);
      // Pre-add a vocabulary item
      await fakeFirestore.collection('vocabulary').add({
        'word': 'Existing Word',
        'topicId': dummyTopicIds.first,
        // other required fields for VocabularyItem.fromFirestore to work if you were to convert
        'definitions': {'en': 'def'},
        'synonyms': [],
        'collocations': [],
        'exampleSentences': {'en': []},
        'level': 'C1',
        'sourceType': 'predefined'
      });

      await firestoreService.addDummyVocabulary(dummyTopicIds);
      final snapshot = await fakeFirestore.collection('vocabulary').get();
      // Should still be 1, not 1 + 5
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['word'], 'Existing Word');
    });

    test('getVocabularyStreamForTopic returns a stream of vocabulary for a specific topic', () async {
      expect(dummyTopicIds.isNotEmpty, isTrue);
      await firestoreService.addDummyVocabulary(dummyTopicIds); // Add some data

      // Get vocabulary for the first topic
      final String targetTopicId = dummyTopicIds.first;
      final stream = firestoreService.getVocabularyStreamForTopic(targetTopicId);

      // Expect a list of VocabularyItem, and all items should have the targetTopicId
      // The number of items depends on how many dummy vocabs were assigned to this specific topicId.
      // In the current addDummyVocabulary logic, each of the 5 vocabs gets a topicId via modulo.
      // So, each topicId gets exactly one vocabulary item.
      expectLater(
        stream,
        emits(isA<List<VocabularyItem>>()
            .having((list) => list.length, 'length', 1) // Each topic gets one of the 5 vocabs
            .having((list) => list.every((item) => item.topicId == targetTopicId), 'all items match topicId', isTrue)
            .having((list) => list.first.word, 'first word check', 'die Herausforderung') // Assuming this is the first vocab for the first topic
            ),
      );
    });

     test('getVocabularyStreamForTopic returns an empty stream for a topic with no vocabulary', () async {
      expect(dummyTopicIds.length, greaterThanOrEqualTo(1)); // Need at least one topic ID

      // Add dummy vocabulary but ensure none are for a specific, new topic ID
      await firestoreService.addDummyVocabulary(dummyTopicIds);

      const String topicWithNoVocab = 'non_existent_topic_id_for_vocab_test';
      // Ensure this ID is not among the dummyTopicIds used for seeding vocab
      expect(dummyTopicIds.contains(topicWithNoVocab), isFalse);


      final stream = firestoreService.getVocabularyStreamForTopic(topicWithNoVocab);

      expectLater(
        stream,
        emits(isA<List<VocabularyItem>>()..having((list) => list.isEmpty, 'length', isTrue)),
      );
    });
  });
}
