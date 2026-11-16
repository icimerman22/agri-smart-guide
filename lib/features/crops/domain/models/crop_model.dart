class CropModel {
  final String id;
  final String name;
  final String description;
  final String plantingPeriod;
  final String growingConditions;
  final int growingDurationDays;
  final String waterNeeds;
  final String? imagePath;

  const CropModel({
    required this.id,
    required this.name,
    required this.description,
    required this.plantingPeriod,
    required this.growingConditions,
    required this.growingDurationDays,
    required this.waterNeeds,
    this.imagePath,
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
    );
  }
}
