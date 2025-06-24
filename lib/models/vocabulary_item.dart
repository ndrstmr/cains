// lib/models/vocabulary_item.dart

/// Enum representing the source of a vocabulary item.
enum VocabularySourceType {
  /// Added by the user manually.
  custom,
  /// Added via AI suggestion.
  ai_added,
  /// Added from scanned text.
  scanned_text,
}

/// Represents a single vocabulary item.
class VocabularyItem {
  final String id;
  final String word;
  final Map<String, String> definitions; // e.g., {'de': '...', 'en': '...', 'es': '...'}
  final List<String>? synonyms;
  final List<String>? collocations;
  final List<String>? exampleSentences;
  final VocabularySourceType sourceType;

  /// Creates a new [VocabularyItem] instance.
  ///
  /// Requires [id], [word], [definitions], and [sourceType].
  /// [synonyms], [collocations], and [exampleSentences] are optional.
  const VocabularyItem({
    required this.id,
    required this.word,
    required this.definitions,
    this.synonyms,
    this.collocations,
    this.exampleSentences,
    required this.sourceType,
  });

  /// Creates a [VocabularyItem] from a JSON object.
  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      id: json['id'] as String,
      word: json['word'] as String,
      definitions: Map<String, String>.from(json['definitions'] as Map),
      synonyms: (json['synonyms'] as List<dynamic>?)?.map((e) => e as String).toList(),
      collocations: (json['collocations'] as List<dynamic>?)?.map((e) => e as String).toList(),
      exampleSentences: (json['exampleSentences'] as List<dynamic>?)?.map((e) => e as String).toList(),
      sourceType: VocabularySourceType.values.byName(json['sourceType'] as String),
    );
  }

  /// Converts this [VocabularyItem] to a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'definitions': definitions,
      'synonyms': synonyms,
      'collocations': collocations,
      'exampleSentences': exampleSentences,
      'sourceType': sourceType.name,
    };
  }

  /// Creates a copy of this [VocabularyItem] but with the given fields replaced with the new values.
  VocabularyItem copyWith({
    String? id,
    String? word,
    Map<String, String>? definitions,
    List<String>? synonyms,
    List<String>? collocations,
    List<String>? exampleSentences,
    VocabularySourceType? sourceType,
  }) {
    return VocabularyItem(
      id: id ?? this.id,
      word: word ?? this.word,
      definitions: definitions ?? this.definitions,
      synonyms: synonyms ?? this.synonyms,
      collocations: collocations ?? this.collocations,
      exampleSentences: exampleSentences ?? this.exampleSentences,
      sourceType: sourceType ?? this.sourceType,
    );
  }
}
