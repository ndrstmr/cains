// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:myapp/models/topic_model.dart'; // Import the Topic model

/// A service to interact with Cloud Firestore.
class FirestoreService {
  final FirebaseFirestore _firestore;

  /// Creates a [FirestoreService] instance.
  /// Requires a [FirebaseFirestore] instance. Consider passing FirebaseFirestore.instance.
  FirestoreService(this._firestore);

  // Collection reference for topics
  CollectionReference<Topic> get _topicsRef => _firestore
      .collection('topics')
      .withConverter<Topic>(
        fromFirestore: (snapshot, _) => Topic.fromFirestore(snapshot),
        toFirestore: (topic, _) => topic.toFirestore(),
      );

  /// Streams a list of [Topic]s from the 'topics' collection.
  Stream<List<Topic>> getTopicsStream() {
    return _topicsRef
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        })
        .handleError((error) {
          if (kDebugMode) {
            print('Error fetching topics stream: $error');
          }
          // Depending on how you want to handle errors, you might rethrow,
          // or return an empty list, or a stream with an error.
          // For now, just print and let the stream emit the error.
          return Stream.error(error); // Or return const [];
        });
  }

  /// Adds a predefined list of dummy topics to the 'topics' collection in Firestore
  /// if the collection is currently empty.
  Future<void> addDummyTopics() async {
    if (kDebugMode) {
      print('FirestoreService: Checking if dummy topics need to be added.');
    }

    try {
      // Check if the topics collection is empty
      final snapshot = await _topicsRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        if (kDebugMode) {
          print(
            'FirestoreService: Topics collection is not empty. No dummy topics added.',
          );
        }
        return; // Topics already exist
      }

      if (kDebugMode) {
        print(
          'FirestoreService: Topics collection is empty. Adding dummy topics.',
        );
      }

      const List<Topic> dummyTopics = [
        // Made the list const
        const Topic(
          // Made Topic instance const
          id: '', // Firestore will generate ID
          titleDe: 'Wirtschaft & Finanzen',
          titleEn: 'Business & Economy',
          titleEs: 'Negocios y Economía',
          descriptionDe:
              'Grundlagen der Wirtschaft und Finanzmärkte verstehen.',
          descriptionEn:
              'Understand the basics of economy and financial markets.',
          descriptionEs:
              'Comprender los conceptos básicos de la economía y los mercados financieros.',
          iconName: 'business', // Corresponds to Icons.business
        ),
        const Topic(
          // Made Topic instance const
          id: '',
          titleDe: 'Wissenschaft & Technik',
          titleEn: 'Science & Technology',
          titleEs: 'Ciencia y Tecnología',
          descriptionDe:
              'Entdeckungen und Innovationen in Wissenschaft und Technik.',
          descriptionEn:
              'Discoveries and innovations in science and technology.',
          descriptionEs:
              'Descubrimientos e innovaciones en ciencia y tecnología.',
          iconName: 'science', // Corresponds to Icons.science
        ),
        const Topic(
          // Made Topic instance const
          id: '',
          titleDe: 'Kunst & Kultur',
          titleEn: 'Art & Culture',
          titleEs: 'Arte y Cultura',
          descriptionDe:
              'Erkunde verschiedene Kunstformen und kulturelle Aspekte.',
          descriptionEn: 'Explore various art forms and cultural aspects.',
          descriptionEs:
              'Explora diversas formas de arte y aspectos culturales.',
          iconName: 'palette', // Corresponds to Icons.palette
        ),
        const Topic(
          // Made Topic instance const
          id: '',
          titleDe: 'Alltag & Gesellschaft',
          titleEn: 'Daily Life & Society',
          titleEs: 'Vida Cotidiana y Sociedad',
          descriptionDe:
              'Themen rund um das tägliche Leben und gesellschaftliche Strukturen.',
          descriptionEn: 'Topics about daily life and societal structures.',
          descriptionEs:
              'Temas sobre la vida diaria y las estructuras sociales.',
          iconName: 'people', // Corresponds to Icons.people
        ),
        // Add a 5th topic if desired
        const Topic(
          // Made Topic instance const
          id: '',
          titleDe: 'Umwelt & Natur',
          titleEn: 'Environment & Nature',
          titleEs: 'Medio Ambiente y Naturaleza',
          descriptionDe:
              'Diskussionen über ökologische Herausforderungen und die Natur.',
          descriptionEn: 'Discussions about ecological challenges and nature.',
          descriptionEs: 'Debates sobre desafíos ecológicos y la naturaleza.',
          iconName: 'eco', // Corresponds to Icons.eco or Icons.nature
        ),
      ];

      // Use a batch write for atomicity if adding multiple documents
      final batch = _firestore.batch();
      for (final topic in dummyTopics) {
        // Firestore generates the ID when DocumentReference is not specified or is empty.
        // We pass an empty ID to Topic constructor, but it's not used in toFirestore().
        // The document ID will be auto-generated by Firestore.
        final newDocRef = _topicsRef.doc(); // Auto-generate ID
        batch.set(newDocRef, topic);
      }
      await batch.commit();

      if (kDebugMode) {
        print(
          'FirestoreService: Successfully added ${dummyTopics.length} dummy topics.',
        );
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print(
          'FirestoreService: FirebaseException while adding dummy topics: ${e.code} - ${e.message}',
        );
      }
      // Rethrow or handle as needed
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print(
          'FirestoreService: Generic exception while adding dummy topics: $e',
        );
      }
      rethrow;
    }
  }

  // --- Existing placeholder methods from Iteration 1 ---
  // (Keep them or remove if they are not relevant to this service's scope anymore)

  /// Placeholder for adding a vocabulary item.
  Future<void> addVocabularyItem(Map<String, dynamic> itemData) async {
    // TODO: Implement actual logic to add data to Firestore
    if (kDebugMode) {
      print('FirestoreService: Attempting to add vocabulary item: $itemData');
    }
    await Future.delayed(
      const Duration(seconds: 1),
    ); // Simulate network request
  }

  /// Placeholder for getting vocabulary items.
  Stream<QuerySnapshot> getVocabularyItems() {
    // TODO: Implement actual logic to stream data from Firestore
    if (kDebugMode) {
      print('FirestoreService: Attempting to get vocabulary items');
    }
    return Stream.empty(); // Placeholder
  }

  /// Placeholder for updating user progress.
  Future<void> updateUserProgress(
    String userId,
    Map<String, dynamic> progressData,
  ) async {
    // TODO: Implement actual logic to update user data in Firestore
    if (kDebugMode) {
      print(
        'FirestoreService: Attempting to update user progress for $userId: $progressData',
      );
    }
    await Future.delayed(
      const Duration(seconds: 1),
    ); // Simulate network request
  }
}
