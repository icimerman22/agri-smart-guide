import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../shared/widgets/app_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agri Smart Guide'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Prijava'),
            AppButton(
              text: 'Registracija',
              variant: AppButtonVariant.secondary,
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.register);
              },
            ),
            AppButton(
              text: 'Nastavi na početnu (demo)',
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.home);
              },
            ),
          ],
        ),
      ),
    );
  }
}
