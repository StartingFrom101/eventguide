import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import 'event_form_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key, required this.user});
  final User user;

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final _events = EventService();
  String _query = '';

  Future<void> _delete(Event event) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text('“${event.title}” will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes == true && mounted) {
      try {
        await _events.delete(event.id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted')));
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not delete event')));
      }
    }
  }

  Future<void> _openForm([Event? event]) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EventFormScreen(user: widget.user, event: event),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Guide'),
        actions: [
          IconButton(tooltip: 'Sign out', onPressed: () => AuthService().signOut(),
            icon: const Icon(Icons.logout)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add event'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search events',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Event>>(
              stream: _events.watchEvents(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Could not load events. Check your Firebase setup and Firestore rules.'),
                  ));
                }
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final events = snapshot.data!.where((e) =>
                  e.title.toLowerCase().contains(_query) ||
                  e.description.toLowerCase().contains(_query) ||
                  e.location.toLowerCase().contains(_query)).toList();
                if (events.isEmpty) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.event_note, size: 54),
                      const SizedBox(height: 12),
                      Text(_query.isEmpty ? 'No events yet' : 'No matching events',
                        style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(_query.isEmpty ? 'Tap “Add event” to create the first one.' : 'Try another search.'),
                    ]),
                  ));
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96, top: 2),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Card(
                      child: InkWell(
                        onTap: () {
                          if (event.createdBy == widget.user.uid) {
                            _openForm(event);
                          } else {
                            showDialog<void>(context: context, builder: (_) => AlertDialog(
                              title: Text(event.title),
                              content: Text(event.description.isEmpty ? event.location : '${event.description}\\n\\n${event.location}'),
                              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                            ));
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Expanded(child: Text(event.title,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600))),
                              if (event.createdBy == widget.user.uid) PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') _openForm(event);
                                  if (v == 'delete') _delete(event);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit'))),
                                  PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete'))),
                                ],
                              ),
                            ]),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.calendar_month_outlined, size: 18),
                              const SizedBox(width: 7),
                              Expanded(child: Text(DateFormat('EEE, d MMM yyyy • h:mm a').format(event.startsAt))),
                            ]),
                            if (event.location.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Row(children: [
                                const Icon(Icons.location_on_outlined, size: 18),
                                const SizedBox(width: 7),
                                Expanded(child: Text(event.location)),
                              ]),
                            ],
                            if (event.description.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(event.description, maxLines: 3, overflow: TextOverflow.ellipsis),
                            ],
                          ]),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
