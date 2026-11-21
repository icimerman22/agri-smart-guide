abstract interface class PlantingRepository {
  Future<String> addPlanting({
    required String ownerId,
    required String parcelId,
    required String cropId,
    required DateTime plantedAt,
    required int growingDurationDays,
  });
}

class PlantingException implements Exception {
  const PlantingException(this.code, {this.message});

  static const parcelNotFound = 'parcel-not-found';
  static const notParcelOwner = 'not-parcel-owner';
  static const invalidDuration = 'invalid-duration';

  final String code;
  final String? message;

  @override
  String toString() => message ?? code;
}
