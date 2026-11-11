import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

/// Firestore document in the parcels collection.
class Parcel {
  Parcel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.areaHa,
    required this.soilType,
    required this.locationName,
    required this.coordinates,
    this.activePlantingId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final double areaHa;
  final String soilType;
  final String locationName;
  final GeoPoint coordinates;
  final String? activePlantingId;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  factory Parcel.fromMap(String id, Map<String, dynamic> data) => Parcel(
    id: id,
    ownerId: readField<String>('ownerId', data, (value) => value as String)!,
    name: readField<String>('name', data, (value) => value as String)!,
    areaHa: readField<double>(
      'areaHa',
      data,
      (value) => (value as num).toDouble(),
    )!,
    soilType: readField<String>('soilType', data, (value) => value as String)!,
    locationName: readField<String>(
      'locationName',
      data,
      (value) => value as String,
    )!,
    coordinates: readField<GeoPoint>(
      'coordinates',
      data,
      (value) => value as GeoPoint,
    )!,
    activePlantingId: readField<String>(
      'activePlantingId',
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

  factory Parcel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Document does not exist: ${snapshot.reference.path}');
    }
    return Parcel.fromMap(snapshot.id, data);
  }

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'name': name,
    'areaHa': areaHa,
    'soilType': soilType,
    'locationName': locationName,
    'coordinates': coordinates,
    'activePlantingId': activePlantingId,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}
