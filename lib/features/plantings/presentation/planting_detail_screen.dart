import 'package:flutter/material.dart';

import '../../../shared/models/planting.dart';
import '../../auth/domain/auth_service.dart';
import 'package:agri_smart_guide/shared/models/crop.dart';
import '../../crops/data/crop_catalog_data_source.dart';
import '../../plots/data/plot_repository.dart';
import '../../plots/domain/plot_model.dart';
import '../domain/planting_formatters.dart';
import '../domain/planting_repository.dart';
import '../domain/planting_stage.dart';
import 'planting_keys.dart';

class PlantingDetailScreen extends StatefulWidget {
  const PlantingDetailScreen({
    super.key,
    required this.plantingId,
    required this.authService,
    required this.plotRepository,
    required this.plantingRepository,
    required this.cropDataSource,
  });

  final String plantingId;
  final AuthService authService;
  final PlotRepository plotRepository;
  final PlantingRepository plantingRepository;
  final CropCatalogDataSource cropDataSource;

  @override
  State<PlantingDetailScreen> createState() => _PlantingDetailScreenState();
}

class _PlantingDetailScreenState extends State<PlantingDetailScreen> {
  late final Future<List<Crop>> _cropsFuture;
  late final Stream<Planting?> _plantingStream;
  Stream<List<Plot>>? _plotsStream;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cropsFuture = widget.cropDataSource.loadCrops();
    _plantingStream = widget.plantingRepository.watchPlanting(widget.plantingId);
    final user = widget.authService.currentUser;
    if (user != null) {
      _plotsStream = widget.plotRepository.getPlots(user.uid);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(Future<void> Function(String ownerId) action, String success) async {
    final user = widget.authService.currentUser;
    if (user == null) {
      _showMessage('Korisnik nije prijavljen.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await action(user.uid);
      if (!mounted) return;
      _showMessage(success);
    } on PlantingException catch (e) {
      if (!mounted) return;
      _showMessage(e.toString());
    } catch (e) {
      if (!mounted) return;
      _showMessage('Greška prilikom spremanja: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changeStage(String stage) {
    return _run(
      (ownerId) => widget.plantingRepository.updateStage(
        ownerId: ownerId,
        plantingId: widget.plantingId,
        stage: stage,
      ),
      'Razvojna faza je ažurirana.',
    );
  }

  Future<void> _changeStatus(bool active) {
    final status = active ? PlantingStatus.active : PlantingStatus.completed;
    return _run(
      (ownerId) => widget.plantingRepository.updateStatus(
        ownerId: ownerId,
        plantingId: widget.plantingId,
        status: status,
      ),
      'Status uzgoja je ažuriran.',
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildDetails(
    Planting planting,
    Map<String, Crop> crops,
    Map<String, Plot> plots,
  ) {
    final cropName = crops[planting.cropId]?.name ?? planting.cropId;
    final parcelName = plots[planting.parcelId]?.name ?? 'Nepoznata parcela';
    final knownStage = PlantingStage.fromKey(planting.stage);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _row('Kultura', cropName),
        _row('Parcela', parcelName),
        _row('Datum sadnje', formatPlantingDate(planting.plantedAt.toDate())),
        _row(
          'Očekivana berba',
          formatPlantingDate(planting.expectedHarvestAt.toDate()),
        ),
        _row('Sezona', planting.seasonYear.toString()),
        const SizedBox(height: 16),
        DropdownButtonFormField<PlantingStage>(
          key: PlantingKeys.stageField,
          initialValue: knownStage,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Razvojna faza'),
          items: [
            for (final stage in PlantingStage.values)
              DropdownMenuItem(value: stage, child: Text(stage.label)),
          ],
          onChanged: _isSaving
              ? null
              : (stage) {
                  if (stage != null && stage != knownStage) {
                    _changeStage(stage.key);
                  }
                },
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          key: PlantingKeys.statusSwitch,
          contentPadding: EdgeInsets.zero,
          title: const Text('Uzgoj je aktivan'),
          subtitle: Text(PlantingStatus.labelOf(planting.status)),
          value: planting.status == PlantingStatus.active,
          onChanged: _isSaving ? null : _changeStatus,
        ),
      ],
    );
  }

  Widget _buildBody() {
    final plotsStream = _plotsStream;
    if (plotsStream == null) {
      return const Center(child: Text('Korisnik nije prijavljen.'));
    }

    return FutureBuilder<List<Crop>>(
      future: _cropsFuture,
      builder: (context, cropsSnapshot) {
        final crops = {
          for (final c in cropsSnapshot.data ?? <Crop>[]) c.id: c,
        };

        return StreamBuilder<List<Plot>>(
          stream: plotsStream,
          builder: (context, plotsSnapshot) {
            final plots = {
              for (final p in plotsSnapshot.data ?? <Plot>[]) p.id: p,
            };

            return StreamBuilder<Planting?>(
              stream: _plantingStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    key: PlantingKeys.error,
                    child: Text('Došlo je do pogreške: ${snapshot.error}'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    key: PlantingKeys.loading,
                    child: CircularProgressIndicator(),
                  );
                }
                final planting = snapshot.data;
                if (planting == null) {
                  return const Center(
                    key: PlantingKeys.detailNotFound,
                    child: Text('Sadnja nije pronađena.'),
                  );
                }
                return _buildDetails(planting, crops, plots);
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
      appBar: AppBar(title: const Text('Detalji sadnje')),
      body: _buildBody(),
    );
  }
}
