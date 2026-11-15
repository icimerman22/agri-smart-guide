/// Default settings for a user who has not changed them yet.
///
/// Used both for a brand-new profile and for a stored profile that is missing
/// some keys (e.g. saved before a new notification type was added).
abstract final class SettingsDefaults {
  static const String unitSystem = 'metric';

  /// Deadline, weather and recommendation notifications are on by default;
  /// the extra reminder a day earlier is opt-in.
  static const Map<String, bool> notifications = {
    'taskDeadlines': true,
    'weatherAlerts': true,
    'recommendations': true,
    'dayBeforeReminder': false,
  };

  /// Stored value for [type], or its default when it was never saved.
  static bool isNotificationEnabled(Map<String, dynamic> stored, String type) {
    final value = stored[type];
    if (value is bool) return value;
    return notifications[type] ?? false;
  }

  /// Stored settings completed with defaults for every missing key.
  static Map<String, dynamic> completeNotifications(
    Map<String, dynamic> stored,
  ) => {...notifications, ...stored};
}
