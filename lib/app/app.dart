import 'package:flutter/material.dart';

import 'routes.dart';
import 'theme/app_theme.dart';

class AgriSmartGuideApp extends StatelessWidget {
  final String initialRoute;

  const AgriSmartGuideApp({
    super.key,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agri Smart Guide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      initialRoute: initialRoute,
      routes: AppRoutes.routes,
    );
  }
}