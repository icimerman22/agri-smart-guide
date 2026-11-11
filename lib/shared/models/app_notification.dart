import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

/// Firestore document in the notifications collection.
class AppNotification {
  AppNotification({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.title,
    required this.body,
    required this.relatedEntityType,
    required this.relatedEntityId,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String ownerId;
  final String type;
  final String title;
  final String body;
  final String relatedEntityType;
  final String relatedEntityId;
  final Timestamp createdAt;
  final Timestamp? readAt;

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) =>
      AppNotification(
        id: id,
        ownerId: readField<String>(
          'ownerId',
          data,
          (value) => value as String,
        )!,
        type: readField<String>('type', data, (value) => value as String)!,
        title: readField<String>('title', data, (value) => value as String)!,
        body: readField<String>('body', data, (value) => value as String)!,
        relatedEntityType: readField<String>(
          'relatedEntityType',
          data,
          (value) => value as String,
        )!,
        relatedEntityId: readField<String>(
          'relatedEntityId',
          data,
          (value) => value as String,
        )!,
        createdAt: readField<Timestamp>(
          'createdAt',
          data,
          (value) => value as Timestamp,
        )!,
        readAt: readField<Timestamp>(
          'readAt',
          data,
          (value) => value as Timestamp,
          optional: true,
        ),
      );

  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Document does not exist: ${snapshot.reference.path}');
    }
    return AppNotification.fromMap(snapshot.id, data);
  }

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'type': type,
    'title': title,
    'body': body,
    'relatedEntityType': relatedEntityType,
    'relatedEntityId': relatedEntityId,
    'createdAt': createdAt,
    'readAt': readAt,
  };
}
