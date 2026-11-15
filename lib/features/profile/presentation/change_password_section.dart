import 'package:flutter/material.dart';

import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/domain/auth_error_messages.dart';
import '../../auth/domain/auth_service.dart';
import '../../auth/domain/auth_validators.dart';
import 'profile_keys.dart';

/// "Promjena lozinke" section of the profile screen (S05).
class ChangePasswordSection extends StatefulWidget {
  const ChangePasswordSection({super.key, required this.authService});

  final AuthService authService;

  @override
  State<ChangePasswordSection> createState() => _ChangePasswordSectionState();
}

class _ChangePasswordSectionState extends State<ChangePasswordSection> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isChanging = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Molimo unesite trenutnu lozinku.';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    final error = AuthValidators.password(value);
    if (error != null) return error;
    if (value == _currentPasswordController.text) {
      return 'Nova lozinka mora se razlikovati od trenutne.';
    }
    return null;
  }

  Future<void> _changePassword() async {
    if (_isChanging) return;

    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isChanging = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await widget.authService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      _formKey.currentState!.reset();
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      messenger.showSnackBar(
        const SnackBar(content: Text('Lozinka je uspješno promijenjena.')),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(AuthErrorMessages.passwordChange(error.code))),
      );
    } finally {
      if (mounted) setState(() => _isChanging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Promjena lozinke',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          AppTextField(
            key: ProfileKeys.currentPassword,
            labelText: 'Trenutna lozinka',
            controller: _currentPasswordController,
            validator: _validateCurrentPassword,
            obscureText: true,
            enabled: !_isChanging,
          ),
          const SizedBox(height: 12),
          AppTextField(
            key: ProfileKeys.newPassword,
            labelText: 'Nova lozinka',
            controller: _newPasswordController,
            validator: _validateNewPassword,
            obscureText: true,
            enabled: !_isChanging,
          ),
          const SizedBox(height: 12),
          AppTextField(
            key: ProfileKeys.confirmNewPassword,
            labelText: 'Potvrda nove lozinke',
            controller: _confirmPasswordController,
            validator: (value) => AuthValidators.confirmPassword(
              value,
              _newPasswordController.text,
            ),
            obscureText: true,
            enabled: !_isChanging,
          ),
          const SizedBox(height: 20),
          AppButton(
            key: ProfileKeys.changePassword,
            text: _isChanging ? 'Mijenjanje...' : 'Promijeni lozinku',
            variant: AppButtonVariant.secondary,
            onPressed: _isChanging ? null : _changePassword,
          ),
        ],
      ),
    );
  }
}
