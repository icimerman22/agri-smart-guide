import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/user_profile.dart';

/// Access to the user profile document (`users/{uid}`).
///
/// Screens depend only on this interface; the concrete implementation
/// (Firestore, or a fake in tests) is injected from outside.
abstract interface class ProfileRepository {
  /// Returns the user profile. If the document does not exist yet (e.g. right
  /// after registration), returns an unsaved profile with default values.
  Future<UserProfile> loadProfile(String uid);

  /// Saves the whole profile and sets `updatedAt` to the current time.
  Future<UserProfile> saveProfile(UserProfile profile);
}

class ProfileException implements Exception {
  const ProfileException(this.code, {this.message});

  final String code;
  final String? message;

  @override
  String toString() => message ?? code;
}

/// Profile for a user who has no saved document yet.
UserProfile defaultUserProfile(String uid, Timestamp now) => UserProfile(
  id: uid,
  firstName: '',
  lastName: '',
  farmName: '',
  primaryLocation: const {},
  unitSystem: 'metric',
  notificationSettings: const {},
  createdAt: now,
  updatedAt: now,
);

extension UserProfileCopy on UserProfile {
  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? farmName,
    Map<String, dynamic>? primaryLocation,
    String? unitSystem,
    Map<String, dynamic>? notificationSettings,
    Timestamp? updatedAt,
  }) => UserProfile(
    id: id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    farmName: farmName ?? this.farmName,
    primaryLocation: primaryLocation ?? this.primaryLocation,
    unitSystem: unitSystem ?? this.unitSystem,
    notificationSettings: notificationSettings ?? this.notificationSettings,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
