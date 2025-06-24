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
  final String id;
  final String title;
  final String description;
  final String targetWord; // Could be an ID linking to a VocabularyItem
  final ChallengeStatus status;

  /// Creates a new [ChallengeModel] instance.
  ///
  /// Requires [id], [title], [description], [targetWord], and [status].
  const ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.targetWord,
    required this.status,
  });

  /// Creates a [ChallengeModel] from a JSON object.
  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      targetWord: json['targetWord'] as String,
      status: ChallengeStatus.values.byName(json['status'] as String),
    );
  }

  /// Converts this [ChallengeModel] to a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetWord': targetWord,
      'status': status.name,
    };
  }

  /// Creates a copy of this [ChallengeModel] but with the given fields replaced with the new values.
  ChallengeModel copyWith({
    String? id,
    String? title,
    String? description,
    String? targetWord,
    ChallengeStatus? status,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetWord: targetWord ?? this.targetWord,
      status: status ?? this.status,
    );
  }
}
