import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

/// Firestore document in the rotation_plans collection.
class RotationPlan {
  RotationPlan({
    required this.id,
    required this.ownerId,
    required this.parcelId,
    required this.seasonYear,
    required this.cropId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String parcelId;
  final int seasonYear;
  final String cropId;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  factory RotationPlan.fromMap(
    String id,
    Map<String, dynamic> data,
  ) => RotationPlan(
    id: id,
    ownerId: readField<String>('ownerId', data, (value) => value as String)!,
    parcelId: readField<String>('parcelId', data, (value) => value as String)!,
    seasonYear: readField<int>('seasonYear', data, (value) => value as int)!,
    cropId: readField<String>('cropId', data, (value) => value as String)!,
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

  factory RotationPlan.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Document does not exist: ${snapshot.reference.path}');
    }
    return RotationPlan.fromMap(snapshot.id, data);
  }

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'parcelId': parcelId,
    'seasonYear': seasonYear,
    'cropId': cropId,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  static String documentId(String parcelId, int seasonYear) =>
      '${parcelId}_$seasonYear';
}
