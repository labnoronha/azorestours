import 'package:flutter/foundation.dart';
import 'package:geofence_foreground_service/geofence_foreground_service.dart';
import 'package:geofence_foreground_service/constants/geofence_event_type.dart';
import 'package:geofence_foreground_service/models/zone.dart';
import 'package:latlng/latlng.dart';

import 'models/poi.dart';
import 'services/poi_service.dart';
import 'services/notification_service.dart';
import 'services/permission_service.dart';

@pragma('vm:entry-point')
void geofenceCallbackDispatcher() {
  GeofenceForegroundService().handleTrigger(
    backgroundTriggerHandler: (String zoneId, GeofenceEventType event) async {
      final txt = switch (event) {
        GeofenceEventType.enter => 'Entrou',
        GeofenceEventType.exit => 'Saiu',
        GeofenceEventType.dwell => 'Permanece',
        GeofenceEventType.unKnown => 'Desconhecido',
      };

      debugPrint("📍 [BG] Geofence $zoneId → $txt");

      try {
        final pois = await POIService.getAllPOIs();

        // 🔹 procurar de forma segura (pode não existir)
        final poi = pois.where((p) => p.id == zoneId).isNotEmpty
            ? pois.firstWhere((p) => p.id == zoneId)
            : null;

        if (poi != null && event == GeofenceEventType.enter) {
          await NotificationService.showPOI(
            'Estás perto: ${poi.titulo}',
            poi.descricao ?? '',
            poiId: poi.id,
          );
        } else {
          debugPrint("⚠️ POI $zoneId não encontrado no Firestore");
        }
      } catch (e, st) {
        debugPrint("⚠️ Erro no callback de geofencing → $e\n$st");
      }

      return true; // garante que o serviço não rebenta
    },
  );
}

class GeofencingService {
  static final GeofenceForegroundService _service =
      GeofenceForegroundService();

  /// Ativa geofencing para uma lista de POIs
  static Future<void> startWithPOIs(List<POI> pois) async {
    final zones = pois.map((p) {
      return Zone(
        id: p.id,
        radius: p.raio,
        coordinates: [LatLng.degree(p.lat, p.lng)],
        triggers: [GeofenceEventType.enter],
        initialTrigger: GeofenceEventType.enter,
      );
    }).toList();

    // Reinicia serviço sempre limpo
    await _service.stopGeofencingService();
    await _service.startGeofencingService(
      notificationChannelId: "azorestour_channel",
      contentTitle: "AzoresTour ativo",
      contentText: "Monitorização de zonas",
      callbackDispatcher: geofenceCallbackDispatcher,
    );

    for (final z in zones) {
      await _service.addGeofenceZone(zone: z);
    }

    debugPrint("✅ Geofencing iniciado com ${zones.length} zonas");
  }

  /// Modo livre → ativa todos os POIs
  static Future<void> startAllPOIs() async {
    try {
      // 🔹 Garante permissões antes de iniciar
      final hasPermission = await PermissionService.requestLocationPermissions();
      if (!hasPermission) {
        debugPrint("❌ Geofencing não iniciado: sem permissões de localização.");
        return;
      }

      final pois = await POIService.getAllPOIs();
      if (pois.isEmpty) {
        debugPrint("⚠️ Nenhum POI disponível.");
        return;
      }

      await startWithPOIs(pois);
    } catch (e, st) {
      debugPrint("⚠️ Erro ao iniciar geofencing com todos os POIs → $e\n$st");
    }
  }

  /// Para o serviço manualmente
  static Future<void> stop() async {
    try {
      await _service.stopGeofencingService();
      debugPrint("🛑 Geofencing parado.");
    } catch (e) {
      debugPrint("⚠️ Erro ao parar geofencing → $e");
    }
  }
}
