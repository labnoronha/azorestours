import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TopicPrefs {
  // 🔹 Define os tópicos disponíveis (podes personalizar depois)
  static const topics = <String>[
    'ilha_terceira',
    'ilha_sao_miguel',
    'ilha_pico',
    'tema_cultura',
    'tema_aventura',
    'tema_gastronomia',
  ];

  /// Subscreve ou remove subscrição de um tópico
  static Future<void> setSubscribed(String topic, bool subscribe) async {
    if (subscribe) {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } else {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    }

    final sp = await SharedPreferences.getInstance();
    await sp.setBool('topic_$topic', subscribe);
  }

  /// Verifica se o utilizador já está subscrito
  static Future<bool> isSubscribed(String topic) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool('topic_$topic') ?? false;
  }
}
