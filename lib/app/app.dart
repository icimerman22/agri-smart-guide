import 'package:flutter/material.dart';

import 'routes.dart';
import 'theme/app_theme.dart';

class AgriSmartGuideApp extends StatelessWidget {
  const AgriSmartGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agri Smart Guide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}
