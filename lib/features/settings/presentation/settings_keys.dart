import 'package:flutter/foundation.dart';

abstract final class SettingsKeys {
  static const loading = ValueKey('settingsLoading');
  static const error = ValueKey('settingsError');
  static const retry = ValueKey('settingsRetry');
  static const unitSystem = ValueKey('settingsUnitSystem');

  static ValueKey<String> notification(String type) =>
      ValueKey('settingsNotification_$type');
}
