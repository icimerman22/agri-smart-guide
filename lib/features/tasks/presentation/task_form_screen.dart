import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../shared/formatters/date_format.dart';
import '../../../shared/models/farm_task.dart';
import '../../../shared/widgets/app_button.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({
    super.key,
    required this.ownerId,
    required this.onSave,
    this.taskToEdit,
  });

  final String ownerId;
  final Future<void> Function(FarmTask) onSave;
  final FarmTask? taskToEdit;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateKey = GlobalKey<FormFieldState<Timestamp>>();
  late final _title = TextEditingController(text: widget.taskToEdit?.title);
  late final _description = TextEditingController(
    text: widget.taskToEdit?.description,
  );
  bool _isSaving = false;
  bool _saveFailed = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate(FormFieldState<Timestamp> field) async {
    final today = DateTime.now();
    final initial = field.value?.toDate().toUtc() ?? today;
    final firstDate = DateTime(today.year - 100);
    final lastDate = DateTime(today.year + 100, 12, 31);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: initial.isBefore(firstDate) ? initial : firstDate,
      lastDate: initial.isAfter(lastDate) ? initial : lastDate,
      helpText: 'Odaberite datum zadatka',
      cancelText: 'Odustani',
      confirmText: 'Potvrdi',
    );
    if (!field.mounted || picked == null) return;

    field.didChange(
      Timestamp.fromDate(DateTime.utc(picked.year, picked.month, picked.day)),
    );
    field.validate();
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    final existing = widget.taskToEdit;
    final now = Timestamp.now();
    final task = FarmTask(
      id: existing?.id ?? '',
      ownerId: widget.ownerId,
      parcelId: existing?.parcelId,
      title: _title.text.trim(),
      description: _description.text.trim(),
      type: existing?.type ?? 'general',
      dueAt: _dateKey.currentState!.value!,
      priority: existing?.priority ?? 'normal',
      status: existing?.status ?? FarmTask.pendingStatus,
      completedAt: existing?.completedAt,
      costCents: existing?.costCents,
      costCategory: existing?.costCategory,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    setState(() {
      _isSaving = true;
      _saveFailed = false;
    });
    try {
      await widget.onSave(task);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveFailed = true;
      });
      return;
    }
    if (mounted && ModalRoute.isCurrentOf(context) == true) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.taskToEdit == null ? 'Novi zadatak' : 'Uredi zadatak',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              enabled: !_isSaving,
              decoration: const InputDecoration(labelText: 'Naziv'),
              textInputAction: TextInputAction.next,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Unesite naziv zadatka.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              enabled: !_isSaving,
              decoration: const InputDecoration(labelText: 'Opis (opcionalno)'),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            FormField<Timestamp>(
              key: _dateKey,
              initialValue: widget.taskToEdit?.dueAt,
              validator: (value) => value == null ? 'Odaberite datum.' : null,
              builder: (field) {
                final date = field.value?.toDate().toUtc();
                return InkWell(
                  onTap: _isSaving ? null : () => _pickDate(field),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Datum',
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                      errorText: field.errorText,
                      enabled: !_isSaving,
                    ),
                    child: Text(
                      date == null ? 'Odaberite datum' : formatShortDate(date),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            if (_saveFailed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    'Spremanje zadatka nije uspjelo.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            AppButton(
              text: _isSaving ? 'Spremanje…' : 'Spremi',
              icon: Icons.check,
              onPressed: _isSaving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
