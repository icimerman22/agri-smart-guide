import 'dart:async';

import 'package:flutter/material.dart';

import '../features/auth/domain/auth_service.dart';
import '../features/profile/domain/profile_repository.dart';
import '../features/tasks/domain/task_repository.dart';
import 'routes.dart';
import 'theme/app_theme.dart';

class AgriSmartGuideApp extends StatefulWidget {
  final String initialRoute;
  final AuthService authService;
  final ProfileRepository profileRepository;
  final TaskRepository taskRepository;

  const AgriSmartGuideApp({
    super.key,
    required this.initialRoute,
    required this.authService,
    required this.profileRepository,
    required this.taskRepository,
  });

  @override
  State<AgriSmartGuideApp> createState() => _AgriSmartGuideAppState();
}

class _AgriSmartGuideAppState extends State<AgriSmartGuideApp> {
  late StreamSubscription<AuthUser?> _authSubscription;
  late String? _userId;
  late String _initialRoute;
  int _session = 0;

  @override
  void initState() {
    super.initState();
    _userId = widget.authService.currentUser?.uid;
    _initialRoute = _userId == null && widget.initialRoute != AppRoutes.register
        ? AppRoutes.login
        : widget.initialRoute;
    _watchAuth();
  }

  void _watchAuth() {
    _authSubscription = widget.authService.authStateChanges().listen((user) {
      if (_userId == user?.uid) return;
      setState(() => _startSession(user?.uid));
    });
  }

  void _startSession(String? userId) {
    _userId = userId;
    _initialRoute = userId == null ? AppRoutes.login : AppRoutes.home;
    _session++;
  }

  @override
  void didUpdateWidget(AgriSmartGuideApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authService == widget.authService) return;
    unawaited(_authSubscription.cancel());
    _startSession(widget.authService.currentUser?.uid);
    _watchAuth();
  }

  @override
  void dispose() {
    unawaited(_authSubscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Discard the previous account's routes, dialogs, and data subscriptions.
      key: ValueKey(_session),
      title: 'Agri Smart Guide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      initialRoute: _initialRoute,
      routes: AppRoutes.routes(
        widget.authService,
        widget.profileRepository,
        widget.taskRepository,
      ),
    );
  }
}
