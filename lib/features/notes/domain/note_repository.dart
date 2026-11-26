import '../../../shared/models/note.dart';

class NoteDraft {
  const NoteDraft({
    required this.title,
    required this.content,
    this.parcelId,
    this.cropId,
  });

  final String title;
  final String content;
  final String? parcelId;
  final String? cropId;
}

abstract interface class NoteRepository {
  Stream<List<Note>> watchNotes(String ownerId);

  Stream<Note?> watchNote(String noteId);

  Future<String> createNote({
    required String ownerId,
    required NoteDraft draft,
  });

  Future<void> updateNote({
    required String ownerId,
    required String noteId,
    required NoteDraft draft,
  });

  Future<void> deleteNote({required String ownerId, required String noteId});
}

class NoteException implements Exception {
  const NoteException(this.code, {this.message});

  static const invalidTitle = 'invalid-title';
  static const invalidContent = 'invalid-content';
  static const noteNotFound = 'note-not-found';
  static const notNoteOwner = 'not-note-owner';

  final String code;
  final String? message;

  @override
  String toString() => message ?? code;
}
