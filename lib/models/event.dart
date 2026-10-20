import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startsAt,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startsAt;
  final String createdBy;
  final DateTime? createdAt;

  factory Event.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final start = data['startsAt'];
    final created = data['createdAt'];
    return Event(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      location: (data['location'] ?? '') as String,
      startsAt: start is Timestamp ? start.toDate() : DateTime.now(),
      createdBy: (data['createdBy'] ?? '') as String,
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title.trim(),
    'description': description.trim(),
    'location': location.trim(),
    'startsAt': Timestamp.fromDate(startsAt),
    'createdBy': createdBy,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
