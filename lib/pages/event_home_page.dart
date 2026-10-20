
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/event_item.dart';
import '../utils/event_helpers.dart';
import '../widgets/event_card.dart';
import 'event_details_page.dart';
import 'event_form_dialog.dart';

class EventHomePage extends StatefulWidget {
  final bool readOnly;

  const EventHomePage({
    super.key,
    this.readOnly = false,
  });

  @override
  State<EventHomePage> createState() => _EventHomePageState();
}

class _EventHomePageState extends State<EventHomePage> {
  final _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  int _selectedTab = 0;
  bool _busy = false;

  final CollectionReference<Map<String, dynamic>> _events =
  FirebaseFirestore.instance.collection('events');

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(EventItem event) {
    final query = _searchQuery.toLowerCase();

    final matchesQuery = query.isEmpty ||
        event.title.toLowerCase().contains(query) ||
        event.description.toLowerCase().contains(query) ||
        event.location.toLowerCase().contains(query) ||
        event.category.toLowerCase().contains(query);

    final matchesCategory = _selectedCategory == 'All' ||
        event.category == _selectedCategory;

    final matchesTab = _selectedTab == 0 ||
        event.ownerId == _currentUser?.uid;

    return matchesQuery && matchesCategory && matchesTab;
  }

  Future<void> _openEventForm({EventItem? event}) async {
    if (widget.readOnly || _busy) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => EventFormDialog(event: event),
    );

    if (result == null || !mounted) return;

    final user = _currentUser;

    if (user == null || user.isAnonymous) return;

    setState(() => _busy = true);

    try {
      if (event == null) {
        await _events.add({
          ...result,
          'ownerId': user.uid,
          'creatorEmail': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        if (event.ownerId != user.uid) {
          throw Exception('You can only edit your own events.');
        }

        await _events.doc(event.id).update(result);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            event == null
                ? 'Event created successfully.'
                : 'Event updated successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save event: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteEvent(EventItem event) async {
    final user = _currentUser;

    if (widget.readOnly ||
        user == null ||
        user.isAnonymous ||
        event.ownerId != user.uid) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text(
          'Are you sure you want to delete "${event.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _events.doc(event.id).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete event: $e')),
      );
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  void _openDetails(EventItem event) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EventDetailsPage(event: event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Guide'),
        actions: [
          if (widget.readOnly)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Chip(
                  avatar: Icon(Icons.visibility_outlined, size: 18),
                  label: Text('Guest'),
                ),
              ),
            ),
          PopupMenuButton<String>(
            tooltip: 'Account options',
            onSelected: (value) {
              if (value == 'signout') _signOut();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  _currentUser?.email ??
                      (widget.readOnly ? 'Guest account' : 'Account'),
                ),
              ),
              const PopupMenuItem(
                value: 'signout',
                child: Text('Sign out'),
              ),
            ],
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value.trim());
              },
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(Icons.clear),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 54,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              scrollDirection: Axis.horizontal,
              itemCount: eventCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = eventCategories[index];

                return ChoiceChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (_) {
                    setState(() => _selectedCategory = category);
                  },
                );
              },
            ),
          ),
          if (!widget.readOnly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('Explore'),
                    icon: Icon(Icons.explore_outlined),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('My Events'),
                    icon: Icon(Icons.event_note),
                  ),
                ],
                selected: {_selectedTab},
                onSelectionChanged: (selection) {
                  setState(() => _selectedTab = selection.first);
                },
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _events
                  .orderBy('date', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load events.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final allEvents = snapshot.data!.docs
                    .map(EventItem.fromDocument)
                    .toList();

                final filteredEvents = allEvents
                    .where(_matches)
                    .toList();

                if (filteredEvents.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.event_busy,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedTab == 1
                                ? 'You have not created any events yet.'
                                : 'No events found.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Try another search or category.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    final canManage = !widget.readOnly &&
                        _currentUser != null &&
                        !_currentUser!.isAnonymous &&
                        event.ownerId == _currentUser!.uid;

                    return EventCard(
                      event: event,
                      canManage: canManage,
                      onTap: () => _openDetails(event),
                      onEdit: canManage
                          ? () => _openEventForm(event: event)
                          : null,
                      onDelete: canManage
                          ? () => _deleteEvent(event)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.readOnly
          ? null
          : FloatingActionButton.extended(
        onPressed: _busy ? null : () => _openEventForm(),
        icon: const Icon(Icons.add),
        label: const Text('Create Event'),
      ),
    );
  }
}
