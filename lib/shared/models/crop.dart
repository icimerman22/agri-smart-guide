
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

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
    this.plantingPeriod,
    this.growingConditions,
    this.imageUrl,
    this.sortOrder,
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

  final String? plantingPeriod;
  final String? growingConditions;
  final String? imageUrl;
  final int? sortOrder;

  int get growingDurationDays => growthDays;

  String get waterNeeds => waterRequirement;

  String get plantingPeriodText {
    final value = plantingPeriod?.trim();
    return value == null || value.isEmpty
        ? 'Razdoblje sadnje nije navedeno.'
        : value;
  }

  String get growingConditionsText {
    final value = growingConditions?.trim();
    return value == null || value.isEmpty
        ? 'Uvjeti uzgoja nisu navedeni.'
        : value;
  }

  factory Crop.fromMap(
      String id,
      Map<String, dynamic> data,
      ) {
    return Crop(
      id: id,
      name: readField<String>(
        'name',
        data,
            (value) => value as String,
      )!,
      category: readField<String>(
        'category',
        data,
            (value) => value as String,
      )!,
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
      growthDays: readField<int>(
        'growthDays',
        data,
            (value) => value as int,
      )!,
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
      plantingPeriod: data['plantingPeriod'] as String?,
      growingConditions: data['growingConditions'] as String?,
      imageUrl: data['imageUrl'] as String?,
      sortOrder: data['sortOrder'] as int?,
    );
  }

  factory Crop.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      ) {
    final data = snapshot.data();

    if (data == null) {
      throw StateError(
        'Document does not exist: ${snapshot.reference.path}',
      );
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
    if (plantingPeriod != null)
      'plantingPeriod': plantingPeriod,
    if (growingConditions != null)
      'growingConditions': growingConditions,
    if (imageUrl != null)
      'imageUrl': imageUrl,
    if (sortOrder != null)
      'sortOrder': sortOrder,
  };
}
