import 'package:flutter/material.dart';
import 'geofencing.dart';
import 'services/itinerary_service.dart';
import 'services/poi_service.dart';
import 'models/itinerary.dart';
import 'models/poi.dart';
import 'add_poi_page.dart';
import 'map_page.dart'; // 👈 Tours com rotas
import 'free_map_page.dart'; // 👈 Modo livre fullscreen
import 'services/auth_service.dart';
import 'login_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = false;

  /// 👉 Ativar itinerário e abrir o mapa com rotas
  Future<void> _activateItinerary(Itinerary itinerary) async {
    setState(() => _loading = true);

    final pois = await POIService.getPOIsByIds(itinerary.pois);
    await GeofencingService.startWithPOIs(pois);

    setState(() => _loading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Tour '${itinerary.titulo}' iniciado (${pois.length} POIs)"),
        ),
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MapPage(pois: pois), // 👈 sempre com rotas
        ),
      );
    }
  }

  /// 👉 Logout
  Future<void> _logout(BuildContext context) async {
    await AuthService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  /// 👉 Ações do menu superior
  void _onMenuSelected(String value) async {
    switch (value) {
      case "perfil":
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        break;
      case "mapa":
        // Abrir mapa em modo livre (fullscreen, sem rotas)
        final pois = await POIService.getAllPOIs();
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FreeMapPage(pois: pois),
            ),
          );
        }
        break;
      case "logout":
        _logout(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AzoresTour"),
        actions: [
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "mapa",
                child: ListTile(
                  leading: Icon(Icons.map),
                  title: Text("Mapa"),
                ),
              ),
              const PopupMenuItem(
                value: "perfil",
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text("Perfil"),
                ),
              ),
              const PopupMenuItem(
                value: "logout",
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text("Sair"),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Itinerary>>(
              future: ItineraryService.getItineraries(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child:
                        Text("Erro ao carregar itinerários: ${snapshot.error}"),
                  );
                }

                final itinerarios = snapshot.data ?? [];
                if (itinerarios.isEmpty) {
                  return const Center(
                      child: Text("Nenhum itinerário disponível."));
                }

                return ListView.builder(
                  itemCount: itinerarios.length,
                  itemBuilder: (context, index) {
                    final it = itinerarios[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            it.imagemUrl != null
                                ? Image.network(it.imagemUrl!,
                                    width: 60, fit: BoxFit.cover)
                                : const Icon(Icons.map),
                            const SizedBox(width: 8),
                            Icon(
                              it.categoria == "car"
                                  ? Icons.directions_car
                                  : Icons.directions_walk,
                              color: Colors.teal,
                            ),
                          ],
                        ),
                        title: Text(it.titulo),
                        subtitle: Text(
                          "${it.descricao ?? ""}"
                          "${it.duracaoEstimada != null ? "\nDuração: ${it.duracaoEstimada} min" : ""}",
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _activateItinerary(it),
                          child: const Text("Fazer Tour"),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddPOIPage()),
          );
        },
        child: const Icon(Icons.add_location_alt),
      ),
    );
  }
}
