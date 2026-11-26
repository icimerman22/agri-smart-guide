import 'package:agri_smart_guide/features/notes/data/firestore_note_repository.dart';
import 'package:agri_smart_guide/features/notes/domain/note_repository.dart';
import 'package:agri_smart_guide/features/notes/presentation/note_keys.dart';
import 'package:agri_smart_guide/features/plots/data/plot_repository.dart';
import 'package:agri_smart_guide/features/plots/domain/plot_model.dart';
import 'package:agri_smart_guide/shared/models/note.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/note_test_helpers.dart';
import '../../../support/planting_test_helpers.dart';

class _FailingWriteNoteRepository extends FirestoreNoteRepository {
  _FailingWriteNoteRepository(FirebaseFirestore firestore)
    : super(firestore: firestore);

  @override
  Future<String> createNote({
    required String ownerId,
    required NoteDraft draft,
  }) async => throw StateError('permission-denied');
}

class _FlakyListNoteRepository extends FirestoreNoteRepository {
  _FlakyListNoteRepository(FirebaseFirestore firestore)
    : super(firestore: firestore);

  int watchCalls = 0;

  @override
  Stream<List<Note>> watchNotes(String ownerId) {
    watchCalls++;
    if (watchCalls == 1) return Stream.error(StateError('unavailable'));
    return super.watchNotes(ownerId);
  }
}

class _FailingPlotRepository extends PlotRepository {
  _FailingPlotRepository(FirebaseFirestore firestore)
    : super(firestore: firestore);

  @override
  Stream<List<Plot>> getPlots(String ownerId) =>
      Stream.error(StateError('unavailable'));
}

Finder _inField(Key fieldKey, String text) =>
    find.descendant(of: find.byKey(fieldKey), matching: find.text(text));

DropdownButton<String?> _dropdown(WidgetTester tester, Key fieldKey) =>
    tester.widget<DropdownButton<String?>>(
      find.descendant(
        of: find.byKey(fieldKey),
        matching: find.byType(DropdownButton<String?>),
      ),
    );

