import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/planting.dart';
import '../domain/planting_repository.dart';

class FirestorePlantingRepository implements PlantingRepository {
  FirestorePlantingRepository({
    FirebaseFirestore? firestore,
    DateTime Function()? clock,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _clock = clock ?? DateTime.now;

  final FirebaseFirestore _firestore;
  final DateTime Function() _clock;

  @override
  Future<String> addPlanting({
    required String ownerId,
    required String parcelId,
    required String cropId,
    required DateTime plantedAt,
    required int growingDurationDays,
  }) async {
    if (growingDurationDays <= 0) {
      throw const PlantingException(
        PlantingException.invalidDuration,
        message: 'Trajanje uzgoja kulture mora biti veće od nule.',
      );
    }

    final parcelRef = _firestore.collection('parcels').doc(parcelId);
    final plantingRef = _firestore.collection('plantings').doc();
    final plantingsCollection = _firestore.collection('plantings');

    final plantedDay = DateTime(plantedAt.year, plantedAt.month, plantedAt.day);
    final harvestDay = DateTime(
      plantedDay.year,
      plantedDay.month,
      plantedDay.day + growingDurationDays,
    );
    final now = Timestamp.fromDate(_clock());

    await _firestore.runTransaction((transaction) async {
      final parcelSnapshot = await transaction.get(parcelRef);
      final parcel = parcelSnapshot.data();

      if (!parcelSnapshot.exists || parcel == null) {
        throw const PlantingException(
          PlantingException.parcelNotFound,
          message: 'Odabrana parcela ne postoji.',
        );
      }
      if (parcel['ownerId'] != ownerId) {
        throw const PlantingException(
          PlantingException.notParcelOwner,
          message: 'Sadnju možete evidentirati samo na vlastitoj parceli.',
        );
      }

      final previousId = parcel['activePlantingId'];
      DocumentReference<Map<String, dynamic>>? previousRef;
      if (previousId is String) {
        final ref = plantingsCollection.doc(previousId);
        final previousSnapshot = await transaction.get(ref);
        if (previousSnapshot.exists &&
            previousSnapshot.data()?['status'] != 'completed') {
          previousRef = ref;
        }
      }

      if (previousRef != null) {
        transaction.update(previousRef, {
          'status': 'completed',
          'updatedAt': now,
        });
      }

      final planting = Planting(
        id: plantingRef.id,
        ownerId: ownerId,
        parcelId: parcelId,
        cropId: cropId,
        plantedAt: Timestamp.fromDate(plantedDay),
        expectedHarvestAt: Timestamp.fromDate(harvestDay),
        stage: 'planted',
        status: 'active',
        seasonYear: plantedDay.year,
        createdAt: now,
        updatedAt: now,
      );
      transaction.set(plantingRef, planting.toMap());
      transaction.update(parcelRef, {
        'activePlantingId': plantingRef.id,
        'updatedAt': now,
      });
    });

    return plantingRef.id;
  }
}
