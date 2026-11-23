import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

/// Firestore document in the crops collection.
class Crop {
  Crop({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required List<int> sowingMonths,
    required this.growthDays,
    required this.waterRequirement,
    required this.rowSpacingCm,
    required this.plantSpacingCm,
    required this.optimalPhMin,
    required this.optimalPhMax,
  }) : sowingMonths = List<int>.unmodifiable(sowingMonths);

  final String id;
  final String name;
  final String category;
  final String description;
  final List<int> sowingMonths;
  final int growthDays;
  final String waterRequirement;
  final double rowSpacingCm;
  final double plantSpacingCm;
  final double optimalPhMin;
  final double optimalPhMax;

  factory Crop.fromMap(String id, Map<String, dynamic> data) => Crop(
    id: id,
    name: readField<String>('name', data, (value) => value as String)!,
    category: readField<String>('category', data, (value) => value as String)!,
    description: readField<String>(
      'description',
      data,
      (value) => value as String,
    )!,
    sowingMonths: readField<List<int>>(
      'sowingMonths',
      data,
      (value) => List<int>.from(value as List),
    )!,
    growthDays: readField<int>('growthDays', data, (value) => value as int)!,
    waterRequirement: readField<String>(
      'waterRequirement',
      data,
      (value) => value as String,
    )!,
    rowSpacingCm: readField<double>(
      'rowSpacingCm',
      data,
      (value) => (value as num).toDouble(),
    )!,
    plantSpacingCm: readField<double>(
      'plantSpacingCm',
      data,
      (value) => (value as num).toDouble(),
    )!,
    optimalPhMin: readField<double>(
      'optimalPhMin',
      data,
      (value) => (value as num).toDouble(),
    )!,
    optimalPhMax: readField<double>(
      'optimalPhMax',
      data,
      (value) => (value as num).toDouble(),
    )!,
  );

  factory Crop.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Document does not exist: ${snapshot.reference.path}');
    }
    return Crop.fromMap(snapshot.id, data);
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'description': description,
    'sowingMonths': sowingMonths,
    'growthDays': growthDays,
    'waterRequirement': waterRequirement,
    'rowSpacingCm': rowSpacingCm,
    'plantSpacingCm': plantSpacingCm,
    'optimalPhMin': optimalPhMin,
    'optimalPhMax': optimalPhMax,
  };
}
