import 'package:flutter/material.dart';

import 'routes.dart';

class AgriSmartGuideApp extends StatelessWidget {
  const AgriSmartGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agri Smart Guide',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}
