
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/event_item.dart';
import '../utils/event_helpers.dart';
import '../widgets/local_poster.dart';

class EventFormDialog extends StatefulWidget {
  final EventItem? event;

  const EventFormDialog({
    super.key,
    this.event,
  });

  @override
  State<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;

  late String _category;
  late DateTime _date;
  String _posterPath = '';
  bool _savingPoster = false;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();

    final event = widget.event;

    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController =
        TextEditingController(text: event?.description ?? '');
    _locationController =
        TextEditingController(text: event?.location ?? '');

    _category = event?.category ?? 'Other';
    _date = event?.date ?? DateTime.now().add(const Duration(days: 1));
    _posterPath = event?.posterPath ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _choosePoster() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image == null || !mounted) return;

      setState(() => _savingPoster = true);

      final directory = await getApplicationDocumentsDirectory();
      final posterDirectory = Directory('${directory.path}/event_posters');

      if (!await posterDirectory.exists()) {
        await posterDirectory.create(recursive: true);
      }

      final extension = image.path.contains('.')
          ? image.path.split('.').last
          : 'jpg';

      final filename =
          'poster_${DateTime.now().microsecondsSinceEpoch}.$extension';

      final savedFile = await File(image.path).copy(
        '${posterDirectory.path}/$filename',
      );

      if (mounted) {
        setState(() => _posterPath = savedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not select poster: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingPoster = false);
      }
    }
  }

  Future<void> _chooseDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );

    if (selectedTime == null || !mounted) return;

    setState(() {
      _date = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(<String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'location': _locationController.text.trim(),
      'category': _category,
      'date': Timestamp.fromDate(_date),
      'posterPath': _posterPath,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Event' : 'Create Event'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LocalPoster(
                    path: _posterPath,
                    height: 150,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _savingPoster ? null : _choosePoster,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                    _savingPoster ? 'Saving poster...' : 'Choose poster',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event title',
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Enter an event title.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Enter a location.'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  items: eventCategories
                      .where((category) => category != 'All')
                      .map(
                        (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _category = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month),
                  title: const Text('Date and time'),
                  subtitle: Text(formatEventDate(_date)),
                  onTap: _chooseDate,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _savingPoster
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _savingPoster ? null : _submit,
          child: Text(_isEditing ? 'Save changes' : 'Create'),
        ),
      ],
    );
  }
}
