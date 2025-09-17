import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/itinerary.dart';

class ItineraryService {
  static final _db = FirebaseFirestore.instance;

  static Future<List<Itinerary>> getItineraries() async {
    final snapshot = await _db.collection('itinerarios').get();
    return snapshot.docs
        .map((d) => Itinerary.fromFirestore(d.id, d.data()))
        .toList();
  }

  static Future<Itinerary?> getItinerary(String id) async {
    final doc = await _db.collection('itinerarios').doc(id).get();
    if (!doc.exists) return null;
    return Itinerary.fromFirestore(doc.id, doc.data()!);
  }

  static Stream<List<Itinerary>> streamItineraries() {
    return _db.collection('itinerarios').snapshots().map((snap) =>
        snap.docs.map((d) => Itinerary.fromFirestore(d.id, d.data())).toList());
  }
}
