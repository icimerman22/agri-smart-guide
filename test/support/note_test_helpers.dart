import 'package:agri_smart_guide/features/auth/domain/auth_service.dart';
import 'package:agri_smart_guide/features/notes/data/firestore_note_repository.dart';
import 'package:agri_smart_guide/features/notes/domain/note_repository.dart';
import 'package:agri_smart_guide/features/notes/presentation/note_list_screen.dart';
import 'package:agri_smart_guide/features/plots/data/plot_repository.dart';
import 'package:agri_smart_guide/shared/models/crop.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agri_smart_guide/features/crops/data/crop_catalog_data_source.dart';

import 'fake_auth_service.dart';

const noteAlice = AuthUser(uid: 'alice', email: 'alice@example.com');
const noteBob = AuthUser(uid: 'bob', email: 'bob@example.com');

class FakeNoteCropDataSource implements CropCatalogDataSource {
  FakeNoteCropDataSource({this.fail = false});

  final bool fail;

  @override
  Future<List<Crop>> loadCrops() async {
    if (fail) throw const FormatException('Neispravan katalog');
    return [
      Crop(
        id: 'tomato',
        name: 'Rajčica',
        category: 'plodovito povrće',
        description: '',
        sowingMonths: [3, 4, 5],
        growthDays: 90,
        waterRequirement: '',
        rowSpacingCm: 70.0,
        plantSpacingCm: 40.0,
        optimalPhMin: 6.0,
        optimalPhMax: 7.0,
        plantingPeriod: '',
        growingConditions: '',
      ),
      Crop(
        id: 'lettuce',
        name: 'Salata',
        category: 'lisnato povrće',
        description: '',
        sowingMonths: [3, 4, 5],
        growthDays: 50,
        waterRequirement: '',
        rowSpacingCm: 30.0,
        plantSpacingCm: 25.0,
        optimalPhMin: 6.0,
        optimalPhMax: 7.0,
        plantingPeriod: '',
        growingConditions: '',
      ),
    ];
  }
}

Future<void> seedNote(
  FakeFirebaseFirestore firestore,
  String id, {
  String ownerId = 'alice',
  String title = 'Bilješka',
  String content = 'Sadržaj',
  String? parcelId,
  String? cropId,
  Timestamp? updatedAt,
}) {
  return firestore.collection('notes').doc(id).set({
    'ownerId': ownerId,
    'parcelId': parcelId,
    'cropId': cropId,
    'title': title,
    'content': content,
    'photoPaths': <String>[],
    'createdAt': Timestamp(100, 0),
    'updatedAt': updatedAt ?? Timestamp(100, 0),
  });
}

Future<void> pumpNoteList(
  WidgetTester tester,
  FakeFirebaseFirestore firestore, {
  AuthUser user = noteAlice,
  String ownerId = 'alice',
  NoteRepository? noteRepository,
  PlotRepository? plotRepository,
  CropCatalogDataSource? cropDataSource,
}) async {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: NoteListScreen(
        authService: FakeAuthService(currentUser: user),
        ownerId: ownerId,
        noteRepository:
            noteRepository ?? FirestoreNoteRepository(firestore: firestore),
        plotRepository: plotRepository ?? PlotRepository(firestore: firestore),
        cropDataSource: cropDataSource ?? FakeNoteCropDataSource(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapNote(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> chooseNoteOption(
  WidgetTester tester,
  Key fieldKey,
  String option,
) async {
  await tapNote(tester, find.byKey(fieldKey));
  await tapNote(tester, find.text(option).last);
}
