import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/domain/auth_service.dart';
import '../../profile/domain/farm_location.dart';
import '../../profile/domain/profile_repository.dart';
import '../../profile/domain/settings_defaults.dart';
import '../../profile/presentation/location_picker.dart';
import 'settings_keys.dart';

/// Notification types shown on S06, keyed as in
/// `users/{uid}.notificationSettings`.
const notificationTypes = <String, String>{
  'taskDeadlines': 'Rokovi zadataka',
  'weatherAlerts': 'Vremenska upozorenja (mraz, suša)',
  'recommendations': 'Preporuke (navodnjavanje, zaštita)',
  'dayBeforeReminder': 'Podsjetnik dan ranije',
};

/// Values for `users/{uid}.unitSystem`.
const unitSystems = <String, String>{
  'metric': 'Metričke (°C, mm, ha)',
  'imperial': 'Imperijalne (°F, in, ac)',
};

/// S06 Postavke: notification switches, primary location and units.
/// Every change is saved immediately.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.authService,
    required this.profileRepository,
  });

  final AuthService authService;
  final ProfileRepository profileRepository;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoggingOut = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = widget.authService.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Niste prijavljeni.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await widget.profileRepository.loadProfile(user.uid);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } on ProfileException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Postavke nije moguće učitati. Provjerite vezu.';
      });
    }
  }

  /// Shows the change at once and saves it; restores the previous value if
  /// saving fails.
  Future<void> _save(UserProfile updated) async {
    final previous = _profile;
    if (_isSaving || previous == null) return;

    setState(() {
      _profile = updated;
      _isSaving = true;
    });
    final messenger = ScaffoldMessenger.of(context);

    try {
      final saved = await widget.profileRepository.saveProfile(updated);
      if (!mounted) return;
      setState(() {
        _profile = saved;
        _isSaving = false;
      });
    } on ProfileException {
      if (!mounted) return;
      setState(() {
        _profile = previous;
        _isSaving = false;
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Promjenu nije moguće spremiti. Pokušajte ponovno.'),
        ),
      );
    }
  }

  void _setNotification(String type, bool enabled) {
    final profile = _profile!;
    _save(
      profile.copyWith(
        notificationSettings: {
          ...SettingsDefaults.completeNotifications(
            profile.notificationSettings,
          ),
          type: enabled,
        },
      ),
    );
  }

  /// Signs out and clears the navigation stack so the user cannot go back
  /// to protected screens.
  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await widget.authService.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    } on AuthException {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Odjava nije uspjela. Pokušajte ponovno.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Postavke')),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(key: SettingsKeys.loading),
      );
    }

    final errorMessage = _errorMessage;
    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                errorMessage,
                key: SettingsKeys.error,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (widget.authService.currentUser != null)
                AppButton(
                  key: SettingsKeys.retry,
                  text: 'Pokušaj ponovno',
                  variant: AppButtonVariant.secondary,
                  onPressed: _loadProfile,
                ),
            ],
          ),
        ),
      );
    }

    final profile = _profile!;
    final textTheme = Theme.of(context).textTheme;
    final unitSystem = unitSystems.containsKey(profile.unitSystem)
        ? profile.unitSystem
        : SettingsDefaults.unitSystem;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('Obavijesti', style: textTheme.titleMedium),
        ),
        for (final entry in notificationTypes.entries)
          SwitchListTile(
            key: SettingsKeys.notification(entry.key),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            title: Text(entry.value),
            value: SettingsDefaults.isNotificationEnabled(
              profile.notificationSettings,
              entry.key,
            ),
            onChanged: _isSaving
                ? null
                : (enabled) => _setNotification(entry.key, enabled),
          ),
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Općenito', style: textTheme.titleMedium),
              const SizedBox(height: 12),
              LocationPicker(
                value: FarmLocation.fromMap(profile.primaryLocation),
                enabled: !_isSaving,
                onChanged: (location) =>
                    _save(profile.copyWith(primaryLocation: location.toMap())),
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Mjerne jedinice',
                  prefixIcon: Icon(Icons.straighten),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    key: SettingsKeys.unitSystem,
                    value: unitSystem,
                    isExpanded: true,
                    isDense: true,
                    items: [
                      for (final entry in unitSystems.entries)
                        DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            if (value != null && value != unitSystem) {
                              _save(profile.copyWith(unitSystem: value));
                            }
                          },
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AppButton(
            key: SettingsKeys.logout,
            text: _isLoggingOut ? 'Odjava...' : 'Odjava',
            icon: Icons.logout,
            variant: AppButtonVariant.secondary,
            onPressed: _isLoggingOut ? null : _logout,
          ),
        ),
      ],
    );
  }
}
