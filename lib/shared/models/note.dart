import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

/// Firestore document in the notes collection.
class Note {
  Note({
    required this.id,
    required this.ownerId,
    this.parcelId,
    required this.title,
    required this.content,
    required List<String> photoPaths,
    required this.createdAt,
    required this.updatedAt,
  }) : photoPaths = List<String>.unmodifiable(photoPaths);

  final String id;
  final String ownerId;
  final String? parcelId;
  final String title;
  final String content;
  final List<String> photoPaths;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  factory Note.fromMap(String id, Map<String, dynamic> data) => Note(
    id: id,
    ownerId: readField<String>('ownerId', data, (value) => value as String)!,
    parcelId: readField<String>(
      'parcelId',
      data,
      (value) => value as String,
      optional: true,
    ),
    title: readField<String>('title', data, (value) => value as String)!,
    content: readField<String>('content', data, (value) => value as String)!,
    photoPaths: readField<List<String>>(
      'photoPaths',
      data,
      (value) => List<String>.from(value as List),
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

  factory Note.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Document does not exist: ${snapshot.reference.path}');
    }
    return Note.fromMap(snapshot.id, data);
  }

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'parcelId': parcelId,
    'title': title,
    'content': content,
    'photoPaths': photoPaths,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}
