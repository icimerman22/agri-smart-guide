
import 'package:agri_smart_guide/shared/models/crop.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'crop_catalog_data_source.dart';

class FirestoreCropDataSource implements CropCatalogDataSource {
  final FirebaseFirestore _firestore;

  FirestoreCropDataSource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Crop>> loadCrops() async {
    final snapshot =
    await _firestore.collection('crops').get();

    final crops = snapshot.docs
        .map((document) => Crop.fromFirestore(document))
        .toList();

    crops.sort((a, b) {
      final orderComparison =
      (a.sortOrder ?? 999999).compareTo(b.sortOrder ?? 999999);

      return orderComparison != 0
          ? orderComparison
          : a.name.compareTo(b.name);
    });

    return crops;
  }
}
