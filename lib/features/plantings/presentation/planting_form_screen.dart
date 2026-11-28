import 'package:flutter/material.dart';

import '../../../shared/widgets/app_button.dart';
import '../../auth/domain/auth_service.dart';
import '../../plots/data/plot_repository.dart';
import '../../plots/domain/plot_model.dart';
import '../domain/planting_repository.dart';
import 'planting_keys.dart';
import 'package:agri_smart_guide/shared/models/crop.dart';
import '../../crops/data/crop_catalog_data_source.dart';

class PlantingFormScreen extends StatefulWidget {
  const PlantingFormScreen({
    super.key,
    required this.authService,
    required this.plotRepository,
    required this.plantingRepository,
    required this.cropDataSource,
    this.today,
  });

  final AuthService authService;
  final PlotRepository plotRepository;
  final PlantingRepository plantingRepository;
  final CropCatalogDataSource cropDataSource;
  final DateTime Function()? today;

  @override
  State<PlantingFormScreen> createState() => _PlantingFormScreenState();
}

class _PlantingFormScreenState extends State<PlantingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();

  late Future<List<Crop>> _cropsFuture;
  Stream<List<Plot>>? _plotsStream;

  List<Crop> _crops = const [];
  List<Plot> _plots = const [];
  String? _selectedCropId;
  String? _selectedParcelId;
  DateTime? _plantedAt;
  bool _isSaving = false;

  DateTime get _today {
    final now = (widget.today ?? DateTime.now)();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _cropsFuture = widget.cropDataSource.loadCrops();
    final user = widget.authService.currentUser;
    if (user != null) {
      _plotsStream = widget.plotRepository.getPlots(user.uid);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void _reloadCrops() {
    setState(() => _cropsFuture = widget.cropDataSource.loadCrops());
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  Future<void> _pickDate() async {
    final today = _today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _plantedAt ?? today,
      firstDate: DateTime(2000),
      lastDate: today,
      helpText: 'Datum sadnje',
    );
    if (picked == null) return;

    setState(() {
      _plantedAt = picked;
      _dateController.text = _formatDate(picked);
    });
    _formKey.currentState?.validate();
  }

  Future<bool> _confirmReplace(Plot plot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Parcela već ima aktivnu sadnju'),
        content: Text(
          'Na parceli "${plot.name}" već postoji aktivna sadnja. '
          'Nova sadnja zamijenit će je, a prethodna će biti označena kao završena.',
        ),
        actions: [
          TextButton(
            key: PlantingKeys.replaceCancel,
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            key: PlantingKeys.replaceConfirm,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Zamijeni'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = widget.authService.currentUser;
    if (user == null) {
      _showMessage('Korisnik nije prijavljen.');
      return;
    }

    final crop = _crops.where((c) => c.id == _selectedCropId).firstOrNull;
    final plot = _plots.where((p) => p.id == _selectedParcelId).firstOrNull;
    final plantedAt = _plantedAt;
    if (crop == null || plot == null || plantedAt == null) return;

    if (plot.activePlantingId != null) {
      final confirmed = await _confirmReplace(plot);
      if (!confirmed || !mounted) return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.plantingRepository.addPlanting(
        ownerId: user.uid,
        parcelId: plot.id,
        cropId: crop.id,
        plantedAt: plantedAt,
        growingDurationDays: crop.growthDays,
      );
      if (!mounted) return;

      _showMessage(
        'Sadnja kulture ${crop.name} na parceli ${plot.name} je evidentirana.',
      );
      Navigator.pop(context);
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

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            key: PlantingKeys.cropField,
            initialValue: _selectedCropId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Kultura *'),
            items: [
              for (final crop in _crops)
                DropdownMenuItem(value: crop.id, child: Text(crop.name)),
            ],
            onChanged: _isSaving
                ? null
                : (value) => setState(() => _selectedCropId = value),
            validator: (value) => value == null ? 'Odaberite kulturu' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: PlantingKeys.parcelField,
            initialValue: _selectedParcelId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Parcela *'),
            items: [
              for (final plot in _plots)
                DropdownMenuItem(value: plot.id, child: Text(plot.name)),
            ],
            onChanged: _isSaving
                ? null
                : (value) => setState(() => _selectedParcelId = value),
            validator: (value) => value == null ? 'Odaberite parcelu' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: PlantingKeys.dateField,
            controller: _dateController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Datum sadnje *',
              suffixIcon: Icon(Icons.calendar_today_outlined),
            ),
            onTap: _isSaving ? null : _pickDate,
            validator: (value) {
              final date = _plantedAt;
              if (date == null) return 'Odaberite datum sadnje';
              if (date.isAfter(_today)) {
                return 'Datum sadnje ne može biti u budućnosti';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          AppButton(
            key: PlantingKeys.save,
            text: _isSaving ? 'Spremanje...' : 'Evidentiraj sadnju',
            icon: Icons.check,
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
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
        _crops = cropsSnapshot.data ?? const [];

        return StreamBuilder<List<Plot>>(
          stream: plotsStream,
          builder: (context, plotsSnapshot) {
            if (plotsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                key: PlantingKeys.loading,
                child: CircularProgressIndicator(),
              );
            }
            if (plotsSnapshot.hasError) {
              return Center(
                key: PlantingKeys.error,
                child: Text('Došlo je do pogreške: ${plotsSnapshot.error}'),
              );
            }
            _plots = plotsSnapshot.data ?? const [];

            if (_plots.isEmpty) {
              return const Center(
                key: PlantingKeys.noParcels,
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Nemate dodanih parcela. Prvo dodajte parcelu kako biste '
                    'mogli evidentirati sadnju.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return _buildForm();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evidentiraj sadnju')),
      body: _buildBody(),
    );
  }
}
