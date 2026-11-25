import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/domain/auth_service.dart';
import '../../auth/presentation/auth_keys.dart';
import '../../profile/presentation/profile_keys.dart';
import '../../crops/presentation/crop_catalog_screen.dart';
import '../../crops/data/local_crop_data_source.dart';
import '../../plantings/data/firestore_planting_repository.dart';
import '../../plantings/presentation/planting_keys.dart';
import '../../plantings/presentation/planting_list_screen.dart';
import '../../plots/data/plot_repository.dart';
import '../../plots/presentation/plot_list_screen.dart';
import '../../tasks/domain/task_repository.dart';
import '../../tasks/presentation/task_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.authService,
    required this.taskRepository,
  });

  final AuthService authService;
  final TaskRepository taskRepository;

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await authService.signOut();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Greška prilikom odjave: $e')));
    }
  }

  void _openCropCatalog(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CropCatalogScreen()));
  }

  void _openPlotList(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlotListScreen(
          authService: authService,
          plotRepository: PlotRepository(),
        ),
      ),
    );
  }

  void _openPlantingList(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlantingListScreen(
          authService: authService,
          plotRepository: PlotRepository(),
          plantingRepository: FirestorePlantingRepository(),
          cropDataSource: LocalCropDataSource(),
        ),
      ),
    );
  }

  void _openTaskList(BuildContext context, String ownerId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskListScreen(
          authService: authService,
          ownerId: ownerId,
          repository: taskRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agri Smart Guide'),
        actions: [
          IconButton(
            key: ProfileKeys.openProfile,
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profil',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          IconButton(
            key: AuthKeys.logoutIcon,
            icon: const Icon(Icons.logout),
            tooltip: 'Odjava',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Dobrodošli u Agri Smart Guide!',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Demonstracijski početni zaslon',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Prijavljeni ste kao:\n${user?.email ?? 'Nepoznati korisnik'}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              AppButton(
                text: 'Katalog kultura',
                onPressed: () => _openCropCatalog(context),
              ),

              const SizedBox(height: 12),

              AppButton(
                text: 'Moje parcele',
                onPressed: () => _openPlotList(context),
              ),

              const SizedBox(height: 12),

              AppButton(
                key: PlantingKeys.openPlantingList,
                text: 'Moje sadnje',
                onPressed: () => _openPlantingList(context),
              ),

              const SizedBox(height: 12),

              AppButton(
                text: 'Zadaci',
                onPressed: user == null
                    ? null
                    : () => _openTaskList(context, user.uid),
              ),

              const SizedBox(height: 12),
              AppButton(
                key: AuthKeys.logout,
                text: 'Odjavi se',
                variant: AppButtonVariant.secondary,
                onPressed: () => _handleLogout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
