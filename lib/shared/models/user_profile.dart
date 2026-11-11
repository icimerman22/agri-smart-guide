import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

/// Firestore document in the users collection.
class UserProfile {
  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.farmName,
    required Map<String, dynamic> primaryLocation,
    required this.unitSystem,
    required Map<String, dynamic> notificationSettings,
    required this.createdAt,
    required this.updatedAt,
  }) : primaryLocation = freezeMap(primaryLocation),
       notificationSettings = freezeMap(notificationSettings);

  final String id;
  final String firstName;
  final String lastName;
  final String farmName;
  final Map<String, dynamic> primaryLocation;
  final String unitSystem;
  final Map<String, dynamic> notificationSettings;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  factory UserProfile.fromMap(
    String id,
    Map<String, dynamic> data,
  ) => UserProfile(
    id: id,
    firstName: readField<String>(
      'firstName',
      data,
      (value) => value as String,
    )!,
    lastName: readField<String>('lastName', data, (value) => value as String)!,
    farmName: readField<String>('farmName', data, (value) => value as String)!,
    primaryLocation: readField<Map<String, dynamic>>(
      'primaryLocation',
      data,
      (value) => Map<String, dynamic>.from(value as Map),
    )!,
    unitSystem: readField<String>(
      'unitSystem',
      data,
      (value) => value as String,
    )!,
    notificationSettings: readField<Map<String, dynamic>>(
      'notificationSettings',
      data,
      (value) => Map<String, dynamic>.from(value as Map),
    )!,
    createdAt: readField<Timestamp>(
      'createdAt',
      data,
      (value) => value as Timestamp,
    )!,
    updatedAt: readField<Timestamp>(
      'updatedAt',
      data,
      (value) => value as Timestamp,
    )!,
  );

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Document does not exist: ${snapshot.reference.path}');
    }
    return UserProfile.fromMap(snapshot.id, data);
  }

  Map<String, dynamic> toMap() => {
    'firstName': firstName,
    'lastName': lastName,
    'farmName': farmName,
    'primaryLocation': primaryLocation,
    'unitSystem': unitSystem,
    'notificationSettings': notificationSettings,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}
