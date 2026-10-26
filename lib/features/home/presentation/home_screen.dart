import 'package:flutter/material.dart';

import '../../../app/routes.dart';

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
            const Text('Dobrodošli u Agri Smart Guide!'),
            const Text('Demonstracijski početni zaslon'),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
              child: const Text('Povratak na prijavu'),
            ),
          ],
        ),
      ),
    );
  }
}
