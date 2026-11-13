import 'package:flutter/material.dart';

import '../features/auth/domain/auth_service.dart';
import '../features/profile/domain/profile_repository.dart';
import 'routes.dart';
import 'theme/app_theme.dart';

class AgriSmartGuideApp extends StatelessWidget {
  final String initialRoute;
  final AuthService authService;
  final ProfileRepository profileRepository;

  const AgriSmartGuideApp({
    super.key,
    required this.initialRoute,
    required this.authService,
    required this.profileRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agri Smart Guide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      initialRoute: initialRoute,
      routes: AppRoutes.routes(authService, profileRepository),
    );
  }
}
