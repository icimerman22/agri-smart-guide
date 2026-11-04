import 'package:flutter/material.dart';
import '../features/auth/domain/auth_service.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/home/presentation/home_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';

  static Map<String, WidgetBuilder> routes(AuthService authService) => {
    login: (context) => LoginScreen(authService: authService),
    register: (context) => RegisterScreen(authService: authService),
    home: (context) => HomeScreen(authService: authService),
  };
}
