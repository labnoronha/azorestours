import 'package:flutter/material.dart';
import 'topic_prefs.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, bool> _values = {for (final t in TopicPrefs.topics) t: false};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    for (final t in _values.keys) {
      _values[t] = await TopicPrefs.isSubscribed(t);
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notificações por tópicos')),
      body: ListView(
        children: _values.keys.map((t) {
          return SwitchListTile(
            title: Text(t.replaceAll('_', ' ').toUpperCase()),
            value: _values[t]!,
            onChanged: (v) async {
              setState(() => _values[t] = v);
              await TopicPrefs.setSubscribed(t, v);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(v ? 'Subscrito: $t' : 'Removido: $t')),
                );
              }
            },
          );
        }).toList(),
      ),
    );
  }
}
