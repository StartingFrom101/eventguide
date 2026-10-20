
import 'package:cloud_firestore/cloud_firestore.dart';

class EventItem {
  final String id;
  final String title;
  final String description;
  final String location;
  final String category;
  final DateTime date;
  final String ownerId;
  final String creatorEmail;
  final String posterPath;

  const EventItem({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.date,
    required this.ownerId,
    required this.creatorEmail,
    this.posterPath = '',
  });

  factory EventItem.fromDocument(
      DocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final data = document.data() ?? {};

    final rawDate = data['date'];
    DateTime eventDate;

    if (rawDate is Timestamp) {
      eventDate = rawDate.toDate();
    } else if (rawDate is DateTime) {
      eventDate = rawDate;
    } else {
      eventDate = DateTime.now();
    }

    return EventItem(
      id: document.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      location: data['location'] as String? ?? '',
      category: data['category'] as String? ?? 'Other',
      date: eventDate,
      ownerId: data['ownerId'] as String? ?? '',
      creatorEmail: data['creatorEmail'] as String? ?? '',
      posterPath: data['posterPath'] as String? ?? '',
    );
  }
}
