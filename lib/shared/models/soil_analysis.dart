import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

/// Firestore document in the soil_analyses collection.
class SoilAnalysis {
  SoilAnalysis({
    required this.id,
    required this.ownerId,
    required this.parcelId,
    required this.sampledAt,
    required this.ph,
    required this.humusPercent,
    required this.nitrogenPercent,
    required this.phosphorusMgPer100g,
    required this.potassiumMgPer100g,
    this.moisturePercent,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String parcelId;
  final Timestamp sampledAt;
  final double ph;
  final double humusPercent;
  final double nitrogenPercent;
  final double phosphorusMgPer100g;
  final double potassiumMgPer100g;
  final double? moisturePercent;
  final Timestamp createdAt;

  factory SoilAnalysis.fromMap(
    String id,
    Map<String, dynamic> data,
  ) => SoilAnalysis(
    id: id,
    ownerId: readField<String>('ownerId', data, (value) => value as String)!,
    parcelId: readField<String>('parcelId', data, (value) => value as String)!,
    sampledAt: readField<Timestamp>(
      'sampledAt',
      data,
      (value) => value as Timestamp,
    )!,
    ph: readField<double>('ph', data, (value) => (value as num).toDouble())!,
    humusPercent: readField<double>(
      'humusPercent',
      data,
      (value) => (value as num).toDouble(),
    )!,
    nitrogenPercent: readField<double>(
      'nitrogenPercent',
      data,
      (value) => (value as num).toDouble(),
    )!,
    phosphorusMgPer100g: readField<double>(
      'phosphorusMgPer100g',
      data,
      (value) => (value as num).toDouble(),
    )!,
    potassiumMgPer100g: readField<double>(
      'potassiumMgPer100g',
      data,
      (value) => (value as num).toDouble(),
    )!,
    moisturePercent: readField<double>(
      'moisturePercent',
      data,
      (value) => (value as num).toDouble(),
      optional: true,
    ),
    createdAt: readField<Timestamp>(
      'createdAt',
      data,
      (value) => value as Timestamp,
    )!,
  );

  factory SoilAnalysis.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Document does not exist: ${snapshot.reference.path}');
    }
    return SoilAnalysis.fromMap(snapshot.id, data);
  }

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'parcelId': parcelId,
    'sampledAt': sampledAt,
    'ph': ph,
    'humusPercent': humusPercent,
    'nitrogenPercent': nitrogenPercent,
    'phosphorusMgPer100g': phosphorusMgPer100g,
    'potassiumMgPer100g': potassiumMgPer100g,
    'moisturePercent': moisturePercent,
    'createdAt': createdAt,
  };
}
