import 'package:agri_smart_guide/features/crops/data/crop_catalog_data_source.dart';
import 'package:flutter/material.dart';

import '../../../shared/formatters/date_format.dart';
import '../../../shared/models/note.dart';
import '../../auth/domain/auth_service.dart';
import '../../plots/data/plot_repository.dart';
import '../domain/note_repository.dart';
import 'note_detail_screen.dart';
import 'note_form_screen.dart';
import 'note_keys.dart';
import 'note_link_options.dart';

class NoteListScreen extends StatefulWidget {
  const NoteListScreen({
    super.key,
    required this.authService,
    required this.ownerId,
    required this.noteRepository,
    required this.plotRepository,
    required this.cropDataSource,
  });

  final AuthService authService;
  final String ownerId;
  final NoteRepository noteRepository;
  final PlotRepository plotRepository;
  final CropCatalogDataSource cropDataSource;

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  late Stream<List<Note>> _notes = widget.noteRepository.watchNotes(
    widget.ownerId,
  );
  late final NoteLinkOptions _linkOptions;

  bool get _hasSession => widget.authService.currentUser?.uid == widget.ownerId;

  @override
  void initState() {
    super.initState();
    _linkOptions = NoteLinkOptions(
      ownerId: widget.ownerId,
      plotRepository: widget.plotRepository,
      cropDataSource: widget.cropDataSource,
    );
  }

  @override
  void dispose() {
    _linkOptions.dispose();
    super.dispose();
  }

  void _openDetail(Note note) {
    if (!_hasSession) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteDetailScreen(
          ownerId: widget.ownerId,
          noteId: note.id,
          noteRepository: widget.noteRepository,
          linkOptions: _linkOptions,
        ),
      ),
    );
  }

  void _openForm() {
    if (!_hasSession) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteFormScreen(
          ownerId: widget.ownerId,
          noteRepository: widget.noteRepository,
          linkOptions: _linkOptions,
        ),
      ),
    );
  }

  Widget _buildList(List<Note> notes) {
    if (notes.isEmpty) {
      return const Center(
        key: NoteKeys.listEmpty,
        child: Text('Nemate spremljenih bilješki.'),
      );
    }

    return ListenableBuilder(
      listenable: _linkOptions,
      builder: (context, _) => ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          final details = [
            formatShortDate(note.updatedAt.toDate()),
            ?_linkOptions.parcelLabel(note.parcelId),
            ?_linkOptions.cropLabel(note.cropId),
          ].join(' • ');
          return Card(
            key: NoteKeys.listItem(note.id),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.sticky_note_2_outlined),
              title: Text(
                note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '$details\n${note.content}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: true,
              onTap: () => _openDetail(note),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasSession) {
      return const Scaffold(
        body: Center(child: Text('Korisnik nije prijavljen.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bilješke')),
      body: StreamBuilder<List<Note>>(
        stream: _notes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              key: NoteKeys.listError,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Učitavanje bilješki nije uspjelo.'),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _notes = widget.noteRepository.watchNotes(widget.ownerId);
                    }),
                    child: const Text('Pokušaj ponovno'),
                  ),
                ],
              ),
            );
          }
          return _buildList(snapshot.data ?? const []);
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: NoteKeys.openForm,
        onPressed: _openForm,
        tooltip: 'Dodaj bilješku',
        child: const Icon(Icons.add),
      ),
    );
  }
}
