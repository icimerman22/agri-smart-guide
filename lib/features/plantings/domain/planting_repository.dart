import '../../../shared/models/planting.dart';

abstract interface class PlantingRepository {
  Future<String> addPlanting({
    required String ownerId,
    required String parcelId,
    required String cropId,
    required DateTime plantedAt,
    required int growingDurationDays,
  });

  Stream<List<Planting>> watchPlantings(String ownerId);

  Stream<Planting?> watchPlanting(String plantingId);

  Future<void> updateStage({
    required String ownerId,
    required String plantingId,
    required String stage,
  });

  Future<void> updateStatus({
    required String ownerId,
    required String plantingId,
    required String status,
  });
}

class PlantingException implements Exception {
  const PlantingException(this.code, {this.message});

  static const parcelNotFound = 'parcel-not-found';
  static const notParcelOwner = 'not-parcel-owner';
  static const invalidDuration = 'invalid-duration';
  static const plantingNotFound = 'planting-not-found';
  static const notPlantingOwner = 'not-planting-owner';
  static const invalidStage = 'invalid-stage';
  static const invalidStatus = 'invalid-status';
  static const parcelOccupied = 'parcel-occupied';

  final String code;
  final String? message;

  @override
  String toString() => message ?? code;
}
