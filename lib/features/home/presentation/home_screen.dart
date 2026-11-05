import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/domain/auth_service.dart';
import '../../auth/presentation/auth_keys.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.authService});

  final AuthService authService;

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await authService.signOut();

      if (!context.mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Greška prilikom odjave: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agri Smart Guide'),
        actions: [
          IconButton(
            key: AuthKeys.logoutIcon,
            icon: const Icon(Icons.logout),
            tooltip: 'Odjava',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
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
