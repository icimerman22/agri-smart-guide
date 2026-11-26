import 'package:flutter/foundation.dart';

abstract final class NoteKeys {
  static const openNoteList = ValueKey('openNoteList');
  static const listEmpty = ValueKey('noteListEmpty');
  static const listError = ValueKey('noteListError');
  static const detailNotFound = ValueKey('noteDetailNotFound');
  static const detailTitle = ValueKey('noteDetailTitle');
  static const detailContent = ValueKey('noteDetailContent');
  static const delete = ValueKey('noteDelete');
  static const deleteConfirm = ValueKey('noteDeleteConfirm');
  static const deleteCancel = ValueKey('noteDeleteCancel');

  static ValueKey<String> listItem(String noteId) =>
      ValueKey('noteItem-$noteId');
}
