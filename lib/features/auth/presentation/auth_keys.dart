import 'package:flutter/foundation.dart';

abstract final class AuthKeys {
  static const loginEmail = ValueKey('loginEmail');
  static const loginPassword = ValueKey('loginPassword');
  static const loginSubmit = ValueKey('loginSubmit');
  static const goToRegister = ValueKey('goToRegister');
  static const registerEmail = ValueKey('registerEmail');
  static const registerPassword = ValueKey('registerPassword');
  static const registerConfirmPassword = ValueKey('registerConfirmPassword');
  static const registerSubmit = ValueKey('registerSubmit');
  static const goToLogin = ValueKey('goToLogin');
  static const logout = ValueKey('logout');
  static const logoutIcon = ValueKey('logoutIcon');
}