String _fieldText(WidgetTester tester, Key fieldKey) =>
    tester.widget<TextFormField>(find.byKey(fieldKey)).controller!.text;

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await seedParcel(firestore, 'p1', name: 'Njiva');
    await seedParcel(firestore, 'p2', name: 'Vrt');
    await seedParcel(firestore, 'bob-parcel', ownerId: 'bob', name: 'Bobovo');
  });

  Future<List<Map<String, dynamic>>> storedNotes() async => [
    for (final doc in (await firestore.collection('notes').get()).docs)
      doc.data(),
  ];

  testWidgets('Creating a note validates required fields and saves links', (
    tester,
  ) async {
    await pumpNoteList(tester, firestore);
    expect(find.byKey(NoteKeys.listEmpty), findsOneWidget);

    await tapNote(tester, find.byKey(NoteKeys.openForm));
    expect(find.text('Nova bilješka'), findsOneWidget);
    await tapNote(tester, find.byKey(NoteKeys.save));
    expect(find.text('Unesite naslov bilješke.'), findsOneWidget);
    expect(find.text('Unesite sadržaj bilješke.'), findsOneWidget);

    await tester.enterText(find.byKey(NoteKeys.titleField), 'Gnojidba');
    await tester.enterText(find.byKey(NoteKeys.contentField), '   ');
    await tapNote(tester, find.byKey(NoteKeys.save));
    expect(find.text('Unesite naslov bilješke.'), findsNothing);
    expect(find.text('Unesite sadržaj bilješke.'), findsOneWidget);
    expect(await storedNotes(), isEmpty);

    await tester.enterText(find.byKey(NoteKeys.contentField), 'NPK 15-15-15');
    await chooseNoteOption(tester, NoteKeys.parcelField, 'Vrt');
    await chooseNoteOption(tester, NoteKeys.cropField, 'Rajčica');
    await tapNote(tester, find.byKey(NoteKeys.save));

    final note = (await storedNotes()).single;
    expect(note['ownerId'], 'alice');
    expect(note['title'], 'Gnojidba');
    expect(note['content'], 'NPK 15-15-15');
    expect(note['parcelId'], 'p2');
    expect(note['cropId'], 'tomato');
    expect(find.text('Bilješka je spremljena.'), findsOneWidget);
    expect(find.text('Gnojidba'), findsOneWidget);
    expect(find.textContaining('Vrt • Rajčica'), findsOneWidget);
  });

  testWidgets('Parcel options list only the signed-in user parcels', (
    tester,
  ) async {
    await pumpNoteList(tester, firestore);
    await tapNote(tester, find.byKey(NoteKeys.openForm));
    await tapNote(tester, find.byKey(NoteKeys.parcelField));

    expect(find.text('Bez parcele'), findsWidgets);
    expect(find.text('Njiva'), findsWidgets);
    expect(find.text('Vrt'), findsWidgets);
    expect(find.text('Bobovo'), findsNothing);
  });

  testWidgets('Detail shows the note and editing updates it in place', (
    tester,
  ) async {
    await seedNote(
      firestore,
      'n1',
      title: 'Rezidba',
      content: 'Orezati suhe grane.',
      parcelId: 'p1',
      cropId: 'tomato',
    );
    await pumpNoteList(tester, firestore);

    await tapNote(tester, find.byKey(NoteKeys.listItem('n1')));
    expect(find.byKey(NoteKeys.detailTitle), findsOneWidget);
    expect(find.text('Orezati suhe grane.'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Njiva'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Rajčica'), findsOneWidget);

    await tapNote(tester, find.byKey(NoteKeys.edit));
    expect(find.text('Uredi bilješku'), findsOneWidget);
    expect(_fieldText(tester, NoteKeys.titleField), 'Rezidba');
    expect(_fieldText(tester, NoteKeys.contentField), 'Orezati suhe grane.');
    expect(_inField(NoteKeys.parcelField, 'Njiva'), findsOneWidget);
    expect(_inField(NoteKeys.cropField, 'Rajčica'), findsOneWidget);

    await tester.enterText(find.byKey(NoteKeys.contentField), '');
    await tapNote(tester, find.byKey(NoteKeys.save));
    expect(find.text('Unesite sadržaj bilješke.'), findsOneWidget);
    expect((await storedNotes()).single['content'], 'Orezati suhe grane.');

    await tester.enterText(find.byKey(NoteKeys.titleField), 'Rezidba voćaka');
    await tester.enterText(
      find.byKey(NoteKeys.contentField),
      'Orezati suhe i bolesne grane.',
    );
    await chooseNoteOption(tester, NoteKeys.parcelField, 'Vrt');
    await chooseNoteOption(tester, NoteKeys.cropField, 'Bez kulture');
    await tapNote(tester, find.byKey(NoteKeys.save));

    final note = (await storedNotes()).single;
    expect(note['title'], 'Rezidba voćaka');
    expect(note['parcelId'], 'p2');
    expect(note['cropId'], isNull);
    expect(find.text('Bilješka je ažurirana.'), findsOneWidget);
    expect(find.byKey(NoteKeys.detailTitle), findsOneWidget);
    expect(find.text('Rezidba voćaka'), findsOneWidget);
    expect(find.text('Orezati suhe i bolesne grane.'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Vrt'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Rajčica'), findsNothing);
  });

  testWidgets('Deleting asks for confirmation and returns to the list', (
    tester,
  ) async {
    await seedNote(firestore, 'n1', title: 'Za brisanje');
    await pumpNoteList(tester, firestore);
    await tapNote(tester, find.byKey(NoteKeys.listItem('n1')));

    await tapNote(tester, find.byKey(NoteKeys.delete));
    expect(find.textContaining('Za brisanje'), findsWidgets);
    await tapNote(tester, find.byKey(NoteKeys.deleteCancel));
    expect(await storedNotes(), hasLength(1));
    expect(find.byKey(NoteKeys.detailTitle), findsOneWidget);

    await tapNote(tester, find.byKey(NoteKeys.delete));
    await tapNote(tester, find.byKey(NoteKeys.deleteConfirm));
    expect(await storedNotes(), isEmpty);
    expect(find.byKey(NoteKeys.listEmpty), findsOneWidget);
    expect(find.text('Bilješka je obrisana.'), findsOneWidget);
  });

  testWidgets('Users see only their own notes and notes survive a restart', (
    tester,
  ) async {
    await seedNote(firestore, 'a1', title: 'Alicina bilješka');
    await seedNote(firestore, 'b1', ownerId: 'bob', title: 'Bobova bilješka');

    await pumpNoteList(tester, firestore);
    expect(find.text('Alicina bilješka'), findsOneWidget);
    expect(find.text('Bobova bilješka'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpNoteList(tester, firestore, user: noteBob, ownerId: 'bob');
    expect(find.text('Bobova bilješka'), findsOneWidget);
    expect(find.text('Alicina bilješka'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpNoteList(tester, firestore);
    expect(find.text('Alicina bilješka'), findsOneWidget);
  });

  testWidgets('Another user session cannot open the owner note list', (
    tester,
  ) async {
    await seedNote(firestore, 'a1', title: 'Alicina bilješka');
    await pumpNoteList(tester, firestore, user: noteBob, ownerId: 'alice');

    expect(find.text('Korisnik nije prijavljen.'), findsOneWidget);
    expect(find.text('Alicina bilješka'), findsNothing);
    expect(find.byKey(NoteKeys.openForm), findsNothing);
  });

  testWidgets('A deleted parcel is labelled and cleared when editing', (
    tester,
  ) async {
    await seedNote(firestore, 'n1', title: 'Stara parcela', parcelId: 'gone');
    await pumpNoteList(tester, firestore);
    expect(find.textContaining('Obrisana parcela'), findsOneWidget);

    await tapNote(tester, find.byKey(NoteKeys.listItem('n1')));
    expect(find.widgetWithText(Chip, 'Obrisana parcela'), findsOneWidget);
    await tapNote(tester, find.byKey(NoteKeys.edit));
    expect(
      find.text('Prethodno povezana parcela je obrisana.'),
      findsOneWidget,
    );
    expect(_inField(NoteKeys.parcelField, 'Bez parcele'), findsOneWidget);

    await tapNote(tester, find.byKey(NoteKeys.save));
    expect((await storedNotes()).single['parcelId'], isNull);
  });

  testWidgets('A parcel deleted while the form is open is cleared', (
    tester,
  ) async {
    await pumpNoteList(tester, firestore);
    await tapNote(tester, find.byKey(NoteKeys.openForm));
    await chooseNoteOption(tester, NoteKeys.parcelField, 'Vrt');

    await firestore.doc('parcels/p2').delete();
    await tester.pumpAndSettle();
    expect(
      find.text('Prethodno povezana parcela je obrisana.'),
      findsOneWidget,
    );
    expect(_inField(NoteKeys.parcelField, 'Bez parcele'), findsOneWidget);
  });

  testWidgets('A failed save keeps the form open with an error', (
    tester,
  ) async {
    await pumpNoteList(
      tester,
      firestore,
      noteRepository: _FailingWriteNoteRepository(firestore),
    );
    await tapNote(tester, find.byKey(NoteKeys.openForm));
    await tester.enterText(find.byKey(NoteKeys.titleField), 'Naslov');
    await tester.enterText(find.byKey(NoteKeys.contentField), 'Sadržaj');
    await tapNote(tester, find.byKey(NoteKeys.save));

    expect(find.byKey(NoteKeys.saveError), findsOneWidget);
    expect(find.text('Spremanje bilješke nije uspjelo.'), findsOneWidget);
    expect(find.text('Nova bilješka'), findsOneWidget);
    expect(_fieldText(tester, NoteKeys.titleField), 'Naslov');
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(
              of: find.byKey(NoteKeys.save),
              matching: find.byWidgetPredicate((w) => w is FilledButton),
            ),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('Unavailable parcels and crops lock links but keep them', (
    tester,
  ) async {
    await seedNote(
      firestore,
      'n1',
      title: 'Povezana',
      parcelId: 'p1',
      cropId: 'tomato',
    );
    await pumpNoteList(
      tester,
      firestore,
      plotRepository: _FailingPlotRepository(firestore),
      cropDataSource: FakeNoteCropDataSource(fail: true),
    );
    await tapNote(tester, find.byKey(NoteKeys.listItem('n1')));
    await tapNote(tester, find.byKey(NoteKeys.edit));

    expect(find.textContaining('Parcele nije moguće učitati.'), findsOneWidget);
    expect(find.textContaining('Kulture nije moguće učitati.'), findsOneWidget);
    expect(_dropdown(tester, NoteKeys.parcelField).onChanged, isNull);
    expect(_dropdown(tester, NoteKeys.cropField).onChanged, isNull);

    await tester.enterText(find.byKey(NoteKeys.titleField), 'Novi naslov');
    await tapNote(tester, find.byKey(NoteKeys.save));
    final note = (await storedNotes()).single;
    expect(note['title'], 'Novi naslov');
    expect(note['parcelId'], 'p1');
    expect(note['cropId'], 'tomato');
  });

  testWidgets('A failed list load can be retried', (tester) async {
    await seedNote(firestore, 'n1', title: 'Nakon ponovnog pokušaja');
    final repository = _FlakyListNoteRepository(firestore);
    await pumpNoteList(tester, firestore, noteRepository: repository);

    expect(find.byKey(NoteKeys.listError), findsOneWidget);
    await tapNote(tester, find.text('Pokušaj ponovno'));
    expect(repository.watchCalls, 2);
    expect(find.text('Nakon ponovnog pokušaja'), findsOneWidget);
  });

  testWidgets('A note deleted elsewhere shows as unavailable', (tester) async {
    await seedNote(firestore, 'n1', title: 'Nestaje');
    await pumpNoteList(tester, firestore);
    await tapNote(tester, find.byKey(NoteKeys.listItem('n1')));

    await firestore.doc('notes/n1').delete();
    await tester.pumpAndSettle();
    expect(find.byKey(NoteKeys.detailNotFound), findsOneWidget);
    expect(find.byKey(NoteKeys.edit), findsNothing);
    expect(find.byKey(NoteKeys.delete), findsNothing);
  });
}
