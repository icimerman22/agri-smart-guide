import 'package:cloud_firestore/cloud_firestore.dart';

class Plot {
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

  Plot({
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

  Map<String, dynamic> toMap() {
    return {
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

  factory Plot.fromMap(String id, Map<String, dynamic> map) {
    return Plot(
      id: id,
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      areaHa: map['areaHa'] != null ? (map['areaHa'] as num).toDouble() : 0.0,
      soilType: map['soilType'] ?? '',
      locationName: map['locationName'] ?? '',
      coordinates: map['coordinates'] ?? const GeoPoint(0, 0),
      activePlantingId: map['activePlantingId'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
    );
  }
}