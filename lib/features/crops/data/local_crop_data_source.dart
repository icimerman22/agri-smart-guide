
import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/models/crop_model.dart';

class LocalCropDataSource {
  final AssetBundle _bundle;

  LocalCropDataSource({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  Future<List<CropModel>> loadCrops() async {
    final jsonString = await _bundle.loadString(
      'assets/data/crops.json',
    );

    final decoded = jsonDecode(jsonString);

    if (decoded is! List) {
      throw const FormatException(
        'Katalog kultura mora sadržavati JSON listu.',
      );
    }

    final crops = decoded.map<CropModel>((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException(
          'Svaka kultura mora biti JSON objekt.',
        );
      }

      return CropModel.fromJson(item);
    }).toList(growable: false);

    final uniqueIds = crops.map((crop) => crop.id).toSet();

    if (uniqueIds.length != crops.length) {
      throw const FormatException(
        'Katalog sadrži duplicirane identifikatore kultura.',
      );
    }

    return crops;
  }
}
