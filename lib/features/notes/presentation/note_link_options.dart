import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/models/crop.dart';
import '../../crops/data/crop_catalog_data_source.dart';
import '../../plots/data/plot_repository.dart';
import '../../plots/domain/plot_model.dart';

class NoteLinkOptions extends ChangeNotifier {
  NoteLinkOptions({
    required String ownerId,
    required PlotRepository plotRepository,
    required CropCatalogDataSource cropDataSource,
  }) {
    _plotSubscription = plotRepository
        .getPlots(ownerId)
        .listen(
          (plots) => _update(() {
            _plots = List.unmodifiable(plots);
            _plotsLoaded = true;
          }),
          onError: (Object _) => _update(() => _plotsFailed = true),
        );
    cropDataSource.loadCrops().then(
      (crops) => _update(() {
        _crops = List.unmodifiable(crops);
        _cropsLoaded = true;
      }),
      onError: (Object _) => _update(() => _cropsFailed = true),
    );
  }

  late final StreamSubscription<List<Plot>> _plotSubscription;
  bool _disposed = false;

  List<Plot> _plots = const [];
  List<Crop> _crops = const [];
  bool _plotsLoaded = false;
  bool _cropsLoaded = false;
  bool _plotsFailed = false;
  bool _cropsFailed = false;

  List<Plot> get plots => _plots;
  List<Crop> get crops => _crops;
  bool get plotsLoaded => _plotsLoaded;
  bool get cropsLoaded => _cropsLoaded;
  bool get plotsFailed => _plotsFailed;
  bool get cropsFailed => _cropsFailed;

  String? parcelLabel(String? parcelId) {
    if (parcelId == null) return null;
    for (final plot in _plots) {
      if (plot.id == parcelId) return plot.name;
    }
    return _plotsLoaded ? 'Obrisana parcela' : null;
  }

  String? cropLabel(String? cropId) {
    if (cropId == null) return null;
    for (final crop in _crops) {
      if (crop.id == cropId) return crop.name;
    }
    return _cropsLoaded ? 'Nepoznata kultura' : null;
  }

  void _update(VoidCallback change) {
    if (_disposed) return;
    change();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_plotSubscription.cancel());
    super.dispose();
  }
}
