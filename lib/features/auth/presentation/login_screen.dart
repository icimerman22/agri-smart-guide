import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../domain/auth_error_messages.dart';
import '../domain/auth_service.dart';
import '../domain/auth_validators.dart';
import 'auth_keys.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _totpFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _totpController = TextEditingController();

  TotpSignInRequired? _totpChallenge;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _totpController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final result = await widget.authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;
        switch (result) {
          case SignedIn():
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          case TotpSignInRequired():
            _passwordController.clear();
            setState(() => _totpChallenge = result);
        }
      } on AuthException catch (e) {
        if (!mounted) return;
        setState(() {
          if (e.code == 'user-not-found' ||
              e.code == 'wrong-password' ||
              e.code == 'invalid-credential') {
            _errorMessage = 'Neispravna e-mail adresa ili lozinka.';
          } else if (e.code == 'invalid-email') {
            _errorMessage = 'Format e-mail adrese nije valjan.';
          } else if (e.code == 'unsupported-second-factor') {
            _errorMessage = e.message;
          } else {
            _errorMessage = 'Došlo je do pogreške: ${e.message}';
          }
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Neočekivana pogreška. Pokušajte ponovno.';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _leaveTotp({String? error}) {
    _totpController.clear();
    setState(() {
      _totpChallenge = null;
      _errorMessage = error;
    });
  }

  Future<void> _confirmTotp(TotpSignInRequired challenge) async {
    if (_isLoading || !_totpFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await challenge.verify(_totpController.text);
      if (!mounted) return;
      _totpController.clear();
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on AuthException catch (error) {
      if (!mounted) return;
      if (AuthErrorMessages.totpChallengeExpired(error.code)) {
        _leaveTotp(error: 'Potvrda je istekla. Prijavite se ponovno.');
      } else {
        setState(
          () => _errorMessage = AuthErrorMessages.totpVerification(error.code),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTotpScreen(TotpSignInRequired challenge) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isLoading) _leaveTotp();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Potvrda prijave')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _totpFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Unesite kod iz autentifikatorske aplikacije.'),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: AuthKeys.loginTotpCode,
                      controller: _totpController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'Kod za potvrdu',
                        border: const OutlineInputBorder(),
                        errorText: _errorMessage,
                      ),
                      validator: AuthValidators.totpCode,
                      onFieldSubmitted: (_) => _confirmTotp(challenge),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      key: AuthKeys.loginTotpSubmit,
                      onPressed: _isLoading
                          ? null
                          : () => _confirmTotp(challenge),
                      child: Text(_isLoading ? 'Provjera…' : 'Potvrdi'),
                    ),
                    TextButton(
                      key: AuthKeys.loginTotpCancel,
                      onPressed: _isLoading ? null : () => _leaveTotp(),
                      child: const Text('Odustani'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _totpChallenge;
    if (challenge != null) return _buildTotpScreen(challenge);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agri Smart Guide - Prijava'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Dobrodošli!',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    key: AuthKeys.loginEmail,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail adresa',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: AuthValidators.email,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    key: AuthKeys.loginPassword,
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Lozinka',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Molimo unesite lozinku.';
                      }
                      if (value.length < 6) {
                        return 'Lozinka mora imati najmanje 6 znakova.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      key: AuthKeys.loginSubmit,
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Prijavi se', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    key: AuthKeys.goToRegister,
                    onPressed: _isLoading
                        ? null
                        : () {
                      Navigator.pushReplacementNamed(context, AppRoutes.register);
                    },
                    child: const Text('Nemate račun? Registrirajte se'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
