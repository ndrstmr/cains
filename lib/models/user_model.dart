// lib/models/user_model.dart

/// Represents a user in the application.
class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  // TODO: Add progress tracking fields later

  /// Creates a new [UserModel] instance.
  ///
  /// Requires [uid].
  /// [email] and [displayName] are optional.
  const UserModel({
    required this.uid,
    this.email,
    this.displayName,
  });

  /// Creates a [UserModel] from a JSON object.
  ///
  /// Useful for deserializing data from Firestore.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
    );
  }

  /// Converts this [UserModel] to a JSON object.
  ///
  /// Useful for serializing data to Firestore.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
    };
  }

  /// Creates a copy of this [UserModel] but with the given fields replaced with the new values.
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
    );
  }
}
