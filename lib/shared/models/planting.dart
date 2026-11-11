import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

/// Firestore document in the plantings collection.
class Planting {
  Planting({
    required this.id,
    required this.ownerId,
    required this.parcelId,
    required this.cropId,
    required this.plantedAt,
    required this.expectedHarvestAt,
    required this.stage,
    required this.status,
    required this.seasonYear,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String parcelId;
  final String cropId;
  final Timestamp plantedAt;
  final Timestamp expectedHarvestAt;
  final String stage;
  final String status;
  final int seasonYear;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  factory Planting.fromMap(String id, Map<String, dynamic> data) => Planting(
    id: id,
    ownerId: readField<String>('ownerId', data, (value) => value as String)!,
    parcelId: readField<String>('parcelId', data, (value) => value as String)!,
    cropId: readField<String>('cropId', data, (value) => value as String)!,
    plantedAt: readField<Timestamp>(
      'plantedAt',
      data,
      (value) => value as Timestamp,
    )!,
    expectedHarvestAt: readField<Timestamp>(
      'expectedHarvestAt',
      data,
      (value) => value as Timestamp,
    )!,
    stage: readField<String>('stage', data, (value) => value as String)!,
    status: readField<String>('status', data, (value) => value as String)!,
    seasonYear: readField<int>('seasonYear', data, (value) => value as int)!,
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

  factory Planting.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Document does not exist: ${snapshot.reference.path}');
    }
    return Planting.fromMap(snapshot.id, data);
  }

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'parcelId': parcelId,
    'cropId': cropId,
    'plantedAt': plantedAt,
    'expectedHarvestAt': expectedHarvestAt,
    'stage': stage,
    'status': status,
    'seasonYear': seasonYear,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}
