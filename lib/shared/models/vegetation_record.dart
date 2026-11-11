import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

/// Firestore document in the vegetation_records collection.
class VegetationRecord {
  VegetationRecord({
    required this.id,
    required this.ownerId,
    required this.parcelId,
    required this.measuredAt,
    required this.ndvi,
    required this.healthStatus,
    required this.summary,
    this.visualizationAssetPath,
    required this.isDemo,
  });

  final String id;
  final String ownerId;
  final String parcelId;
  final Timestamp measuredAt;
  final double ndvi;
  final String healthStatus;
  final String summary;
  final String? visualizationAssetPath;
  final bool isDemo;

  factory VegetationRecord.fromMap(
    String id,
    Map<String, dynamic> data,
  ) => VegetationRecord(
    id: id,
    ownerId: readField<String>('ownerId', data, (value) => value as String)!,
    parcelId: readField<String>('parcelId', data, (value) => value as String)!,
    measuredAt: readField<Timestamp>(
      'measuredAt',
      data,
      (value) => value as Timestamp,
    )!,
    ndvi: readField<double>(
      'ndvi',
      data,
      (value) => (value as num).toDouble(),
    )!,
    healthStatus: readField<String>(
      'healthStatus',
      data,
      (value) => value as String,
    )!,
    summary: readField<String>('summary', data, (value) => value as String)!,
    visualizationAssetPath: readField<String>(
      'visualizationAssetPath',
      data,
      (value) => value as String,
      optional: true,
    ),
    isDemo: readField<bool>('isDemo', data, (value) => value as bool)!,
  );

  factory VegetationRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Document does not exist: ${snapshot.reference.path}');
    }
    return VegetationRecord.fromMap(snapshot.id, data);
  }

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'parcelId': parcelId,
    'measuredAt': measuredAt,
    'ndvi': ndvi,
    'healthStatus': healthStatus,
    'summary': summary,
    'visualizationAssetPath': visualizationAssetPath,
    'isDemo': isDemo,
  };
}
