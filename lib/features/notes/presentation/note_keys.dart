import 'package:flutter/foundation.dart';

abstract final class NoteKeys {
  static const openNoteList = ValueKey('openNoteList');
  static const openForm = ValueKey('noteOpenForm');
  static const edit = ValueKey('noteEdit');
  static const form = ValueKey('noteForm');
  static const titleField = ValueKey('noteTitle');
  static const contentField = ValueKey('noteContent');
  static const parcelField = ValueKey('noteParcel');
  static const cropField = ValueKey('noteCrop');
  static const save = ValueKey('noteSave');
  static const saveError = ValueKey('noteSaveError');
  static const formLoading = ValueKey('noteFormLoading');
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
