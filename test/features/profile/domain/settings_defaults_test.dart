import 'package:agri_smart_guide/features/profile/domain/profile_repository.dart';
import 'package:agri_smart_guide/features/profile/domain/settings_defaults.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingsDefaults', () {
    test('novi profil dobiva zadane postavke', () {
      final profile = defaultUserProfile('u1', Timestamp(10, 0));

      expect(profile.id, 'u1');
      expect(profile.firstName, '');
      expect(profile.primaryLocation, isEmpty);
      expect(profile.unitSystem, 'metric');
      expect(profile.notificationSettings, {
        'taskDeadlines': true,
        'weatherAlerts': true,
        'recommendations': true,
        'dayBeforeReminder': false,
      });
      expect(profile.createdAt, Timestamp(10, 0));
      expect(profile.updatedAt, Timestamp(10, 0));
    });

    test('ključ koji nedostaje dobiva zadanu vrijednost', () {
      expect(SettingsDefaults.isNotificationEnabled({}, 'taskDeadlines'), true);
      expect(
        SettingsDefaults.isNotificationEnabled({}, 'dayBeforeReminder'),
        false,
      );
      expect(SettingsDefaults.isNotificationEnabled({}, 'nepoznato'), false);
    });

    test('spremljena vrijednost ima prednost pred zadanom', () {
      expect(
        SettingsDefaults.isNotificationEnabled({
          'taskDeadlines': false,
        }, 'taskDeadlines'),
        false,
      );
      expect(
        SettingsDefaults.isNotificationEnabled({
          'dayBeforeReminder': true,
        }, 'dayBeforeReminder'),
        true,
      );
    });

    test('dopunjava spremljene postavke zadanim vrijednostima', () {
      expect(SettingsDefaults.completeNotifications({'weatherAlerts': false}), {
        'taskDeadlines': true,
        'weatherAlerts': false,
        'recommendations': true,
        'dayBeforeReminder': false,
      });
    });
  });
}
