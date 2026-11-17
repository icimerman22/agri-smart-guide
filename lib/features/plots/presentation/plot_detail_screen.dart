import 'package:flutter/material.dart';
import '../domain/plot_model.dart';

class PlotDetailScreen extends StatelessWidget {
  const PlotDetailScreen({super.key, required this.plot});

  final Plot plot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(plot.name),
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