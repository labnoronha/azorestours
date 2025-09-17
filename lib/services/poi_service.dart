import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/poi.dart';

class POIService {
  static final _db = FirebaseFirestore.instance;

  /// Buscar todos os POIs (para Modo Livre)
  static Future<List<POI>> getAllPOIs() async {
    final snapshot = await _db.collection('pois').get();
    return snapshot.docs
        .map((d) => POI.fromFirestore(d.id, d.data()))
        .toList();
  }

  /// Buscar POIs por lista de IDs (para itinerários)
  static Future<List<POI>> getPOIsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snapshot = await _db
        .collection('pois')
        .where(FieldPath.documentId, whereIn: ids)
        .get();
    return snapshot.docs
        .map((d) => POI.fromFirestore(d.id, d.data()))
        .toList();
  }

  /// Stream em tempo real de todos os POIs (se precisares de live updates no mapa)
  static Stream<List<POI>> streamPOIs() {
    return _db.collection('pois').snapshots().map(
          (snap) =>
              snap.docs.map((d) => POI.fromFirestore(d.id, d.data())).toList(),
        );
  }
}
