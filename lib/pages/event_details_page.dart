
import 'package:flutter/material.dart';

import '../models/event_item.dart';
import '../utils/event_helpers.dart';
import '../widgets/local_poster.dart';

class EventDetailsPage extends StatelessWidget {
  final EventItem event;

  const EventDetailsPage({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: ListView(
        children: [
          LocalPoster(
            path: event.posterPath,
            height: 260,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Chip(
                  avatar: Icon(categoryIcon(event.category)),
                  label: Text(event.category),
                ),
                const SizedBox(height: 20),
                _detailRow(
                  Icons.calendar_month,
                  'Date and time',
                  formatEventDate(event.date),
                ),
                const SizedBox(height: 16),
                _detailRow(
                  Icons.location_on_outlined,
                  'Location',
                  event.location,
                ),
                if (event.creatorEmail.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _detailRow(
                    Icons.person_outline,
                    'Organizer',
                    event.creatorEmail,
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'About this event',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  event.description.isEmpty
                      ? 'No description provided.'
                      : event.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.deepPurple),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(value.isEmpty ? 'Not provided' : value),
            ],
          ),
        ),
      ],
    );
  }
}
