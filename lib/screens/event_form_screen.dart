import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/event_service.dart';

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key, required this.user, this.event});
  final User user;
  final Event? event;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _service = EventService();
  late DateTime _startsAt;
  bool _saving = false;

  bool get _editing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _title.text = event?.title ?? '';
    _description.text = event?.description ?? '';
    _location.text = event?.location ?? '';
    _startsAt = event?.startsAt ?? DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _chooseDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (time == null || !mounted) return;
    setState(() => _startsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final event = Event(
        id: widget.event?.id ?? '',
        title: _title.text,
        description: _description.text,
        location: _location.text,
        startsAt: _startsAt,
        createdBy: widget.event?.createdBy ?? widget.user.uid,
        createdAt: widget.event?.createdAt,
      );
      if (_editing) {
        await _service.update(event);
      } else {
        await _service.create(event);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Check your connection and Firestore rules.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit event' : 'New event')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Event title *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter an event title.' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _location,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 18),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Date and time'),
                  subtitle: Text(MaterialLocalizations.of(context).formatFullDate(_startsAt) +
                    ' • ' + TimeOfDay.fromDateTime(_startsAt).format(context)),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: _chooseDateTime,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving…' : 'Save event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
