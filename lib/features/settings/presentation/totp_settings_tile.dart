import 'package:flutter/material.dart';

import '../../auth/domain/auth_error_messages.dart';
import '../../auth/domain/auth_service.dart';
import '../../auth/domain/auth_validators.dart';

class TotpSettingsTile extends StatefulWidget {
  const TotpSettingsTile({super.key, required this.authService});

  final AuthService authService;

  @override
  State<TotpSettingsTile> createState() => _TotpSettingsTileState();
}

class _TotpSettingsTileState extends State<TotpSettingsTile> {
  TotpEnrollmentStatus? _status;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    try {
      final status = await widget.authService.totpEnrollmentStatus();
      if (mounted) setState(() => _status = status);
    } on AuthException {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _openSetup(TotpEnrollmentStatus status) async {
    final enabled = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TotpEnrollmentDialog(
        authService: widget.authService,
        initialStatus: status,
      ),
    );
    if (mounted && enabled == true) {
      setState(() => _status = TotpEnrollmentStatus.enabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final description = switch (status) {
      TotpEnrollmentStatus.enabled => '2FA je uključen',
      null when _loadFailed => 'Status nije moguće učitati.',
      null => 'Učitavanje statusa…',
      _ => '2FA je isključen',
    };

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: const Text('Dvofaktorska autentifikacija'),
      subtitle: Text(description),
      trailing: switch (status) {
        TotpEnrollmentStatus.enabled => null,
        null when _loadFailed => TextButton(
          onPressed: _load,
          child: const Text('Pokušaj ponovno'),
        ),
        null => null,
        _ => TextButton(
          onPressed: () => _openSetup(status),
          child: const Text('Uključi 2FA'),
        ),
      },
    );
  }
}

class _TotpEnrollmentDialog extends StatefulWidget {
  const _TotpEnrollmentDialog({
    required this.authService,
    required this.initialStatus,
  });

  final AuthService authService;
  final TotpEnrollmentStatus initialStatus;

  @override
  State<_TotpEnrollmentDialog> createState() => _TotpEnrollmentDialogState();
}

class _TotpEnrollmentDialogState extends State<_TotpEnrollmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _code = TextEditingController();
  late TotpEnrollmentStatus _status = widget.initialStatus;
  TotpEnrollment? _enrollment;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String fallback,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        if (AuthErrorMessages.totpChallengeExpired(error.code)) {
          _enrollment = null;
          _code.clear();
          _message = 'Postavljanje je isteklo. Unesite lozinku ponovno.';
        } else if (error.code == 'unverified-email') {
          _status = TotpEnrollmentStatus.emailUnverified;
          _message = 'E-adresa još nije potvrđena.';
        } else if (error.code == 'wrong-password' ||
            error.code == 'invalid-credential') {
          _message = 'Trenutna lozinka nije ispravna.';
        } else if (error.code == 'invalid-verification-code' ||
            error.code == 'network-request-failed' ||
            error.code == 'too-many-requests') {
          _message = AuthErrorMessages.totpVerification(error.code);
        } else {
          _message = fallback;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendEmail() => _run(() async {
    await widget.authService.sendTotpVerificationEmail();
    if (mounted) setState(() => _message = 'Poruka za potvrdu je poslana.');
  }, fallback: 'Poruku za potvrdu nije moguće poslati.');

  Future<void> _checkEmail() => _run(() async {
    final status = await widget.authService.totpEnrollmentStatus(refresh: true);
    if (!mounted) return;
    if (status == TotpEnrollmentStatus.enabled) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _status = status;
      if (status == TotpEnrollmentStatus.emailUnverified) {
        _message = 'E-adresa još nije potvrđena.';
      }
    });
  }, fallback: 'Status e-adrese nije moguće provjeriti.');

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    final enrollment = _enrollment;
    await _run(
      () async {
        if (enrollment != null) {
          await enrollment.verify(_code.text);
          if (mounted) Navigator.of(context).pop(true);
          return;
        }
        final next = await widget.authService.beginTotpEnrollment(
          password: _password.text,
        );
        if (!mounted) return;
        _password.clear();
        setState(() => _enrollment = next);
      },
      fallback: enrollment == null
          ? 'Postavljanje 2FA nije moguće pokrenuti.'
          : 'Kod nije moguće potvrditi. Pokušajte ponovno.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final needsEmail = _status == TotpEnrollmentStatus.emailUnverified;
    final enrollment = _enrollment;

    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: const Text('Uključivanje 2FA'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (needsEmail)
              const Text('Potvrdite e-adresu prije uključivanja 2FA.')
            else
              Form(
                key: _formKey,
                child: enrollment == null
                    ? TextFormField(
                        key: const ValueKey('totpEnrollmentPassword'),
                        controller: _password,
                        enabled: !_busy,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Trenutna lozinka',
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Unesite trenutnu lozinku.'
                            : null,
                        onFieldSubmitted: (_) => _submit(),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dodajte ključ kao vremenski kod u autentifikatoru.',
                          ),
                          const SizedBox(height: 8),
                          const Text('Ključ za postavljanje'),
                          SelectableText(enrollment.setupKey),
                          TextFormField(
                            key: const ValueKey('totpEnrollmentCode'),
                            controller: _code,
                            enabled: !_busy,
                            keyboardType: TextInputType.number,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: const InputDecoration(
                              labelText: 'Kod iz autentifikatora',
                            ),
                            validator: AuthValidators.totpCode,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                        ],
                      ),
              ),
            if (_message case final message?) ...[
              const SizedBox(height: 12),
              Text(message),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: const Text('Odustani'),
          ),
          if (needsEmail) ...[
            TextButton(
              onPressed: _busy ? null : _sendEmail,
              child: const Text('Pošalji poruku za potvrdu'),
            ),
            TextButton(
              onPressed: _busy ? null : _checkEmail,
              child: const Text('Provjeri potvrdu'),
            ),
          ] else
            TextButton(
              onPressed: _busy ? null : _submit,
              child: Text(enrollment == null ? 'Nastavi' : 'Potvrdi'),
            ),
        ],
      ),
    );
  }
}
