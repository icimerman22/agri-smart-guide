import 'package:flutter/material.dart';

import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/domain/auth_service.dart';
import '../domain/profile_repository.dart';
import '../domain/profile_validators.dart';
import 'profile_keys.dart';

/// S05 Profile: shows the signed-in user's personal data.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.authService,
    required this.profileRepository,
  });

  final AuthService authService;
  final ProfileRepository profileRepository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _farmNameController = TextEditingController();

  UserProfile? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _farmNameController.dispose();
    super.dispose();
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
      _firstNameController.text = profile.firstName;
      _lastNameController.text = profile.lastName;
      _emailController.text = user.email ?? '';
      _farmNameController.text = profile.farmName;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } on ProfileException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Profil nije moguće učitati. Provjerite vezu.';
      });
    }
  }

  Future<void> _saveProfile() async {
    final profile = _profile;
    if (_isSaving || profile == null) return;

    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final saved = await widget.profileRepository.saveProfile(
        profile.copyWith(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          farmName: _farmNameController.text.trim(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _profile = saved;
        _isSaving = false;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Promjene su uspješno spremljene.')),
      );
    } on ProfileException {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Promjene nije moguće spremiti. Pokušajte ponovno.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(key: ProfileKeys.loading),
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
                key: ProfileKeys.error,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (widget.authService.currentUser != null)
                AppButton(
                  key: ProfileKeys.retry,
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
    final fullName = '${profile.firstName} ${profile.lastName}'.trim();
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AppCard(
          key: ProfileKeys.header,
          child: Row(
            children: [
              const CircleAvatar(radius: 28, child: Icon(Icons.person)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isEmpty ? 'Profil nije dovršen' : fullName,
                      style: textTheme.titleMedium,
                    ),
                    Text(_emailController.text, style: textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Osobni podaci', style: textTheme.titleMedium),
              const SizedBox(height: 12),
              AppTextField(
                key: ProfileKeys.firstName,
                labelText: 'Ime',
                controller: _firstNameController,
                validator: ProfileValidators.firstName,
                enabled: !_isSaving,
              ),
              const SizedBox(height: 12),
              AppTextField(
                key: ProfileKeys.lastName,
                labelText: 'Prezime',
                controller: _lastNameController,
                validator: ProfileValidators.lastName,
                enabled: !_isSaving,
              ),
              const SizedBox(height: 12),
              AppTextField(
                key: ProfileKeys.email,
                labelText: 'E-mail (nije moguće mijenjati)',
                controller: _emailController,
                enabled: false,
              ),
              const SizedBox(height: 12),
              AppTextField(
                key: ProfileKeys.farmName,
                labelText: 'Naziv gospodarstva (OPG)',
                controller: _farmNameController,
                validator: ProfileValidators.farmName,
                enabled: !_isSaving,
              ),
              const SizedBox(height: 20),
              AppButton(
                key: ProfileKeys.save,
                text: _isSaving ? 'Spremanje...' : 'Spremi promjene',
                onPressed: _isSaving ? null : _saveProfile,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
