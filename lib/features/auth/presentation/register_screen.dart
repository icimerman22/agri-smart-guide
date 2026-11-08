import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../domain/auth_error_messages.dart';
import '../domain/auth_service.dart';
import '../domain/auth_validators.dart';
import 'auth_keys.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;
    // Nakon prvog pokušaja polja se provjeravaju dok korisnik tipka,
    // pa poruka greške nestane čim ispravi unos.
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Firebase nakon uspješne registracije korisnika odmah i prijavi.
      await widget.authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthErrorMessages.registration(e.code));
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthErrorMessages.registration(''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Agri Smart Guide - Registracija')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              autovalidateMode: _autovalidateMode,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Izradite račun',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: colors.onErrorContainer),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  AppTextField(
                    key: AuthKeys.registerEmail,
                    controller: _emailController,
                    labelText: 'E-mail adresa',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: AuthValidators.email,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    key: AuthKeys.registerPassword,
                    controller: _passwordController,
                    labelText: 'Lozinka',
                    icon: Icons.lock,
                    obscureText: true,
                    validator: AuthValidators.password,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    key: AuthKeys.registerConfirmPassword,
                    controller: _confirmPasswordController,
                    labelText: 'Potvrda lozinke',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: (value) => AuthValidators.confirmPassword(
                      value,
                      _passwordController.text,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    key: AuthKeys.registerSubmit,
                    text: _isLoading
                        ? 'Registracija u tijeku...'
                        : 'Registriraj se',
                    onPressed: _isLoading ? null : _handleRegister,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    key: AuthKeys.goToLogin,
                    onPressed: _isLoading ? null : _goToLogin,
                    child: const Text('Već imate račun? Prijavite se'),
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
