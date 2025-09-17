import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:audioplayers/audioplayers.dart';
import 'models/poi.dart';

enum PlayerState { stopped, playing, paused }

class FreeMapPage extends StatefulWidget {
  final List<POI> pois;

  const FreeMapPage({super.key, required this.pois});

  @override
  State<FreeMapPage> createState() => _FreeMapPageState();
}

class _FreeMapPageState extends State<FreeMapPage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? _currentLocation;

  StreamSubscription<Position>? _positionStream;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _ultimoPoiReproduzido;
  PlayerState _playerState = PlayerState.stopped;

  @override
  void initState() {
    super.initState();
    _loadMarkers();
    _iniciarTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _iniciarTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _atualizarLocalizacao(pos);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 20,
      ),
    ).listen((pos) => _atualizarLocalizacao(pos));
  }

  void _atualizarLocalizacao(Position pos) {
    LatLng novaLocalizacao = LatLng(pos.latitude, pos.longitude);
    setState(() => _currentLocation = novaLocalizacao);

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: novaLocalizacao,
            zoom: 16,
          ),
        ),
      );
    }

    _verificarPOI(novaLocalizacao);
  }

  void _verificarPOI(LatLng localizacao) {
    for (var poi in widget.pois) {
      double distancia = Geolocator.distanceBetween(
        localizacao.latitude,
        localizacao.longitude,
        poi.lat,
        poi.lng,
      );

      if (distancia <= poi.raio) {
        if (_ultimoPoiReproduzido != poi.id) {
          _ultimoPoiReproduzido = poi.id;
          _mostrarPopup(poi);
          _tocarAudio(poi);
        }
        break;
      }
    }
  }

  void _mostrarPopup(POI poi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (poi.imagemUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    poi.imagemUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                poi.titulo,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                poi.descricao ?? "Sem descrição disponível.",
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Fechar"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _tocarAudio(POI poi) async {
    try {
      if (poi.audioUrl != null && poi.audioUrl!.isNotEmpty) {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(poi.audioUrl!));
        setState(() => _playerState = PlayerState.playing);
      }
    } catch (_) {}
  }

  Future<void> _pausarAudio() async {
    try {
      await _audioPlayer.pause();
      setState(() => _playerState = PlayerState.paused);
    } catch (_) {}
  }

  Future<void> _retomarAudio() async {
    try {
      await _audioPlayer.resume();
      setState(() => _playerState = PlayerState.playing);
    } catch (_) {}
  }

  Future<void> _pararAudio() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _playerState = PlayerState.stopped;
        _ultimoPoiReproduzido = null;
      });
    } catch (_) {}
  }

  void _loadMarkers() {
    Set<Marker> markers = {};
    for (var poi in widget.pois) {
      markers.add(
        Marker(
          markerId: MarkerId(poi.id),
          position: LatLng(poi.lat, poi.lng),
          infoWindow: InfoWindow(title: poi.titulo),
        ),
      );
    }
    setState(() => _markers = markers);
  }

  @override
  Widget build(BuildContext context) {
    LatLng startPosition = widget.pois.isNotEmpty
        ? LatLng(widget.pois.first.lat, widget.pois.first.lng)
        : const LatLng(38.7169, -27.2361);

    return Scaffold(
      appBar: AppBar(title: const Text("Mapa (Modo Livre)")),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(target: startPosition, zoom: 12),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          // 🔹 Botões de controlo do áudio
          if (_playerState != PlayerState.stopped)
            Positioned(
              bottom: 80, // 👈 mais acima para não colidir com os botões do sistema
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_playerState == PlayerState.playing) ...[
                    FloatingActionButton(
                      heroTag: "pauseBtn",
                      mini: true,
                      onPressed: _pausarAudio,
                      child: const Icon(Icons.pause),
                    ),
                    const SizedBox(width: 16),
                    FloatingActionButton(
                      heroTag: "stopBtn",
                      mini: true,
                      backgroundColor: Colors.red,
                      onPressed: _pararAudio,
                      child: const Icon(Icons.stop),
                    ),
                  ] else if (_playerState == PlayerState.paused) ...[
                    FloatingActionButton(
                      heroTag: "playBtn",
                      mini: true,
                      onPressed: _retomarAudio,
                      child: const Icon(Icons.play_arrow),
                    ),
                    const SizedBox(width: 16),
                    FloatingActionButton(
                      heroTag: "stopBtn",
                      mini: true,
                      backgroundColor: Colors.red,
                      onPressed: _pararAudio,
                      child: const Icon(Icons.stop),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
