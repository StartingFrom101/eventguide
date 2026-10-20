import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class EventService {
  EventService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('events');

  Stream<List<Event>> watchEvents() => _events
      .orderBy('startsAt')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Event.fromDocument).toList());

  Future<void> create(Event event) async {
    await _events.add(event.toMap());
  }

  Future<void> update(Event event) async {
    await _events.doc(event.id).update({
      'title': event.title.trim(),
      'description': event.description.trim(),
      'location': event.location.trim(),
      'startsAt': Timestamp.fromDate(event.startsAt),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) => _events.doc(id).delete();
}
