import 'package:agri_smart_guide/features/notes/data/firestore_note_repository.dart';
import 'package:agri_smart_guide/features/notes/domain/note_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/note_test_helpers.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late DateTime now;
  late FirestoreNoteRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    now = DateTime(2026, 11, 20, 9, 30);
    repository = FirestoreNoteRepository(
      firestore: firestore,
      clock: () => now,
    );
  });

  Future<Map<String, dynamic>?> noteData(String id) async =>
      (await firestore.doc('notes/$id').get()).data();

  Matcher throwsNoteException(String code) =>
      throwsA(isA<NoteException>().having((error) => error.code, 'code', code));

  group('createNote', () {
    test('stores trimmed fields, links, owner and timestamps', () async {
      final id = await repository.createNote(
        ownerId: 'alice',
        draft: const NoteDraft(
          title: '  Gnojidba  ',
          content: '\nNPK 15-15-15\n',
          parcelId: 'p1',
          cropId: 'tomato',
        ),
      );

      expect(await noteData(id), {
        'ownerId': 'alice',
        'parcelId': 'p1',
        'cropId': 'tomato',
        'title': 'Gnojidba',
        'content': 'NPK 15-15-15',
        'photoPaths': <String>[],
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
    });

    test('allows a note without parcel and crop', () async {
      final id = await repository.createNote(
        ownerId: 'alice',
        draft: const NoteDraft(title: 'Vrijeme', content: 'Kiša cijeli dan'),
      );

      final data = await noteData(id);
      expect(data!['parcelId'], isNull);
      expect(data['cropId'], isNull);
    });

    test('rejects invalid required fields without writing', () async {
      final invalid = {
        NoteException.invalidTitle: [
          const NoteDraft(title: '   ', content: 'Sadržaj'),
          NoteDraft(title: 'a' * 101, content: 'Sadržaj'),
        ],
        NoteException.invalidContent: [
          const NoteDraft(title: 'Naslov', content: '  \n '),
          NoteDraft(title: 'Naslov', content: 'a' * 5001),
        ],
      };

      for (final entry in invalid.entries) {
        for (final draft in entry.value) {
          await expectLater(
            repository.createNote(ownerId: 'alice', draft: draft),
            throwsNoteException(entry.key),
          );
        }
      }
      expect((await firestore.collection('notes').get()).docs, isEmpty);
    });
  });

  group('watchNotes', () {
    test('returns only the owner notes, newest change first', () async {
      await seedNote(
        firestore,
        'old',
        title: 'Stara',
        updatedAt: Timestamp(100, 0),
      );
      await seedNote(
        firestore,
        'new',
        title: 'Nova',
        updatedAt: Timestamp(300, 0),
      );
      await seedNote(
        firestore,
        'mid',
        title: 'Srednja',
        updatedAt: Timestamp(200, 0),
      );
      await seedNote(firestore, 'foreign', ownerId: 'bob', title: 'Bobova');

      final aliceNotes = await repository.watchNotes('alice').first;
      expect(aliceNotes.map((note) => note.id), ['new', 'mid', 'old']);

      final bobNotes = await repository.watchNotes('bob').first;
      expect(bobNotes.map((note) => note.title), ['Bobova']);
    });

    test('emits changes after create, update and delete', () async {
      final titles = repository
          .watchNotes('alice')
          .map((notes) => notes.map((note) => note.title).toList());
      final expectation = expectLater(
        titles,
        emitsInOrder([
          <String>[],
          ['Prva'],
          ['Promijenjena'],
          <String>[],
        ]),
      );

      final id = await repository.createNote(
        ownerId: 'alice',
        draft: const NoteDraft(title: 'Prva', content: 'Sadržaj'),
      );
      await repository.updateNote(
        ownerId: 'alice',
        noteId: id,
        draft: const NoteDraft(title: 'Promijenjena', content: 'Sadržaj'),
      );
      await repository.deleteNote(ownerId: 'alice', noteId: id);
      await expectation;
    });
  });

  group('watchNote', () {
    test('emits the note and null once it is deleted', () async {
      await seedNote(firestore, 'n1', title: 'Rezidba');

      final expectation = expectLater(
        repository.watchNote('n1').map((note) => note?.title),
        emitsInOrder(['Rezidba', null]),
      );
      await firestore.doc('notes/n1').delete();
      await expectation;
    });
  });

  group('updateNote', () {
    test(
      'changes content and links but keeps owner and creation time',
      () async {
        await seedNote(firestore, 'n1', parcelId: 'p1', cropId: 'tomato');

        await repository.updateNote(
          ownerId: 'alice',
          noteId: 'n1',
          draft: const NoteDraft(
            title: ' Novi naslov ',
            content: 'Novi sadržaj',
            parcelId: 'p2',
          ),
        );

        final data = await noteData('n1');
        expect(data!['title'], 'Novi naslov');
        expect(data['content'], 'Novi sadržaj');
        expect(data['parcelId'], 'p2');
        expect(data['cropId'], isNull);
        expect(data['ownerId'], 'alice');
        expect(data['createdAt'], Timestamp(100, 0));
        expect(data['updatedAt'], Timestamp.fromDate(now));
      },
    );

    test('rejects invalid fields and keeps the stored note', () async {
      await seedNote(firestore, 'n1', title: 'Original');

      await expectLater(
        repository.updateNote(
          ownerId: 'alice',
          noteId: 'n1',
          draft: const NoteDraft(title: '', content: 'Sadržaj'),
        ),
        throwsNoteException(NoteException.invalidTitle),
      );
      expect((await noteData('n1'))!['title'], 'Original');
    });

    test('rejects a missing note and another user note', () async {
      await seedNote(firestore, 'foreign', ownerId: 'bob', title: 'Bobova');
      const draft = NoteDraft(title: 'Preuzeto', content: 'Sadržaj');

      await expectLater(
        repository.updateNote(
          ownerId: 'alice',
          noteId: 'missing',
          draft: draft,
        ),
        throwsNoteException(NoteException.noteNotFound),
      );
      await expectLater(
        repository.updateNote(
          ownerId: 'alice',
          noteId: 'foreign',
          draft: draft,
        ),
        throwsNoteException(NoteException.notNoteOwner),
      );
      expect((await noteData('foreign'))!['title'], 'Bobova');
      expect(await noteData('missing'), isNull);
    });
  });

  group('deleteNote', () {
    test('removes the owner note', () async {
      await seedNote(firestore, 'n1');

      await repository.deleteNote(ownerId: 'alice', noteId: 'n1');

      expect(await noteData('n1'), isNull);
    });

    test('rejects a missing note and another user note', () async {
      await seedNote(firestore, 'foreign', ownerId: 'bob');

      await expectLater(
        repository.deleteNote(ownerId: 'alice', noteId: 'missing'),
        throwsNoteException(NoteException.noteNotFound),
      );
      await expectLater(
        repository.deleteNote(ownerId: 'alice', noteId: 'foreign'),
        throwsNoteException(NoteException.notNoteOwner),
      );
      expect(await noteData('foreign'), isNotNull);
    });
  });
}
