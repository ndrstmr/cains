// lib/models/topic_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show immutable;

/// Represents a learning topic.
@immutable
class Topic {
  final String id;
  final String titleDe;
  final String titleEn;
  final String titleEs;
  final String descriptionDe;
  final String descriptionEn;
  final String descriptionEs;
  final String
  iconName; // e.g., 'business', 'science' to be mapped to an IconData

  /// Creates a [Topic] instance.
  /// All fields are required.
  const Topic({
    required this.id,
    required this.titleDe,
    required this.titleEn,
    required this.titleEs,
    required this.descriptionDe,
    required this.descriptionEn,
    required this.descriptionEs,
    required this.iconName,
  });

  /// Creates a [Topic] instance from a Firestore document snapshot.
  ///
  /// Expects the snapshot data to contain fields matching the [Topic] properties.
  factory Topic.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Missing data for Topic document: ${doc.id}');
    }
    return Topic(
      id: doc.id,
      titleDe: data['titleDe'] as String? ?? '', // Provide default if null
      titleEn: data['titleEn'] as String? ?? '',
      titleEs: data['titleEs'] as String? ?? '',
      descriptionDe: data['descriptionDe'] as String? ?? '',
      descriptionEn: data['descriptionEn'] as String? ?? '',
      descriptionEs: data['descriptionEs'] as String? ?? '',
      iconName:
          data['iconName'] as String? ??
          'default_icon', // Provide a default icon name
    );
  }

  /// Converts this [Topic] instance to a Map suitable for Firestore.
  /// The `id` is typically used as the document ID and not stored as a field within the document.
  Map<String, dynamic> toFirestore() {
    return {
      'titleDe': titleDe,
      'titleEn': titleEn,
      'titleEs': titleEs,
      'descriptionDe': descriptionDe,
      'descriptionEn': descriptionEn,
      'descriptionEs': descriptionEs,
      'iconName': iconName,
    };
  }

  // Helper method to get localized title based on current locale (conceptual)
  // This would typically be used in the UI layer with access to AppLocalizations.
  // String getLocalizedTitle(String languageCode) {
  //   switch (languageCode) {
  //     case 'de': return titleDe;
  //     case 'en': return titleEn;
  //     case 'es': return titleEs;
  //     default: return titleEn; // Default to English
  //   }
  // }

  // String getLocalizedDescription(String languageCode) {
  //   switch (languageCode) {
  //     case 'de': return descriptionDe;
  //     case 'en': return descriptionEn;
  //     case 'es': return descriptionEs;
  //     default: return descriptionEn; // Default to English
  //   }
  // }
}
