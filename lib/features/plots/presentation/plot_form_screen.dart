import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../auth/domain/auth_service.dart';
import '../data/plot_repository.dart';
import '../domain/plot_model.dart';

class PlotFormScreen extends StatefulWidget {
  const PlotFormScreen({
    super.key,
    required this.authService,
    required this.plotRepository,
    this.plotToEdit,
  });

  final AuthService authService;
  final PlotRepository plotRepository;
  final Plot? plotToEdit; // Ako je null, dodajemo novu; ako postoji, uređujemo je

  @override
  State<PlotFormScreen> createState() => _PlotFormScreenState();
}

class _PlotFormScreenState extends State<PlotFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _locationNameController;
  late TextEditingController _areaHaController;
  late TextEditingController _soilTypeController;
  late TextEditingController _latController;
  late TextEditingController _lngController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final plot = widget.plotToEdit;
    _nameController = TextEditingController(text: plot?.name ?? '');
    _locationNameController = TextEditingController(text: plot?.locationName ?? '');
    _areaHaController = TextEditingController(text: plot?.areaHa != null ? plot!.areaHa.toString() : '');
    _soilTypeController = TextEditingController(text: plot?.soilType ?? '');
    _latController = TextEditingController(text: plot?.coordinates.latitude.toString() ?? '45.815');
    _lngController = TextEditingController(text: plot?.coordinates.longitude.toString() ?? '15.981');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationNameController.dispose();
    _areaHaController.dispose();
    _soilTypeController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _savePlot() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = widget.authService.currentUser;
      if (user == null) return;

      final name = _nameController.text.trim();
      final locationName = _locationNameController.text.trim();
      final areaHa = double.parse(_areaHaController.text.trim());
      final soilType = _soilTypeController.text.trim();
      final lat = double.parse(_latController.text.trim());
      final lng = double.parse(_lngController.text.trim());
      final coordinates = GeoPoint(lat, lng);

      if (widget.plotToEdit == null) {
        // Kreiranje nove parcele
        final newPlot = Plot(
          id: '',
          ownerId: user.uid,
          name: name,
          areaHa: areaHa,
          soilType: soilType,
          locationName: locationName,
          coordinates: coordinates,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        );
        await widget.plotRepository.addPlot(newPlot);
      } else {
        // Ažuriranje postojeće parcele
        final updatedPlot = Plot(
          id: widget.plotToEdit!.id,
          ownerId: widget.plotToEdit!.ownerId,
          name: name,
          areaHa: areaHa,
          soilType: soilType,
          locationName: locationName,
          coordinates: coordinates,
          activePlantingId: widget.plotToEdit!.activePlantingId,
          createdAt: widget.plotToEdit!.createdAt,
          updatedAt: Timestamp.now(),
        );
        await widget.plotRepository.updatePlot(updatedPlot);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška prilikom spremanja: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.plotToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Uredi parcelu' : 'Nova parcela'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
            TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Naziv parcele / vrta *'),
            validator: (value) => value == null || value.isEmpty ? 'Unesite naziv parcele' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _locationNameController,
            decoration: const InputDecoration(labelText: 'Naziv lokacije / adresa *'),
            validator: (value) => value == null || value.isEmpty ? 'Unesite lokaciju' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _areaHaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Površina (u hektarima - ha) *'),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Unesite površinu';
              if (double.tryParse(value) == null) return 'Unesite valjani broj';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _soilTypeController,
            decoration: const InputDecoration(labelText: 'Tip tla (npr. glinasto, pjeskovito) *'),
            validator: (value) => value == null || value.isEmpty ? 'Unesite tip tla' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _latController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Geografska širina (Lat)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lngController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Geografska dužina (Lng)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _savePlot,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(isEditing ? 'Spremi promjene' : 'Dodaj parcelu'),
              ),
        ],
      ),
    ),
    ),
    );
  }
}