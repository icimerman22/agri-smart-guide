import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

/// Firestore document in the tasks collection.
class FarmTask {
  FarmTask({
    required this.id,
    required this.ownerId,
    this.parcelId,
    required this.title,
    required this.description,
    required this.type,
    required this.dueAt,
    required this.priority,
    required this.status,
    this.completedAt,
    this.costCents,
    this.costCategory,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String? parcelId;
  final String title;
  final String description;
  final String type;
  final Timestamp dueAt;
  final String priority;
  final String status;
  final Timestamp? completedAt;
  final int? costCents;
  final String? costCategory;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  factory FarmTask.fromMap(String id, Map<String, dynamic> data) => FarmTask(
    id: id,
    ownerId: readField<String>('ownerId', data, (value) => value as String)!,
    parcelId: readField<String>(
      'parcelId',
      data,
      (value) => value as String,
      optional: true,
    ),
    title: readField<String>('title', data, (value) => value as String)!,
    description: readField<String>(
      'description',
      data,
      (value) => value as String,
    )!,
    type: readField<String>('type', data, (value) => value as String)!,
    dueAt: readField<Timestamp>('dueAt', data, (value) => value as Timestamp)!,
    priority: readField<String>('priority', data, (value) => value as String)!,
    status: readField<String>('status', data, (value) => value as String)!,
    completedAt: readField<Timestamp>(
      'completedAt',
      data,
      (value) => value as Timestamp,
      optional: true,
    ),
    costCents: readField<int>(
      'costCents',
      data,
      (value) => value as int,
      optional: true,
    ),
    costCategory: readField<String>(
      'costCategory',
      data,
      (value) => value as String,
      optional: true,
    ),
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

  factory FarmTask.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Document does not exist: ${snapshot.reference.path}');
    }
    return FarmTask.fromMap(snapshot.id, data);
  }

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'parcelId': parcelId,
    'title': title,
    'description': description,
    'type': type,
    'dueAt': dueAt,
    'priority': priority,
    'status': status,
    'completedAt': completedAt,
    'costCents': costCents,
    'costCategory': costCategory,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}
