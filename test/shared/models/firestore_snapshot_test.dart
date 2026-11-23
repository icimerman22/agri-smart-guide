// Test-only snapshot doubles avoid a platform dependency or a mocking library.
// ignore_for_file: subtype_of_sealed_class

import 'package:agri_smart_guide/shared/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// Only snapshot metadata is substituted; no Firebase app or platform calls.
class _Snapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this.value);
  final Map<String, dynamic>? value;

  @override
  String get id => 'snapshot-id';
  @override
  Map<String, dynamic>? data() => value;
  @override
  DocumentReference<Map<String, dynamic>> get reference => _Reference();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Reference implements DocumentReference<Map<String, dynamic>> {
  @override
  String get path => 'parcels/snapshot-id';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final factories =
      <String, Object Function(DocumentSnapshot<Map<String, dynamic>>)>{
        'UserProfile': UserProfile.fromFirestore,
        'Parcel': Parcel.fromFirestore,
        'Crop': Crop.fromFirestore,
        'Planting': Planting.fromFirestore,
        'FarmTask': FarmTask.fromFirestore,
        'SoilAnalysis': SoilAnalysis.fromFirestore,
        'VegetationRecord': VegetationRecord.fromFirestore,
        'Note': Note.fromFirestore,
        'Harvest': Harvest.fromFirestore,
        'AppNotification': AppNotification.fromFirestore,
        'RotationPlan': RotationPlan.fromFirestore,
      };
  for (final entry in factories.entries) {
    test('${entry.key} rejects a missing snapshot', () {
      expect(() => entry.value(_Snapshot(null)), throwsStateError);
    });
    test('${entry.key} validates snapshot data', () {
      expect(() => entry.value(_Snapshot({})), throwsFormatException);
    });
  }
  test('snapshot uses its document ID and native Firestore values', () {
    final time = Timestamp(1700000000, 123456789);
    final parcel = Parcel.fromFirestore(
      _Snapshot({
        'id': 'ignored-embedded-id',
        'ownerId': 'alice',
        'name': 'Polje',
        'areaHa': 2,
        'soilType': 'loam',
        'locationName': 'Zagreb',
        'coordinates': const GeoPoint(45.8, 16),
        'createdAt': time,
        'updatedAt': time,
      }),
    );
    expect(parcel.id, 'snapshot-id');
    expect(parcel.areaHa, 2.0);
    expect(parcel.createdAt.nanoseconds, 123456789);
    expect(parcel.activePlantingId, isNull);
  });
}
