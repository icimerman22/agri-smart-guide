import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

Future<void> seedParcel(
  FakeFirebaseFirestore firestore,
  String id, {
  String ownerId = 'alice',
  String name = 'Njiva',
  String? activePlantingId,
}) {
  return firestore.collection('parcels').doc(id).set({
    'ownerId': ownerId,
    'name': name,
    'areaHa': 1.5,
    'soilType': 'glinasto',
    'locationName': 'Varaždin',
    'coordinates': const GeoPoint(46.3, 16.3),
    'activePlantingId': activePlantingId,
    'createdAt': Timestamp(100, 0),
    'updatedAt': Timestamp(100, 0),
  });
}

Future<void> seedPlanting(
  FakeFirebaseFirestore firestore,
  String id, {
  String ownerId = 'alice',
  String parcelId = 'p1',
  String cropId = 'tomato',
  String status = 'active',
}) {
  return firestore.collection('plantings').doc(id).set({
    'ownerId': ownerId,
    'parcelId': parcelId,
    'cropId': cropId,
    'plantedAt': Timestamp(100, 0),
    'expectedHarvestAt': Timestamp(200, 0),
    'stage': 'planted',
    'status': status,
    'seasonYear': 2026,
    'createdAt': Timestamp(100, 0),
    'updatedAt': Timestamp(100, 0),
  });
}
