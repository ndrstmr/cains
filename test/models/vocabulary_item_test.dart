// test/models/vocabulary_item_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:myapp/models/vocabulary_item.dart';

void main() {
  group('VocabularyItem', () {
    // Sample data for a VocabularyItem
    final Map<String, dynamic> sampleVocabularyData = {
      'word': 'Beispiel',
      'definitions': {'de': 'Ein Muster', 'en': 'An example', 'es': 'Un ejemplo'},
      'synonyms': ['Muster', 'Vorbild'],
      'collocations': ['ein Beispiel geben', 'als Beispiel dienen'],
      'exampleSentences': {
        'de': ['Das ist ein gutes Beispiel.'],
        'en': ['This is a good example.'],
        'es': ['Este es un buen ejemplo.']
      },
      'level': 'C1',
      'sourceType': 'predefined',
      'topicId': 'topic123',
    };

    // Sample VocabularyItem instance
    final sampleVocabularyItem = VocabularyItem(
      id: 'item001',
      word: 'Beispiel',
      definitions: {'de': 'Ein Muster', 'en': 'An example', 'es': 'Un ejemplo'},
      synonyms: ['Muster', 'Vorbild'],
      collocations: ['ein Beispiel geben', 'als Beispiel dienen'],
      exampleSentences: {
        'de': ['Das ist ein gutes Beispiel.'],
        'en': ['This is a good example.'],
        'es': ['Este es un buen ejemplo.']
      },
      level: 'C1',
      sourceType: SourceType.predefined,
      topicId: 'topic123',
    );

    test('fromFirestore creates a valid VocabularyItem from DocumentSnapshot', () async {
      // Use FakeCloudFirestore for testing Firestore interactions
      final firestore = FakeFirebaseFirestore();
      final docRef = firestore.collection('vocabulary').doc('item001');
      await docRef.set(sampleVocabularyData);

      final snapshot = await docRef.get();
      final item = VocabularyItem.fromFirestore(snapshot);

      expect(item.id, 'item001');
      expect(item.word, sampleVocabularyData['word']);
      expect(item.definitions, sampleVocabularyData['definitions']);
      expect(item.synonyms, sampleVocabularyData['synonyms']);
      expect(item.collocations, sampleVocabularyData['collocations']);
      expect(item.exampleSentences, sampleVocabularyData['exampleSentences']);
      expect(item.level, sampleVocabularyData['level']);
      expect(item.sourceType.toString().split('.').last, sampleVocabularyData['sourceType']);
      expect(item.topicId, sampleVocabularyData['topicId']);
    });

    test('fromFirestore handles missing optional fields with defaults', () async {
      final firestore = FakeFirebaseFirestore();
      final Map<String, dynamic> dataWithMissingOptional = {
        'word': 'TestWort',
        'definitions': {'en': 'Test word'},
        'synonyms': [],
        'collocations': [],
        'exampleSentences': {'en': ['A test sentence.']},
        // 'level' is missing
        'sourceType': 'ai_added',
        'topicId': 'topic456',
      };
      final docRef = firestore.collection('vocabulary').doc('item002');
      await docRef.set(dataWithMissingOptional);
      final snapshot = await docRef.get();
      final item = VocabularyItem.fromFirestore(snapshot);

      expect(item.level, 'C1'); // Should default to C1
      expect(item.sourceType, SourceType.ai_added);
    });

     test('fromFirestore handles invalid sourceType with default', () async {
      final firestore = FakeFirebaseFirestore();
      final Map<String, dynamic> dataWithInvalidSource = {
        'word': 'TestWort',
        'definitions': {'en': 'Test word'},
        'synonyms': [],
        'collocations': [],
        'exampleSentences': {'en': ['A test sentence.']},
        'level': 'B2',
        'sourceType': 'invalid_source_type', // Invalid enum string
        'topicId': 'topic789',
      };
      final docRef = firestore.collection('vocabulary').doc('item003');
      await docRef.set(dataWithInvalidSource);
      final snapshot = await docRef.get();
      final item = VocabularyItem.fromFirestore(snapshot);

      expect(item.sourceType, SourceType.predefined); // Should default
    });


    test('toFirestore converts VocabularyItem to a valid Map', () {
      final firestoreMap = sampleVocabularyItem.toFirestore();

      // Note: 'id' is not part of toFirestore as it's the document ID
      expect(firestoreMap['word'], sampleVocabularyItem.word);
      expect(firestoreMap['definitions'], sampleVocabularyItem.definitions);
      expect(firestoreMap['synonyms'], sampleVocabularyItem.synonyms);
      expect(firestoreMap['collocations'], sampleVocabularyItem.collocations);
      expect(firestoreMap['exampleSentences'], sampleVocabularyItem.exampleSentences);
      expect(firestoreMap['level'], sampleVocabularyItem.level);
      expect(firestoreMap['sourceType'], sampleVocabularyItem.sourceType.toString().split('.').last);
      expect(firestoreMap['topicId'], sampleVocabularyItem.topicId);
    });

    test('VocabularyItem equality and hashCode', () {
      final item1 = VocabularyItem(
        id: 'id1', word: 'word1', definitions: {'en': 'def1'}, synonyms: [], collocations: [],
        exampleSentences: {}, level: 'C1', sourceType: SourceType.predefined, topicId: 'topic1'
      );
      final item2 = VocabularyItem(
        id: 'id1', word: 'word1', definitions: {'en': 'def1'}, synonyms: [], collocations: [],
        exampleSentences: {}, level: 'C1', sourceType: SourceType.predefined, topicId: 'topic1'
      );
      // These are not equal because they are different instances without an overridden ==/hashCode.
      // If value equality is needed, one would typically override == and hashCode,
      // or use a package like `equatable`. For this model, instance identity is usually sufficient
      // as objects from Firestore will be different instances unless cached/managed explicitly.
      // This test primarily serves as a reminder.
      // For the purpose of this test, we'll just check they are not the same instance,
      // but if they were from a list, they'd be different.
      expect(item1 == item2, isFalse); // This is expected without == override.

      // If we were to test `toFirestore` maps from identical items (excluding ID):
      final map1 = item1.toFirestore();
      final item1FromMap = VocabularyItem.fromFirestore(
        FakeDocumentSnapshot(
          id: 'id1',
          data: map1,
          reference: FakeFirebaseFirestore().collection('vocabulary').doc('id1'),
        )
      );
      // item1FromMap and item1 will still be different instances.
      // What matters is that the data content is the same.
      expect(item1FromMap.word, item1.word);
    });
  });
}

// Helper class for creating a fake DocumentSnapshot for tests not involving FakeFirebaseFirestore directly
class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic>? _data;
  @override
  final DocumentReference<Map<String, dynamic>> reference;

  FakeDocumentSnapshot({required this.id, Map<String, dynamic>? data, required this.reference}) : _data = data;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  bool get exists => _data != null;

  @override
  dynamic get(Object field) {
    if (_data == null) {
      throw StateError('Document does not exist or has no data.');
    }
    if (field is String && _data.containsKey(field)) {
      return _data[field];
    }
    if (field is FieldPath && _data.containsKey(field.toString())) {
       // Basic support for FieldPath, might need more complex logic for nested paths
      return _data[field.toString()];
    }
    throw StateError('Field "$field" does not exist in the document.');
  }

  @override
  dynamic operator [](Object field) => get(field);


  @override
  SnapshotMetadata get metadata => const SnapshotMetadata(hasPendingWrites: false, isFromCache: false);
}
