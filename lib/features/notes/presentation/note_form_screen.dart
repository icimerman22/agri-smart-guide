import 'package:flutter/material.dart';

import '../../../shared/models/note.dart';
import '../../../shared/widgets/app_button.dart';
import '../domain/note_repository.dart';
import '../domain/note_validators.dart';
import 'note_keys.dart';
import 'note_link_options.dart';

class NoteFormScreen extends StatefulWidget {
  const NoteFormScreen({
    super.key,
    required this.ownerId,
    required this.noteRepository,
    required this.linkOptions,
    this.noteToEdit,
  });

  final String ownerId;
  final NoteRepository noteRepository;
  final NoteLinkOptions linkOptions;
  final Note? noteToEdit;

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.noteToEdit?.title);
  late final _content = TextEditingController(text: widget.noteToEdit?.content);
  late String? _parcelId = widget.noteToEdit?.parcelId;
  late String? _cropId = widget.noteToEdit?.cropId;
  bool _parcelRemoved = false;
  bool _cropRemoved = false;
  bool _isSaving = false;
  String? _saveError;

  NoteLinkOptions get _links => widget.linkOptions;
  bool get _isEditing => widget.noteToEdit != null;
  bool get _linksReady =>
      (_links.plotsLoaded || _links.plotsFailed) &&
      (_links.cropsLoaded || _links.cropsFailed);

  @override
  void initState() {
    super.initState();
    _dropMissingLinks();
    _links.addListener(_onLinksChanged);
  }

  @override
  void dispose() {
    _links.removeListener(_onLinksChanged);
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  void _onLinksChanged() => setState(_dropMissingLinks);

  void _dropMissingLinks() {
    final parcelId = _parcelId;
    if (parcelId != null &&
        _links.plotsLoaded &&
        !_links.plots.any((plot) => plot.id == parcelId)) {
      _parcelId = null;
      _parcelRemoved = true;
    }
    final cropId = _cropId;
    if (cropId != null &&
        _links.cropsLoaded &&
        !_links.crops.any((crop) => crop.id == cropId)) {
      _cropId = null;
      _cropRemoved = true;
    }
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    final draft = NoteDraft(
      title: _title.text,
      content: _content.text,
      parcelId: _parcelId,
      cropId: _cropId,
    );
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      final note = widget.noteToEdit;
      if (note == null) {
        await widget.noteRepository.createNote(
          ownerId: widget.ownerId,
          draft: draft,
        );
      } else {
        await widget.noteRepository.updateNote(
          ownerId: widget.ownerId,
          noteId: note.id,
          draft: draft,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = error is NoteException && error.message != null
            ? error.message
            : 'Spremanje bilješke nije uspjelo.';
      });
      return;
    }

    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Bilješka je ažurirana.' : 'Bilješka je spremljena.',
          ),
        ),
      );
    if (mounted && ModalRoute.isCurrentOf(context) == true) {
      Navigator.pop(context);
    }
  }

  Widget _buildLinkField({
    required Key fieldKey,
    required String label,
    required String emptyLabel,
    required IconData icon,
    required List<({String id, String name})> options,
    required String? value,
    required bool failed,
    required String? helperText,
    required ValueChanged<String?> onChanged,
  }) {
    return KeyedSubtree(
      key: ValueKey('$failed:${options.map((option) => option.id).join(',')}'),
      child: DropdownButtonFormField<String?>(
        key: fieldKey,
        initialValue: failed ? null : value,
        isExpanded: true,
        hint: Text(emptyLabel),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          helperText: helperText,
          helperMaxLines: 2,
        ),
        items: [
          DropdownMenuItem<String?>(value: null, child: Text(emptyLabel)),
          for (final option in options)
            DropdownMenuItem<String?>(
              value: option.id,
              child: Text(option.name, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: _isSaving || failed ? null : onChanged,
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        key: NoteKeys.form,
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            key: NoteKeys.titleField,
            controller: _title,
            enabled: !_isSaving,
            decoration: const InputDecoration(labelText: 'Naslov'),
            maxLength: NoteValidators.maxTitleLength,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            validator: NoteValidators.title,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: NoteKeys.contentField,
            controller: _content,
            enabled: !_isSaving,
            decoration: const InputDecoration(
              labelText: 'Sadržaj',
              alignLabelWithHint: true,
            ),
            maxLength: NoteValidators.maxContentLength,
            minLines: 5,
            maxLines: 12,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            validator: NoteValidators.content,
          ),
          const SizedBox(height: 12),
          _buildLinkField(
            fieldKey: NoteKeys.parcelField,
            label: 'Parcela (opcionalno)',
            emptyLabel: 'Bez parcele',
            icon: Icons.landscape_outlined,
            options: [
              for (final plot in _links.plots) (id: plot.id, name: plot.name),
            ],
            value: _parcelId,
            failed: _links.plotsFailed,
            helperText: _links.plotsFailed
                ? 'Parcele nije moguće učitati. Postojeća poveznica ostaje nepromijenjena.'
                : _parcelRemoved
                ? 'Prethodno povezana parcela je obrisana.'
                : null,
            onChanged: (value) => setState(() {
              _parcelId = value;
              _parcelRemoved = false;
            }),
          ),
          const SizedBox(height: 12),
          _buildLinkField(
            fieldKey: NoteKeys.cropField,
            label: 'Kultura (opcionalno)',
            emptyLabel: 'Bez kulture',
            icon: Icons.eco_outlined,
            options: [
              for (final crop in _links.crops) (id: crop.id, name: crop.name),
            ],
            value: _cropId,
            failed: _links.cropsFailed,
            helperText: _links.cropsFailed
                ? 'Kulture nije moguće učitati. Postojeća poveznica ostaje nepromijenjena.'
                : _cropRemoved
                ? 'Prethodno povezana kultura više ne postoji u katalogu.'
                : null,
            onChanged: (value) => setState(() {
              _cropId = value;
              _cropRemoved = false;
            }),
          ),
          const SizedBox(height: 32),
          if (_saveError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _saveError!,
                  key: NoteKeys.saveError,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          AppButton(
            key: NoteKeys.save,
            text: _isSaving ? 'Spremanje…' : 'Spremi',
            icon: Icons.check,
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Uredi bilješku' : 'Nova bilješka'),
      ),
      body: _linksReady
          ? _buildForm(context)
          : const Center(
              key: NoteKeys.formLoading,
              child: CircularProgressIndicator(),
            ),
    );
  }
}
