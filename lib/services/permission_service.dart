import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // 🔹 Pede permissões de localização em 2 passos
  static Future<bool> requestLocationPermissions() async {
    // 1. Primeiro pede localização quando em uso
    var statusWhenInUse = await Permission.locationWhenInUse.request();

    if (statusWhenInUse.isGranted) {
      // 2. Depois pede background (necessário para geofencing)
      var statusAlways = await Permission.locationAlways.request();

      if (statusAlways.isGranted) {
        return true;
      } else {
        print("⚠️ Utilizador aceitou 'quando em uso', mas recusou 'sempre'.");
        return true; // Permite geofencing enquanto app está aberta
      }
    } else {
      print("❌ Permissão de localização negada.");
      return false;
    }
  }

  // 🔹 Pede permissões de notificações
  static Future<void> requestNotificationPermissions() async {
    final status = await Permission.notification.request();
    if (!status.isGranted) {
      print("⚠️ Utilizador recusou notificações.");
    }
  }
}
