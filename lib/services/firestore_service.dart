// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:myapp/models/topic_model.dart';
import 'package:myapp/models/vocabulary_item.dart';
import 'package:myapp/models/user_model.dart'; // Added UserModel
import 'package:myapp/models/challenge_model.dart'; // Added ChallengeModel

/// A service to interact with Cloud Firestore.
class FirestoreService {
  final FirebaseFirestore _firestore;

  /// Creates a [FirestoreService] instance.
  /// Requires a [FirebaseFirestore] instance. Consider passing FirebaseFirestore.instance.
  FirestoreService(this._firestore);

  // Collection reference for users
  CollectionReference<UserModel> _usersRef(String userId) => _firestore
      .collection('users')
      .withConverter<UserModel>(
        fromFirestore: (snapshot, _) => UserModel.fromFirestore(snapshot),
        toFirestore: (user, _) => user.toFirestore(),
      );

  // Collection reference for a user's daily challenges
  CollectionReference<ChallengeModel> _userDailyChallengesRef(String userId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_challenges')
          .withConverter<ChallengeModel>(
            fromFirestore: (snapshot, _) => ChallengeModel.fromJson(snapshot.data()!), // Assuming ChallengeModel.fromJson for now
            toFirestore: (challenge, _) => challenge.toJson(),
          );

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

  /// Streams the [UserModel] for a given [userId].
  Stream<UserModel?> getUserStream(String userId) {
    if (userId.isEmpty) {
      return Stream.value(null);
    }
    final docRef = _firestore.collection('users').doc(userId);
    return docRef.snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromFirestore(snapshot);
      }
      return null; // User document might not exist yet
    }).handleError((error) {
      if (kDebugMode) {
        print('Error fetching user stream for $userId: $error');
      }
      return Stream.error(error);
    });
  }

  /// Updates or creates user progress data in Firestore.
  ///
  /// Uses `SetOptions(merge: true)` to only update provided fields or create if not exists.
  Future<void> updateUserProgress(String userId, Map<String, dynamic> data) async {
    if (userId.isEmpty) {
      if (kDebugMode) {
        print('FirestoreService: updateUserProgress called with empty userId.');
      }
      return;
    }
    try {
      // It's good practice to ensure 'uid' is part of the data if creating a new user doc,
      // though merge:true handles partial updates well.
      // If `data` comes directly from `UserModel.toFirestore()`, `uid` will be there.
      await _firestore
          .collection('users')
          .doc(userId)
          .set(data, SetOptions(merge: true));
      if (kDebugMode) {
        print('FirestoreService: User progress updated for $userId with data: $data');
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('FirestoreService: FirebaseException while updating user progress for $userId: ${e.code} - ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('FirestoreService: Generic exception while updating user progress for $userId: $e');
      }
      rethrow;
    }
  }

  /// Streams a list of [ChallengeModel] for the user's daily challenges.
  Stream<List<ChallengeModel>> getDailyChallengesStream(String userId) {
    if (userId.isEmpty) {
      if (kDebugMode) {
        print('FirestoreService: getDailyChallengesStream called with empty userId.');
      }
      return Stream.value([]);
    }
    return _userDailyChallengesRef(userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        })
        .handleError((error) {
          if (kDebugMode) {
            print('Error fetching daily challenges stream for $userId: $error');
          }
          return Stream.error(error);
        });
  }

  /// Placeholder method to trigger the generation of a daily challenge via a Cloud Function.
  /// This will be more fleshed out when `functions_service.dart` is implemented.
  Future<ChallengeModel?> generateAndGetDailyChallenge(String userId) async {
    if (userId.isEmpty) {
      if (kDebugMode) {
        print('FirestoreService: generateAndGetDailyChallenge called with empty userId.');
      }
      return null;
    }
    // TODO: Implement call to FunctionsService which invokes the Cloud Function.
    // For now, this is a placeholder.
    // The Cloud Function should ideally return the generated challenge or confirm its creation.
    // This service might then fetch it or directly use the returned data.
    if (kDebugMode) {
      print('FirestoreService: Placeholder for calling generateDailyChallenge Cloud Function for user $userId.');
    }
    // Simulating a potential return or a re-fetch if the function only signals creation
    // For now, returning null as the actual call is not implemented.
    return null;
  }


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
          return Stream.error(error);
        });
  }

  /// Adds a predefined list of dummy topics to the 'topics' collection in Firestore
  /// if the collection is currently empty.
  Future<void> addDummyTopics() async {
    if (kDebugMode) {
      print('FirestoreService: Checking if dummy topics need to be added.');
    }

    try {
      final snapshot = await _topicsRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        if (kDebugMode) {
          print('FirestoreService: Topics collection is not empty. No dummy topics added.');
        }
        return;
      }

      if (kDebugMode) {
        print('FirestoreService: Topics collection is empty. Adding dummy topics.');
      }

      const List<Topic> dummyTopics = [
        Topic(
          id: '',
          titleDe: 'Wirtschaft & Finanzen',
          titleEn: 'Business & Economy',
          titleEs: 'Negocios y Economía',
          descriptionDe: 'Grundlagen der Wirtschaft und Finanzmärkte verstehen.',
          descriptionEn: 'Understand the basics of economy and financial markets.',
          descriptionEs: 'Comprender los conceptos básicos de la economía y los mercados financieros.',
          iconName: 'business',
        ),
        Topic(
          id: '',
          titleDe: 'Wissenschaft & Technik',
          titleEn: 'Science & Technology',
          titleEs: 'Ciencia y Tecnología',
          descriptionDe: 'Entdeckungen und Innovationen in Wissenschaft und Technik.',
          descriptionEn: 'Discoveries and innovations in science and technology.',
          descriptionEs: 'Descubrimientos e innovaciones en ciencia y tecnología.',
          iconName: 'science',
        ),
        Topic(
          id: '',
          titleDe: 'Kunst & Kultur',
          titleEn: 'Art & Culture',
          titleEs: 'Arte y Cultura',
          descriptionDe: 'Erkunde verschiedene Kunstformen und kulturelle Aspekte.',
          descriptionEn: 'Explore various art forms and cultural aspects.',
          descriptionEs: 'Explora diversas formas de arte y aspectos culturales.',
          iconName: 'palette',
        ),
        Topic(
          id: '',
          titleDe: 'Alltag & Gesellschaft',
          titleEn: 'Daily Life & Society',
          titleEs: 'Vida Cotidiana y Sociedad',
          descriptionDe: 'Themen rund um das tägliche Leben und gesellschaftliche Strukturen.',
          descriptionEn: 'Topics about daily life and societal structures.',
          descriptionEs: 'Temas sobre la vida diaria y las estructuras sociales.',
          iconName: 'people',
        ),
        Topic(
          id: '',
          titleDe: 'Umwelt & Natur',
          titleEn: 'Environment & Nature',
          titleEs: 'Medio Ambiente y Naturaleza',
          descriptionDe: 'Diskussionen über ökologische Herausforderungen und die Natur.',
          descriptionEn: 'Discussions about ecological challenges and nature.',
          descriptionEs: 'Debates sobre desafíos ecológicos y la naturaleza.',
          iconName: 'eco',
        ),
      ];

      final batch = _firestore.batch();
      for (final topic in dummyTopics) {
        final newDocRef = _topicsRef.doc();
        batch.set(newDocRef, topic);
      }
      await batch.commit();

      if (kDebugMode) {
        print('FirestoreService: Successfully added ${dummyTopics.length} dummy topics.');
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('FirestoreService: FirebaseException while adding dummy topics: ${e.code} - ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('FirestoreService: Generic exception while adding dummy topics: $e');
      }
      rethrow;
    }
  }

  /// Adds a predefined list of dummy C1 vocabulary items to the 'vocabulary' collection
  /// in Firestore if the collection is currently empty.
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
      final snapshot = await _vocabularyRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        if (kDebugMode) {
          print('FirestoreService: Vocabulary collection is not empty. No dummy vocabulary added.');
        }
        return;
      }

      if (kDebugMode) {
        print('FirestoreService: Vocabulary collection is empty. Adding dummy vocabulary.');
      }

      final List<VocabularyItem> dummyVocabulary = [
        VocabularyItem(
          id: '',
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
          topicId: topicIds[0 % topicIds.length],
        ),
        // ... (other vocabulary items kept for brevity but would be here)
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
          topicId: topicIds[4 % topicIds.length], // Assuming 5 topics
        ),
      ];

      final batch = _firestore.batch();
      for (final item in dummyVocabulary) {
        final newDocRef = _vocabularyRef.doc();
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

  /// Streams a list of [VocabularyItem]s for a specific topic.
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

  // --- Removed old placeholder methods for addVocabularyItem and getVocabularyItems ---
  // as they are now properly implemented with _vocabularyRef or are not needed.
}
