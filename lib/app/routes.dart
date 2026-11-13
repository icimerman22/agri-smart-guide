import 'package:flutter/material.dart';
import '../features/auth/domain/auth_service.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/profile/domain/profile_repository.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> routes(
    AuthService authService,
    ProfileRepository profileRepository,
  ) => {
    login: (context) => LoginScreen(authService: authService),
    register: (context) => RegisterScreen(authService: authService),
    home: (context) => HomeScreen(authService: authService),
    profile: (context) => ProfileScreen(
      authService: authService,
      profileRepository: profileRepository,
    ),
    settings: (context) => SettingsScreen(
      authService: authService,
      profileRepository: profileRepository,
    ),
  };
}
