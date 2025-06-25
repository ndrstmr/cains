// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:myapp/models/topic_model.dart'; // Import the Topic model
import 'package:myapp/models/vocabulary_item.dart'; // Import the VocabularyItem model

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

  // Collection reference for vocabulary items
  CollectionReference<VocabularyItem> get _vocabularyRef => _firestore
      .collection('vocabulary')
      .withConverter<VocabularyItem>(
        fromFirestore: (snapshot, _) => VocabularyItem.fromFirestore(snapshot),
        toFirestore: (item, _) => item.toFirestore(),
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

  /// Adds a predefined list of dummy C1 vocabulary items to the 'vocabulary' collection
  /// in Firestore if the collection is currently empty.
  /// Associates vocabulary with existing dummy topic IDs.
  Future<void> addDummyVocabulary(List<String> topicIds) async {
    if (kDebugMode) {
      print('FirestoreService: Checking if dummy vocabulary needs to be added.');
    }

    if (topicIds.isEmpty) {
      if (kDebugMode) {
        print('FirestoreService: No topic IDs provided, cannot add dummy vocabulary.');
      }
      return;
    }

    try {
      // Check if the vocabulary collection is empty
      final snapshot = await _vocabularyRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        if (kDebugMode) {
          print('FirestoreService: Vocabulary collection is not empty. No dummy vocabulary added.');
        }
        return; // Vocabulary items already exist
      }

      if (kDebugMode) {
        print('FirestoreService: Vocabulary collection is empty. Adding dummy vocabulary.');
      }

      // Dummy C1 Vocabulary Items
      final List<VocabularyItem> dummyVocabulary = [
        VocabularyItem(
          id: '', // Firestore will generate ID
          word: 'die Herausforderung',
          definitions: {
            'de': 'Eine schwierige Aufgabe, die besonderen Einsatz erfordert.',
            'en': 'A difficult task that requires special effort.',
            'es': 'Una tarea difícil que requiere un esfuerzo especial.',
          },
          synonyms: ['die Schwierigkeit', 'das Problem', 'die Aufgabe'],
          collocations: ['eine Herausforderung annehmen', 'vor einer Herausforderung stehen'],
          exampleSentences: {
            'de': ['Das Projekt stellt eine große Herausforderung dar.', 'Sie meisterte die Herausforderung mit Bravour.'],
            'en': ['The project presents a major challenge.', 'She mastered the challenge with flying colors.'],
            'es': ['El proyecto presenta un gran desafío.', 'Superó el desafío con gran éxito.'],
          },
          level: 'C1',
          sourceType: SourceType.predefined,
          topicId: topicIds[0 % topicIds.length], // Assign to a topic
        ),
        VocabularyItem(
          id: '',
          word: 'nachhaltig',
          definitions: {
            'de': 'So, dass etwas für längere Zeit bestehen bleibt oder wirkt; umweltverträglich.',
            'en': 'Sustainable; in a way that something lasts or has an effect for a long time; environmentally friendly.',
            'es': 'Sostenible; de manera que algo dure o tenga efecto por mucho tiempo; respetuoso con el medio ambiente.',
          },
          synonyms: ['umweltfreundlich', 'zukunftsfähig', 'dauerhaft'],
          collocations: ['nachhaltige Entwicklung', 'nachhaltig wirtschaften'],
          exampleSentences: {
            'de': ['Wir müssen nachhaltiger leben, um die Umwelt zu schützen.', 'Das Unternehmen setzt auf nachhaltige Produktion.'],
            'en': ['We need to live more sustainably to protect the environment.', 'The company focuses on sustainable production.'],
            'es': ['Necesitamos vivir de forma más sostenible para proteger el medio ambiente.', 'La empresa apuesta por una producción sostenible.'],
          },
          level: 'C1',
          sourceType: SourceType.predefined,
          topicId: topicIds[1 % topicIds.length],
        ),
        VocabularyItem(
          id: '',
          word: 'die Voraussetzung',
          definitions: {
            'de': 'Eine Bedingung, die erfüllt sein muss, damit etwas anderes geschehen kann.',
            'en': 'A condition that must be met for something else to happen.',
            'es': 'Una condición que debe cumplirse para que suceda otra cosa.',
          },
          synonyms: ['die Bedingung', 'die Anforderung', 'das Erfordernis'],
          collocations: ['die Voraussetzungen erfüllen', 'unter der Voraussetzung, dass...'],
          exampleSentences: {
            'de': ['Gute Sprachkenntnisse sind eine Voraussetzung für diesen Job.', 'Er erfüllte alle Voraussetzungen für die Zulassung.'],
            'en': ['Good language skills are a prerequisite for this job.', 'He met all the requirements for admission.'],
            'es': ['Un buen conocimiento de idiomas es un requisito para este trabajo.', 'Cumplió todos los requisitos para la admisión.'],
          },
          level: 'C1',
          sourceType: SourceType.predefined,
          topicId: topicIds[2 % topicIds.length],
        ),
        VocabularyItem(
          id: '',
          word: 'umfangreich',
          definitions: {
            'de': 'Sehr groß in Bezug auf Menge, Ausmaß oder Inhalt.',
            'en': 'Very large in terms of quantity, extent, or content.',
            'es': 'Muy grande en términos de cantidad, extensión o contenido.',
          },
          synonyms: ['ausführlich', 'umfassend', 'weitläufig'],
          collocations: ['umfangreiche Kenntnisse', 'eine umfangreiche Sammlung'],
          exampleSentences: {
            'de': ['Die Bibliothek verfügt über eine umfangreiche Sammlung an Fachliteratur.', 'Er hat umfangreiche Erfahrungen in diesem Bereich.'],
            'en': ['The library has an extensive collection of specialized literature.', 'He has extensive experience in this field.'],
            'es': ['La biblioteca cuenta con una extensa colección de literatura especializada.', 'Tiene una amplia experiencia en este campo.'],
          },
          level: 'C1',
          sourceType: SourceType.predefined,
          topicId: topicIds[3 % topicIds.length],
        ),
        VocabularyItem(
          id: '',
          word: 'die Auswirkung',
          definitions: {
            'de': 'Die Folge oder Konsequenz einer Handlung oder eines Ereignisses.',
            'en': 'The consequence or result of an action or event.',
            'es': 'La consecuencia o resultado de una acción o evento.',
          },
          synonyms: ['die Folge', 'die Konsequenz', 'der Effekt', 'der Einfluss'],
          collocations: ['positive/negative Auswirkungen haben', 'die Auswirkungen untersuchen'],
          exampleSentences: {
            'de': ['Die neuen Maßnahmen hatten positive Auswirkungen auf die Wirtschaft.', 'Die Auswirkungen des Klimawandels sind bereits spürbar.'],
            'en': ['The new measures had positive effects on the economy.', 'The impacts of climate change are already noticeable.'],
            'es': ['Las nuevas medidas tuvieron efectos positivos en la economía.', 'Los impactos del cambio climático ya son notables.'],
          },
          level: 'C1',
          sourceType: SourceType.predefined,
          topicId: topicIds[4 % topicIds.length],
        ),
      ];

      final batch = _firestore.batch();
      for (final item in dummyVocabulary) {
        final newDocRef = _vocabularyRef.doc(); // Auto-generate ID
        batch.set(newDocRef, item);
      }
      await batch.commit();

      if (kDebugMode) {
        print('FirestoreService: Successfully added ${dummyVocabulary.length} dummy vocabulary items.');
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('FirestoreService: FirebaseException while adding dummy vocabulary: ${e.code} - ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('FirestoreService: Generic exception while adding dummy vocabulary: $e');
      }
      rethrow;
    }
  }

  /// Streams a list of [VocabularyItem]s for a specific topic from the 'vocabulary' collection.
  ///
  /// Filters items by [topicId].
  Stream<List<VocabularyItem>> getVocabularyStreamForTopic(String topicId) {
    if (kDebugMode) {
      print('FirestoreService: Getting vocabulary stream for topic ID: $topicId');
    }
    return _vocabularyRef
        .where('topicId', isEqualTo: topicId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        })
        .handleError((error) {
          if (kDebugMode) {
            print('Error fetching vocabulary stream for topic $topicId: $error');
          }
          return Stream.error(error);
        });
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
