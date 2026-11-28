import 'package:agri_smart_guide/features/crops/data/crop_catalog_data_source.dart';
import 'package:agri_smart_guide/shared/models/crop.dart';

class FakeCropCatalogDataSource implements CropCatalogDataSource {
  @override
  Future<List<Crop>> loadCrops() async {
    return [
      Crop(
        id: 'tomato',
        name: 'Rajčica',
        category: 'plodovito povrće',
        description: 'Povrtna kultura',
        sowingMonths: [3, 4, 5],
        growthDays: 90,
        waterRequirement: 'Redovito zalijevanje',
        rowSpacingCm: 70.0,
        plantSpacingCm: 40.0,
        optimalPhMin: 6.0,
        optimalPhMax: 7.0,
        plantingPeriod: 'Proljeće',
        growingConditions: 'Sunčan položaj',
      ),
      Crop(
        id: 'lettuce',
        name: 'Salata',
        category: 'lisnato povrće',
        description: 'Lisnata kultura',
        sowingMonths: [3, 4, 5],
        growthDays: 50,
        waterRequirement: 'Redovito zalijevanje',
        rowSpacingCm: 30.0,
        plantSpacingCm: 25.0,
        optimalPhMin: 6.0,
        optimalPhMax: 7.0,
        plantingPeriod: 'Proljeće',
        growingConditions: 'Umjerene temperature',
      ),
      Crop(
        id: 'sunflower',
        name: 'Suncokret',
        category: 'uljarica',
        description: 'Uljana kultura',
        sowingMonths: [4, 5],
        growthDays: 110,
        waterRequirement: 'Umjereno zalijevanje',
        rowSpacingCm: 70.0,
        plantSpacingCm: 25.0,
        optimalPhMin: 6.0,
        optimalPhMax: 7.0,
        plantingPeriod: 'Proljeće',
        growingConditions: 'Sunčan položaj',
      ),
    ];
  }
}
