import 'package:flutter/material.dart';

import '../../../shared/widgets/app_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            Text(
              'Dobrodošli u Agri Smart Guide!',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            Text(
              'Demonstracijski početni zaslon',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            AppButton(
              text: 'Povratak na prijavu',
              variant: AppButtonVariant.secondary,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
