import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/note.dart';
import '../domain/note_repository.dart';

class FirestoreNoteRepository implements NoteRepository {
  FirestoreNoteRepository({
    FirebaseFirestore? firestore,
    DateTime Function()? clock,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _clock = clock ?? DateTime.now;

  final FirebaseFirestore _firestore;
  final DateTime Function() _clock;

  CollectionReference<Map<String, dynamic>> get _notes =>
      _firestore.collection('notes');

  @override
  Stream<List<Note>> watchNotes(String ownerId) {
    return _notes
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(Note.fromFirestore).toList()
                ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
        );
  }

  @override
  Stream<Note?> watchNote(String noteId) {
    return _notes
        .doc(noteId)
        .snapshots()
        .map(
          (snapshot) => snapshot.exists ? Note.fromFirestore(snapshot) : null,
        );
  }

  @override
  Future<String> createNote({
    required String ownerId,
    required NoteDraft draft,
  }) async {
    final fields = _validatedFields(draft);
    final ref = _notes.doc();
    final now = Timestamp.fromDate(_clock());

    await ref.set({
      ...fields,
      'ownerId': ownerId,
      'photoPaths': const <String>[],
      'createdAt': now,
      'updatedAt': now,
    });
    return ref.id;
  }

  @override
  Future<void> updateNote({
    required String ownerId,
    required String noteId,
    required NoteDraft draft,
  }) async {
    final fields = _validatedFields(draft);
    final ref = _notes.doc(noteId);
    final now = Timestamp.fromDate(_clock());

    await _firestore.runTransaction((transaction) async {
      _requireOwnedNote(await transaction.get(ref), ownerId);
      transaction.update(ref, {...fields, 'updatedAt': now});
    });
  }

  @override
  Future<void> deleteNote({
    required String ownerId,
    required String noteId,
  }) async {
    final ref = _notes.doc(noteId);

    await _firestore.runTransaction((transaction) async {
      _requireOwnedNote(await transaction.get(ref), ownerId);
      transaction.delete(ref);
    });
  }

  Map<String, dynamic> _validatedFields(NoteDraft draft) {
    final title = draft.title.trim();
    final content = draft.content.trim();
    if (title.isEmpty) {
      throw const NoteException(
        NoteException.missingTitle,
        message: 'Naslov bilješke je obavezan.',
      );
    }
    if (content.isEmpty) {
      throw const NoteException(
        NoteException.missingContent,
        message: 'Sadržaj bilješke je obavezan.',
      );
    }
    return {
      'title': title,
      'content': content,
      'parcelId': draft.parcelId,
      'cropId': draft.cropId,
    };
  }

  void _requireOwnedNote(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    String ownerId,
  ) {
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw const NoteException(
        NoteException.noteNotFound,
        message: 'Bilješka ne postoji.',
      );
    }
    if (data['ownerId'] != ownerId) {
      throw const NoteException(
        NoteException.notNoteOwner,
        message: 'Možete mijenjati samo vlastite bilješke.',
      );
    }
  }
}
