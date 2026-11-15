import 'package:agri_smart_guide/features/profile/data/firestore_profile_repository.dart';
import 'package:agri_smart_guide/features/profile/domain/profile_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreProfileRepository repository;
  late Timestamp now;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    now = Timestamp(100, 0);
    repository = FirestoreProfileRepository(
      firestore: firestore,
      clock: () => now,
    );
  });

  group('FirestoreProfileRepository.loadProfile', () {
    test('vraća zadani profil i ne stvara dokument kad ga nema', () async {
      final profile = await repository.loadProfile('alice');

      expect(profile.id, 'alice');
      expect(profile.firstName, '');
      expect(profile.unitSystem, 'metric');
      expect(profile.createdAt, Timestamp(100, 0));
      expect((await firestore.doc('users/alice').get()).exists, isFalse);
    });

    test('baca ProfileException za neispravan dokument', () async {
      await firestore.doc('users/alice').set({'firstName': 'Ana'});

      expect(
        repository.loadProfile('alice'),
        throwsA(
          isA<ProfileException>().having(
            (error) => error.code,
            'code',
            'invalid-data',
          ),
        ),
      );
    });
  });

  group('FirestoreProfileRepository.saveProfile', () {
    test('zapisuje sva polja koja traže sigurnosna pravila', () async {
      final profile = await repository.loadProfile('alice');
      await repository.saveProfile(profile);

      final data = (await firestore.doc('users/alice').get()).data()!;
      expect(data.keys.toSet(), {
        'firstName',
        'lastName',
        'farmName',
        'primaryLocation',
        'unitSystem',
        'notificationSettings',
        'createdAt',
        'updatedAt',
      });
    });

    test('spremljene izmjene ponovno se učitavaju', () async {
      final initial = await repository.loadProfile('alice');
      now = Timestamp(200, 0);

      final saved = await repository.saveProfile(
        initial.copyWith(
          firstName: 'Ana',
          lastName: 'Horvat',
          farmName: 'OPG Horvat',
          primaryLocation: {
            'name': 'Varaždin',
            'latitude': 46.3057,
            'longitude': 16.3366,
          },
          unitSystem: 'imperial',
        ),
      );
      final loaded = await repository.loadProfile('alice');

      expect(saved.updatedAt, Timestamp(200, 0));
      expect(loaded.firstName, 'Ana');
      expect(loaded.lastName, 'Horvat');
      expect(loaded.farmName, 'OPG Horvat');
      expect(loaded.primaryLocation['name'], 'Varaždin');
      expect(loaded.unitSystem, 'imperial');
      expect(loaded.createdAt, Timestamp(100, 0));
      expect(loaded.updatedAt, Timestamp(200, 0));
    });

    test('profili različitih korisnika spremaju se odvojeno', () async {
      final alice = await repository.loadProfile('alice');
      final bob = await repository.loadProfile('bob');
      await repository.saveProfile(alice.copyWith(firstName: 'Alice'));
      await repository.saveProfile(bob.copyWith(firstName: 'Bob'));

      expect((await repository.loadProfile('alice')).firstName, 'Alice');
      expect((await repository.loadProfile('bob')).firstName, 'Bob');
    });
  });
}
