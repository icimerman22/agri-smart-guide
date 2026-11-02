import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../domain/auth_validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    // Nakon prvog pokušaja polja se provjeravaju dok korisnik tipka,
    // pa poruka greške nestane čim ispravi unos.
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);

    if (!_formKey.currentState!.validate()) return;
  }

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agri Smart Guide - Registracija'),
      ),
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
                  AppTextField(
                    controller: _emailController,
                    labelText: 'E-mail adresa',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: AuthValidators.email,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _passwordController,
                    labelText: 'Lozinka',
                    icon: Icons.lock,
                    obscureText: true,
                    validator: AuthValidators.password,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
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
                    text: 'Registriraj se',
                    onPressed: _handleRegister,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _goToLogin,
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
