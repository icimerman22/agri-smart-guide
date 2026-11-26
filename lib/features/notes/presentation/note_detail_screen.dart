import 'package:flutter/material.dart';

import '../../../shared/formatters/date_format.dart';
import '../../../shared/models/note.dart';
import '../domain/note_repository.dart';
import 'note_form_screen.dart';
import 'note_keys.dart';
import 'note_link_options.dart';

class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({
    super.key,
    required this.ownerId,
    required this.noteId,
    required this.noteRepository,
    required this.linkOptions,
  });

  final String ownerId;
  final String noteId;
  final NoteRepository noteRepository;
  final NoteLinkOptions linkOptions;

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late final Stream<Note?> _note = widget.noteRepository.watchNote(
    widget.noteId,
  );
  bool _isDeleting = false;

  void _openEdit(Note note) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteFormScreen(
          ownerId: widget.ownerId,
          noteRepository: widget.noteRepository,
          linkOptions: widget.linkOptions,
          noteToEdit: note,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Brisanje bilješke'),
        content: Text('Želite li obrisati bilješku „${note.title}”?'),
        actions: [
          TextButton(
            key: NoteKeys.deleteCancel,
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Odustani'),
          ),
          TextButton(
            key: NoteKeys.deleteConfirm,
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isDeleting = true);
    try {
      await widget.noteRepository.deleteNote(
        ownerId: widget.ownerId,
        noteId: note.id,
      );
      messenger
        ..removeCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Bilješka je obrisana.')));
      navigator.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      messenger
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              error is NoteException && error.message != null
                  ? error.message!
                  : 'Brisanje bilješke nije uspjelo.',
            ),
          ),
        );
    }
  }

  Widget _buildNote(BuildContext context, Note note) {
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: widget.linkOptions,
      builder: (context, _) {
        final parcel = widget.linkOptions.parcelLabel(note.parcelId);
        final crop = widget.linkOptions.cropLabel(note.cropId);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              note.title,
              key: NoteKeys.detailTitle,
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Ažurirano: ${formatShortDate(note.updatedAt.toDate())}',
              style: textTheme.bodySmall,
            ),
            if (parcel != null || crop != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (parcel != null)
                    Chip(
                      avatar: const Icon(Icons.landscape_outlined, size: 18),
                      label: Text(parcel),
                    ),
                  if (crop != null)
                    Chip(
                      avatar: const Icon(Icons.eco_outlined, size: 18),
                      label: Text(crop),
                    ),
                ],
              ),
            ],
            const Divider(height: 32),
            SelectableText(
              note.content,
              key: NoteKeys.detailContent,
              style: textTheme.bodyLarge,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Note?>(
      stream: _note,
      builder: (context, snapshot) {
        final note = snapshot.data;
        final Widget body;
        if (snapshot.connectionState == ConnectionState.waiting) {
          body = const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || note == null) {
          body = const Center(
            key: NoteKeys.detailNotFound,
            child: Text('Bilješka nije dostupna.'),
          );
        } else {
          body = _buildNote(context, note);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Bilješka'),
            actions: [
              if (note != null && !snapshot.hasError) ...[
                IconButton(
                  key: NoteKeys.edit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Uredi bilješku',
                  onPressed: _isDeleting ? null : () => _openEdit(note),
                ),
                IconButton(
                  key: NoteKeys.delete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Obriši bilješku',
                  onPressed: _isDeleting ? null : () => _confirmDelete(note),
                ),
              ],
            ],
          ),
          body: body,
        );
      },
    );
  }
}
