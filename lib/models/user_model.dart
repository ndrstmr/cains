// lib/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user in the application, including their progress.
class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final int totalPoints;
  final int wordsFoundCount;

  /// Progress for each topic.
  /// Key: topicId (String)
  /// Value: Map<String, dynamic> containing:
  ///   - 'completedPuzzles': int
  ///   - 'totalWordsFoundInTopic': int
  ///   - 'lastPlayed': Timestamp
  final Map<String, Map<String, dynamic>> topicProgress;

  /// Tracks completed daily challenges.
  /// Key: Date string 'YYYY-MM-DD'
  /// Value: Challenge ID (String)
  final Map<String, String> dailyChallengeCompletion;

  /// Creates a new [UserModel] instance.
  const UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.totalPoints = 0,
    this.wordsFoundCount = 0,
    Map<String, Map<String, dynamic>>? topicProgress,
    Map<String, String>? dailyChallengeCompletion,
  })  : topicProgress = topicProgress ?? const {},
        dailyChallengeCompletion = dailyChallengeCompletion ?? const {};

  /// Creates a [UserModel] from a Firestore document snapshot.
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError("Missing data for UserModel fromFirestore: ${doc.id}");
    }

    // Safely parsing topicProgress with type checks
    final rawTopicProgress = data['topicProgress'] as Map<String, dynamic>? ?? {};
    final Map<String, Map<String, dynamic>> topicProgress = {};
    rawTopicProgress.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        // Ensure 'lastPlayed' is a Timestamp, convert if it's a different type (e.g. from JSON)
        final lastPlayedRaw = value['lastPlayed'];
        Timestamp lastPlayedTimestamp;
        if (lastPlayedRaw is Timestamp) {
          lastPlayedTimestamp = lastPlayedRaw;
        } else if (lastPlayedRaw is Map && lastPlayedRaw.containsKey('_seconds') && lastPlayedRaw.containsKey('_nanoseconds')) {
          // Handle cases where Timestamp might be serialized from non-Firestore sources
          lastPlayedTimestamp = Timestamp(lastPlayedRaw['_seconds'], lastPlayedRaw['_nanoseconds']);
        } else {
          // Default or error if type is unexpected
          lastPlayedTimestamp = Timestamp.now(); // Or handle error appropriately
        }

        topicProgress[key] = {
          'completedPuzzles': value['completedPuzzles'] as int? ?? 0,
          'totalWordsFoundInTopic': value['totalWordsFoundInTopic'] as int? ?? 0,
          'lastPlayed': lastPlayedTimestamp,
        };
      }
    });

    // Safely parsing dailyChallengeCompletion
    final rawDailyChallengeCompletion = data['dailyChallengeCompletion'] as Map<String, dynamic>? ?? {};
    final Map<String, String> dailyChallengeCompletion = rawDailyChallengeCompletion.map(
        (key, value) => MapEntry(key, value as String? ?? ''));


    return UserModel(
      uid: data['uid'] as String? ?? doc.id, // Use doc.id as fallback for uid if not in data
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      totalPoints: data['totalPoints'] as int? ?? 0,
      wordsFoundCount: data['wordsFoundCount'] as int? ?? 0,
      topicProgress: topicProgress,
      dailyChallengeCompletion: dailyChallengeCompletion,
    );
  }

  /// Converts this [UserModel] to a JSON object for Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      if (email != null) 'email': email,
      if (displayName != null) 'displayName': displayName,
      'totalPoints': totalPoints,
      'wordsFoundCount': wordsFoundCount,
      'topicProgress': topicProgress, // Firestore handles Timestamps directly
      'dailyChallengeCompletion': dailyChallengeCompletion,
    };
  }

  /// Creates a copy of this [UserModel] but with the given fields replaced with the new values.
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    int? totalPoints,
    int? wordsFoundCount,
    Map<String, Map<String, dynamic>>? topicProgress,
    Map<String, String>? dailyChallengeCompletion,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      totalPoints: totalPoints ?? this.totalPoints,
      wordsFoundCount: wordsFoundCount ?? this.wordsFoundCount,
      topicProgress: topicProgress ?? this.topicProgress,
      dailyChallengeCompletion: dailyChallengeCompletion ?? this.dailyChallengeCompletion,
    );
  }
}
