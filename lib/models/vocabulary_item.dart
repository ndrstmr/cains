// Defines the data structure for a vocabulary item.
// Includes methods for Firestore serialization and deserialization.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the type of source for a vocabulary item.
enum SourceType {
  predefined, // Provided by the app
  ai_added, // Added by AI
  scanned_text, // Added from scanned text
}

/// Represents a single vocabulary item.
class VocabularyItem {
  /// The unique identifier for the vocabulary item.
  final String id;

  /// The C1 word.
  final String word;

  /// Definitions of the word in multiple languages.
  /// Key: language code (e.g., 'de', 'en', 'es')
  /// Value: definition in that language
  final Map<String, String> definitions;

  /// A list of synonyms for the word.
  final List<String> synonyms;

  /// A list of collocations or typical word combinations.
  final List<String> collocations;

  /// Example sentences for the word in multiple languages.
  /// Key: language code (e.g., 'de', 'en', 'es')
  /// Value: list of example sentences in that language
  final Map<String, List<String>> exampleSentences;

  /// The proficiency level of the word (e.g., 'C1').
  final String level;

  /// The source type of the vocabulary item.
  final SourceType sourceType;

  /// The identifier of the topic this vocabulary item belongs to.
  final String topicId;

  /// A short grammar hint for the word (e.g., "Noun, feminine").
  final String? grammarHint;

  /// A short contextual text explaining when the word is typically used.
  final String? contextualText;

  /// Constructs a [VocabularyItem].
  VocabularyItem({
    required this.id,
    required this.word,
    required this.definitions,
    required this.synonyms,
    required this.collocations,
    required this.exampleSentences,
    this.level = 'C1', // Default level to C1
    required this.sourceType,
    required this.topicId,
    this.grammarHint,
    this.contextualText,
  });

  /// Creates a [VocabularyItem] from a JSON map.
  /// Expects 'id' to be present in the JSON map.
  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      id: json['id'] as String,
      word: json['word'] as String,
      definitions: Map<String, String>.from(json['definitions'] as Map),
      synonyms: List<String>.from(json['synonyms'] as List),
      collocations: List<String>.from(json['collocations'] as List),
      exampleSentences: (json['exampleSentences'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, List<String>.from(value as List)),
      ),
      level: json['level'] as String? ?? 'C1',
      sourceType: SourceType.values.firstWhere(
        (e) => e.toString().split('.').last == (json['sourceType'] as String? ?? SourceType.ai_added.toString().split('.').last),
        orElse: () => SourceType.ai_added,
      ),
      topicId: json['topicId'] as String? ?? 'ai_researched',
      grammarHint: json['grammarHint'] as String?,
      contextualText: json['contextualText'] as String?,
    );
  }

  /// Creates a [VocabularyItem] from a Firestore document snapshot.
  factory VocabularyItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Missing data for VocabularyItem ${snapshot.id}');
    }

    return VocabularyItem(
      id: snapshot.id,
      word: data['word'] as String,
      definitions: Map<String, String>.from(data['definitions'] as Map),
      synonyms: List<String>.from(data['synonyms'] as List),
      collocations: List<String>.from(data['collocations'] as List),
      exampleSentences: (data['exampleSentences'] as Map).map(
        (key, value) => MapEntry(key as String, List<String>.from(value as List)),
      ),
      level: data['level'] as String? ?? 'C1', // Default to C1 if not present
      sourceType: SourceType.values.firstWhere(
        (e) => e.toString() == 'SourceType.${data['sourceType'] as String}',
        orElse: () => SourceType.predefined, // Default if parsing fails
      ),
      topicId: data['topicId'] as String,
      grammarHint: data['grammarHint'] as String?,
      contextualText: data['contextualText'] as String?,
    );
  }

  /// Converts a [VocabularyItem] instance to a Map suitable for Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'word': word,
      'definitions': definitions,
      'synonyms': synonyms,
      'collocations': collocations,
      'exampleSentences': exampleSentences,
      'level': level,
      'sourceType': sourceType.toString().split('.').last, // Store enum as string
      'topicId': topicId,
      if (grammarHint != null) 'grammarHint': grammarHint,
      if (contextualText != null) 'contextualText': contextualText,
    };
  }
}
