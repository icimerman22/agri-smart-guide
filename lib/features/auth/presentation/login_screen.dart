import 'package:flutter/material.dart';
import '../../../app/routes.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
        await widget.authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } on AuthException catch (e) {
        if (!mounted) return;
        setState(() {
          if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
            _errorMessage = 'Neispravna e-mail adresa ili lozinka.';
          } else if (e.code == 'invalid-email') {
            _errorMessage = 'Format e-mail adrese nije valjan.';
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

  @override
  Widget build(BuildContext context) {
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