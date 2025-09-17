import 'package:geofence_foreground_service/models/zone.dart';
import 'package:geofence_foreground_service/constants/geofence_event_type.dart';
import 'package:latlng/latlng.dart';

/// Zonas de teste (Angra + Praia)
final List<Zone> sampleZones = [
  Zone(
    id: "angra_centro",
    radius: 200, // metros
    coordinates: [
      LatLng.degree(38.6533, -27.2204), // Centro de Angra do Heroísmo
    ],
    triggers: const [
      GeofenceEventType.enter,
      GeofenceEventType.exit,
      GeofenceEventType.dwell,
    ],
    initialTrigger: GeofenceEventType.enter,
  ),
  Zone(
    id: "praia_vitoria",
    radius: 250,
    coordinates: [
      LatLng.degree(38.7325, -27.0647), // Centro da Praia da Vitória
    ],
    triggers: const [
      GeofenceEventType.enter,
      GeofenceEventType.exit,
    ],
    initialTrigger: GeofenceEventType.enter,
  ),
];
