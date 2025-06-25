// lib/models/challenge_model.dart

/// Enum representing the status of a challenge.
enum ChallengeStatus {
  /// The challenge is open and not yet completed.
  open,

  /// The challenge has been successfully completed.
  completed,

  /// The challenge was failed or expired.
  failed,
}

/// Represents a daily challenge for the user.
class ChallengeModel {
  final String id; // Typically YYYY-MM-DD from the function
  final String userId; // ID of the user this challenge belongs to
  final String title;
  final String description;
  final String targetWord;
  final String targetTopicId;
  final String? targetTopicTitleEn; // Optional, for display convenience
  final String targetVocabularyItemId;
  final ChallengeStatus status;
  final String dateCreated; // YYYY-MM-DD

  /// Creates a new [ChallengeModel] instance.
  const ChallengeModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.targetWord,
    required this.targetTopicId,
    this.targetTopicTitleEn,
    required this.targetVocabularyItemId,
    required this.status,
    required this.dateCreated,
  });

  /// Creates a [ChallengeModel] from a JSON object (e.g., from Firestore or Cloud Function).
  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '', // Default to empty if missing, though should be present
      title: json['title'] as String,
      description: json['description'] as String,
      targetWord: json['targetWord'] as String,
      targetTopicId: json['targetTopicId'] as String,
      targetTopicTitleEn: json['targetTopicTitleEn'] as String?,
      targetVocabularyItemId: json['targetVocabularyItemId'] as String,
      status: ChallengeStatus.values.byName(json['status'] as String? ?? 'open'), // Default to open if status is missing or invalid
      dateCreated: json['dateCreated'] as String? ?? (json['id'] as String? ?? ''), // Fallback to id if dateCreated is missing
    );
  }

  /// Converts this [ChallengeModel] to a JSON object for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'targetWord': targetWord,
      'targetTopicId': targetTopicId,
      if (targetTopicTitleEn != null) 'targetTopicTitleEn': targetTopicTitleEn,
      'targetVocabularyItemId': targetVocabularyItemId,
      'status': status.name,
      'dateCreated': dateCreated,
    };
  }

  /// Creates a copy of this [ChallengeModel] but with the given fields replaced with the new values.
  ChallengeModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? targetWord,
    String? targetTopicId,
    String? targetTopicTitleEn,
    String? targetVocabularyItemId,
    ChallengeStatus? status,
    String? dateCreated,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetWord: targetWord ?? this.targetWord,
      targetTopicId: targetTopicId ?? this.targetTopicId,
      targetTopicTitleEn: targetTopicTitleEn ?? this.targetTopicTitleEn,
      targetVocabularyItemId: targetVocabularyItemId ?? this.targetVocabularyItemId,
      status: status ?? this.status,
      dateCreated: dateCreated ?? this.dateCreated,
    );
  }
}
