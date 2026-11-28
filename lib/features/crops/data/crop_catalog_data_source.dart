import 'package:agri_smart_guide/shared/models/crop.dart';


abstract class CropCatalogDataSource {
  Future<List<Crop>> loadCrops();
}