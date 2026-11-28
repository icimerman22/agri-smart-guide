
class CropModel {
  final String id;
  final String name;
  final String description;
  final String plantingPeriod;
  final String growingConditions;
  final int growingDurationDays;
  final String waterNeeds;

  final String? imagePath;
  final String? imageUrl;
  final int? sortOrder;

  const CropModel({
    required this.id,
    required this.name,
    required this.description,
    required this.plantingPeriod,
    required this.growingConditions,
    required this.growingDurationDays,
    required this.waterNeeds,
    this.imagePath,
    this.imageUrl,
    this.sortOrder,
  });

  factory CropModel.fromJson(Map<String, dynamic> json) {
    return CropModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      plantingPeriod: json['plantingPeriod'] as String,
      growingConditions: json['growingConditions'] as String,
      growingDurationDays: json['growingDurationDays'] as int,
      waterNeeds: json['waterNeeds'] as String,
      imagePath: json['imagePath'] as String?,
      imageUrl: json['imageUrl'] as String?,
      sortOrder: json['sortOrder'] as int?,
    );
  }

  factory CropModel.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    String requiredText(String field) {
      final value = data[field];

      if (value is! String || value.trim().isEmpty) {
        throw FormatException(
          'Kultura $id nema ispravno polje $field.',
        );
      }

      return value;
    }

    final growthDays = data['growthDays'];

    if (growthDays is! int) {
      throw FormatException(
        'Kultura $id nema ispravno polje growthDays.',
      );
    }

    final imageValue = data['imageUrl'];
    final orderValue = data['sortOrder'];

    return CropModel(
      id: id,
      name: requiredText('name'),
      description: requiredText('description'),
      plantingPeriod: requiredText('plantingPeriod'),
      growingConditions: requiredText('growingConditions'),
      growingDurationDays: growthDays,
      waterNeeds: requiredText('waterRequirement'),
      imageUrl: imageValue is String && imageValue.trim().isNotEmpty
          ? imageValue
          : null,
      sortOrder: orderValue is int ? orderValue : null,
    );
  }
}
