import 'package:flutter/material.dart';
import '../../auth/domain/auth_service.dart';
import '../data/plot_repository.dart';
import '../domain/plot_model.dart';
import 'plot_detail_screen.dart';

class PlotListScreen extends StatelessWidget {
  const PlotListScreen({
    super.key,
    required this.authService,
    required this.plotRepository,
  });

  final AuthService authService;
  final PlotRepository plotRepository;

  @override
  Widget build(BuildContext context) {
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Korisnik nije prijavljen.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje parcele'),
      ),
      body: StreamBuilder<List<Plot>>(
        stream: plotRepository.getPlots(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Došlo je do pogreške: ${snapshot.error}'));
          }

          final plots = snapshot.data ?? [];

          if (plots.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.eco_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Nemate još dodanih parcela.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: plots.length,
            itemBuilder: (context, index) {
              final plot = plots[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.grass, color: Colors.white),
                  ),
                  title: Text(
                    plot.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${plot.locationName} • ${plot.areaHa} ha',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlotDetailScreen(plot: plot),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}