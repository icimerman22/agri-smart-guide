import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/planting.dart';
import '../domain/planting_repository.dart';
import '../domain/planting_stage.dart';

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

  @override
  Stream<List<Planting>> watchPlantings(String ownerId) {
    return _firestore
        .collection('plantings')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Planting.fromFirestore).toList());
  }

  @override
  Stream<Planting?> watchPlanting(String plantingId) {
    return _firestore
        .collection('plantings')
        .doc(plantingId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? Planting.fromFirestore(snapshot) : null);
  }

  @override
  Future<void> updateStage({
    required String ownerId,
    required String plantingId,
    required String stage,
  }) async {
    if (PlantingStage.fromKey(stage) == null) {
      throw const PlantingException(
        PlantingException.invalidStage,
        message: 'Odabrana razvojna faza nije valjana.',
      );
    }

    final ref = _firestore.collection('plantings').doc(plantingId);
    final now = Timestamp.fromDate(_clock());

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      _requireOwnedPlanting(snapshot, ownerId);
      transaction.update(ref, {'stage': stage, 'updatedAt': now});
    });
  }

  @override
  Future<void> updateStatus({
    required String ownerId,
    required String plantingId,
    required String status,
  }) async {
    if (status != PlantingStatus.active && status != PlantingStatus.completed) {
      throw const PlantingException(
        PlantingException.invalidStatus,
        message: 'Odabrani status uzgoja nije valjan.',
      );
    }

    final plantingRef = _firestore.collection('plantings').doc(plantingId);
    final now = Timestamp.fromDate(_clock());

    await _firestore.runTransaction((transaction) async {
      final plantingSnapshot = await transaction.get(plantingRef);
      final planting = _requireOwnedPlanting(plantingSnapshot, ownerId);

      final parcelRef = _firestore
          .collection('parcels')
          .doc(planting['parcelId'] as String);
      final parcelSnapshot = await transaction.get(parcelRef);
      final parcel = parcelSnapshot.data();
      if (!parcelSnapshot.exists || parcel == null) {
        throw const PlantingException(
          PlantingException.parcelNotFound,
          message: 'Parcela ove sadnje ne postoji.',
        );
      }

      final activeId = parcel['activePlantingId'];

      if (status == PlantingStatus.completed) {
        transaction.update(plantingRef, {'status': status, 'updatedAt': now});
        if (activeId == plantingId) {
          transaction.update(parcelRef, {
            'activePlantingId': null,
            'updatedAt': now,
          });
        }
        return;
      }

      if (activeId is String && activeId != plantingId) {
        final otherSnapshot = await transaction.get(
          _firestore.collection('plantings').doc(activeId),
        );
        if (otherSnapshot.exists &&
            otherSnapshot.data()?['status'] != PlantingStatus.completed) {
          throw const PlantingException(
            PlantingException.parcelOccupied,
            message:
                'Na parceli već postoji aktivna sadnja. Prvo je označite kao završenu.',
          );
        }
      }

      transaction.update(plantingRef, {'status': status, 'updatedAt': now});
      transaction.update(parcelRef, {
        'activePlantingId': plantingId,
        'updatedAt': now,
      });
    });
  }

  Map<String, dynamic> _requireOwnedPlanting(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    String ownerId,
  ) {
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw const PlantingException(
        PlantingException.plantingNotFound,
        message: 'Sadnja ne postoji.',
      );
    }
    if (data['ownerId'] != ownerId) {
      throw const PlantingException(
        PlantingException.notPlantingOwner,
        message: 'Možete mijenjati samo vlastite posađene kulture.',
      );
    }
    return data;
  }
}
