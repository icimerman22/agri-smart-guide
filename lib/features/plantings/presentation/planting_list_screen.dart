import 'package:flutter/material.dart';

import '../../../shared/models/planting.dart';
import '../../auth/domain/auth_service.dart';
import '../../crops/data/local_crop_data_source.dart';
import '../../crops/domain/models/crop_model.dart';
import '../../plots/data/plot_repository.dart';
import '../../plots/domain/plot_model.dart';
import '../domain/planting_formatters.dart';
import '../domain/planting_repository.dart';
import '../domain/planting_stage.dart';
import 'planting_detail_screen.dart';
import 'planting_keys.dart';

class PlantingListScreen extends StatefulWidget {
  const PlantingListScreen({
    super.key,
    required this.authService,
    required this.plotRepository,
    required this.plantingRepository,
    required this.cropDataSource,
  });

  final AuthService authService;
  final PlotRepository plotRepository;
  final PlantingRepository plantingRepository;
  final LocalCropDataSource cropDataSource;

  @override
  State<PlantingListScreen> createState() => _PlantingListScreenState();
}

class _PlantingListScreenState extends State<PlantingListScreen> {
  late Future<List<CropModel>> _cropsFuture;
  Stream<List<Planting>>? _plantingsStream;
  Stream<List<Plot>>? _plotsStream;

  @override
  void initState() {
    super.initState();
    _cropsFuture = widget.cropDataSource.loadCrops();
    final user = widget.authService.currentUser;
    if (user != null) {
      _plantingsStream = widget.plantingRepository.watchPlantings(user.uid);
      _plotsStream = widget.plotRepository.getPlots(user.uid);
    }
  }

  void _reloadCrops() {
    setState(() => _cropsFuture = widget.cropDataSource.loadCrops());
  }

  void _openDetail(Planting planting) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlantingDetailScreen(
          plantingId: planting.id,
          authService: widget.authService,
          plotRepository: widget.plotRepository,
          plantingRepository: widget.plantingRepository,
          cropDataSource: widget.cropDataSource,
        ),
      ),
    );
  }

  Widget _buildList(
    List<Planting> plantings,
    Map<String, CropModel> crops,
    Map<String, Plot> plots,
  ) {
    if (plantings.isEmpty) {
      return const Center(
        key: PlantingKeys.listEmpty,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nemate evidentiranih posađenih kultura.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final sorted = [...plantings]
      ..sort((a, b) => b.plantedAt.compareTo(a.plantedAt));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final planting = sorted[index];
        final cropName = crops[planting.cropId]?.name ?? planting.cropId;
        final parcelName = plots[planting.parcelId]?.name ?? 'Nepoznata parcela';
        return Card(
          key: PlantingKeys.listItem(planting.id),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.eco, color: Colors.white),
            ),
            title: Text(
              cropName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '$parcelName • ${formatPlantingDate(planting.plantedAt.toDate())}\n'
              '${PlantingStage.labelOf(planting.stage)} • '
              '${PlantingStatus.labelOf(planting.status)}',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _openDetail(planting),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    final plantingsStream = _plantingsStream;
    final plotsStream = _plotsStream;
    if (plantingsStream == null || plotsStream == null) {
      return const Center(child: Text('Korisnik nije prijavljen.'));
    }

    return FutureBuilder<List<CropModel>>(
      future: _cropsFuture,
      builder: (context, cropsSnapshot) {
        if (cropsSnapshot.connectionState != ConnectionState.done) {
          return const Center(
            key: PlantingKeys.loading,
            child: CircularProgressIndicator(),
          );
        }
        if (cropsSnapshot.hasError) {
          return Center(
            key: PlantingKeys.error,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Katalog kultura nije moguće učitati.'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _reloadCrops,
                  child: const Text('Pokušaj ponovno'),
                ),
              ],
            ),
          );
        }
        final crops = {for (final c in cropsSnapshot.data ?? <CropModel>[]) c.id: c};

        return StreamBuilder<List<Plot>>(
          stream: plotsStream,
          builder: (context, plotsSnapshot) {
            if (plotsSnapshot.hasError) {
              return Center(
                key: PlantingKeys.error,
                child: Text('Došlo je do pogreške: ${plotsSnapshot.error}'),
              );
            }
            if (!plotsSnapshot.hasData) {
              return const Center(
                key: PlantingKeys.loading,
                child: CircularProgressIndicator(),
              );
            }
            final plots = {for (final p in plotsSnapshot.data!) p.id: p};

            return StreamBuilder<List<Planting>>(
              stream: plantingsStream,
              builder: (context, plantingsSnapshot) {
                if (plantingsSnapshot.hasError) {
                  return Center(
                    key: PlantingKeys.error,
                    child: Text(
                      'Došlo je do pogreške: ${plantingsSnapshot.error}',
                    ),
                  );
                }
                if (!plantingsSnapshot.hasData) {
                  return const Center(
                    key: PlantingKeys.loading,
                    child: CircularProgressIndicator(),
                  );
                }
                return _buildList(plantingsSnapshot.data!, crops, plots);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moje posađene kulture')),
      body: _buildBody(),
    );
  }
}
