import 'package:flutter/material.dart';
import '../../auth/domain/auth_service.dart';
import '../data/plot_repository.dart';
import '../domain/plot_model.dart';
import 'plot_form_screen.dart';

class PlotDetailScreen extends StatelessWidget {
  const PlotDetailScreen({
    super.key,
    required this.plot,
    required this.authService,
    required this.plotRepository,
  });

  final Plot plot;
  final AuthService authService;
  final PlotRepository plotRepository;

  Future<void> _confirmAndDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Brisanje parcele'),
        content: Text('Jeste li sigurni da želite obrisati parcelu "${plot.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await plotRepository.deletePlot(plot.id);
      if (!context.mounted) return;
      Navigator.pop(context); // Vraća s ekrana detalja na listu
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(plot.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Uredi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlotFormScreen(
                    authService: authService,
                    plotRepository: plotRepository,
                    plotToEdit: plot,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Obriši',
            onPressed: () => _confirmAndDelete(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalji parcele',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildDetailRow(Icons.location_on, 'Lokacija', plot.locationName),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.straighten, 'Površina', '${plot.areaHa} ha'),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.terrain, 'Tip tla', plot.soilType),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.map,
              'Koordinate',
              'Lat: ${plot.coordinates.latitude}, Lng: ${plot.coordinates.longitude}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.green.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}