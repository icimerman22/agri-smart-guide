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
      final changed = await widget.authService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmTotp: _confirmTotp,
      );
      if (!mounted || !changed) return;
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

  Future<void> _confirmTotp(TotpVerifier verify) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PasswordChangeTotpDialog(verify: verify),
    );
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

class _PasswordChangeTotpDialog extends StatefulWidget {
  const _PasswordChangeTotpDialog({required this.verify});

  final TotpVerifier verify;

  @override
  State<_PasswordChangeTotpDialog> createState() =>
      _PasswordChangeTotpDialogState();
}

class _PasswordChangeTotpDialogState extends State<_PasswordChangeTotpDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isVerifying = false;
  bool _challengeEnded = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_isVerifying || _challengeEnded || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      await widget.verify(_codeController.text);
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (error) {
      if (!mounted) return;
      final expired = AuthErrorMessages.totpChallengeExpired(error.code);
      final accountChanged = error.code == 'auth-user-changed';
      setState(() {
        _challengeEnded = expired || accountChanged;
        _errorMessage = switch (error.code) {
          _ when expired => 'Potvrda je istekla. Pokrenite promjenu ponovno.',
          _ when accountChanged => AuthErrorMessages.passwordChange(error.code),
          _ => AuthErrorMessages.totpVerification(error.code),
        };
      });
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = !_isVerifying && !_challengeEnded;
    return PopScope(
      canPop: !_isVerifying,
      child: AlertDialog(
        title: const Text('Potvrdite promjenu lozinke'),
        scrollable: true,
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _codeController,
            enabled: canConfirm,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            decoration: InputDecoration(
              labelText: 'Kod iz autentifikatorske aplikacije',
              errorText: _errorMessage,
              errorMaxLines: 3,
            ),
            validator: AuthValidators.totpCode,
            onFieldSubmitted: (_) => _confirm(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isVerifying ? null : () => Navigator.of(context).pop(),
            child: const Text('Odustani'),
          ),
          TextButton(
            onPressed: canConfirm ? _confirm : null,
            child: Text(_isVerifying ? 'Provjera…' : 'Potvrdi'),
          ),
        ],
      ),
    );
  }
}
