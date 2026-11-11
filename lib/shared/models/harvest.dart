import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

/// Firestore document in the harvests collection.
class Harvest {
  Harvest({
    required this.id,
    required this.ownerId,
    required this.parcelId,
    required this.plantingId,
    required this.harvestedAt,
    required this.quantityKg,
    required this.areaHaAtHarvest,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String parcelId;
  final String plantingId;
  final Timestamp harvestedAt;
  final double quantityKg;
  final double areaHaAtHarvest;
  final String note;
  final Timestamp createdAt;

  factory Harvest.fromMap(String id, Map<String, dynamic> data) => Harvest(
    id: id,
    ownerId: readField<String>('ownerId', data, (value) => value as String)!,
    parcelId: readField<String>('parcelId', data, (value) => value as String)!,
    plantingId: readField<String>(
      'plantingId',
      data,
      (value) => value as String,
    )!,
    harvestedAt: readField<Timestamp>(
      'harvestedAt',
      data,
      (value) => value as Timestamp,
    )!,
    quantityKg: readField<double>(
      'quantityKg',
      data,
      (value) => (value as num).toDouble(),
    )!,
    areaHaAtHarvest: readField<double>(
      'areaHaAtHarvest',
      data,
      (value) => (value as num).toDouble(),
    )!,
    note: readField<String>('note', data, (value) => value as String)!,
    createdAt: readField<Timestamp>(
      'createdAt',
      data,
      (value) => value as Timestamp,
    )!,
  );

  factory Harvest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Document does not exist: ${snapshot.reference.path}');
    }
    return Harvest.fromMap(snapshot.id, data);
  }

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'parcelId': parcelId,
    'plantingId': plantingId,
    'harvestedAt': harvestedAt,
    'quantityKg': quantityKg,
    'areaHaAtHarvest': areaHaAtHarvest,
    'note': note,
    'createdAt': createdAt,
  };
}
