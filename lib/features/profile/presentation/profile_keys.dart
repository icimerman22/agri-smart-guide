import 'package:flutter/foundation.dart';

abstract final class ProfileKeys {
  static const openProfile = ValueKey('openProfile');
  static const loading = ValueKey('profileLoading');
  static const error = ValueKey('profileError');
  static const retry = ValueKey('profileRetry');
  static const header = ValueKey('profileHeader');
  static const firstName = ValueKey('profileFirstName');
  static const lastName = ValueKey('profileLastName');
  static const email = ValueKey('profileEmail');
  static const farmName = ValueKey('profileFarmName');
}
