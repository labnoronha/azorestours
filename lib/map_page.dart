import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'models/poi.dart';

enum PlayerState { stopped, playing, paused }

class MapPage extends StatefulWidget {
  final List<POI> pois;
  final String apiKey;
  final bool calcularRotas; // 👈 controla se calcula rotas ou só mostra markers

  const MapPage({
    super.key,
    required this.pois,
    this.apiKey = "AIzaSyBnptOXcNQKkjlnjdR0vWc2NYiArh2j8Xo",
    this.calcularRotas = true,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  String _rotaInfo = "";
  LatLng? _currentLocation;

  StreamSubscription<Position>? _positionStream;
  double _lastBearing = 0.0;
  LatLng? _ultimaLocalizacao;

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

    double bearing = pos.heading;
    if (bearing < 0 && _ultimaLocalizacao != null) {
      bearing = Geolocator.bearingBetween(
        _ultimaLocalizacao!.latitude,
        _ultimaLocalizacao!.longitude,
        novaLocalizacao.latitude,
        novaLocalizacao.longitude,
      );
    }
    if (bearing.isNaN) bearing = _lastBearing;

    _ultimaLocalizacao = novaLocalizacao;
    _lastBearing = bearing;

    setState(() => _currentLocation = novaLocalizacao);

    if (widget.calcularRotas) {
      _calcularRota();
    }

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: novaLocalizacao,
            zoom: 16,
            tilt: 45,
            bearing: bearing,
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
          infoWindow: InfoWindow(title: poi.titulo, snippet: poi.descricao),
        ),
      );
    }
    setState(() => _markers = markers);
  }

  Future<void> _calcularRota() async {
    if (widget.pois.isEmpty) return;

    LatLng origem = _currentLocation ??
        LatLng(widget.pois.first.lat, widget.pois.first.lng);
    List<LatLng> destinos =
        widget.pois.map((poi) => LatLng(poi.lat, poi.lng)).toList();

    String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${origem.latitude},${origem.longitude}&destination=${destinos.last.latitude},${destinos.last.longitude}&key=${widget.apiKey}&mode=driving";

    if (destinos.length > 1) {
      String waypoints = destinos
          .sublist(0, destinos.length - 1)
          .map((e) => "${e.latitude},${e.longitude}")
          .join("|");
      url += "&waypoints=$waypoints";
    }

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data["status"] != "OK") return;

      List<LatLng> polylinePoints = [];
      int totalDuration = 0;
      int totalDistance = 0;

      if (data["routes"].isNotEmpty) {
        var route = data["routes"][0];
        for (var leg in route["legs"]) {
          totalDuration += (leg["duration"]["value"] as num).toInt();
          totalDistance += (leg["distance"]["value"] as num).toInt();
        }
        polylinePoints = _decodePolyline(route["overview_polyline"]["points"]);
      }

      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId("rota"),
            color: Colors.blue,
            width: 5,
            points: polylinePoints,
          )
        };
        _rotaInfo =
            "⏱ ${(totalDuration / 60).toStringAsFixed(0)} min | 📍 ${(totalDistance / 1000).toStringAsFixed(1)} km";
      });
    } catch (_) {}
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    LatLng startPosition = widget.pois.isNotEmpty
        ? LatLng(widget.pois.first.lat, widget.pois.first.lng)
        : const LatLng(38.7169, -27.2361);

    return Scaffold(
      appBar: AppBar(title: const Text("Mapa (Tour)")),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: GoogleMap(
              onMapCreated: (controller) => _mapController = controller,
              initialCameraPosition:
                  CameraPosition(target: startPosition, zoom: 12),
              markers: _markers,
              polylines: widget.calcularRotas ? _polylines : {},
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                if (widget.calcularRotas && _rotaInfo.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _rotaInfo,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                if (_playerState != PlayerState.stopped)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_playerState == PlayerState.playing) ...[
                        IconButton(
                          icon: const Icon(Icons.pause, size: 32),
                          onPressed: _pausarAudio,
                        ),
                        IconButton(
                          icon: const Icon(Icons.stop, size: 32),
                          onPressed: _pararAudio,
                        ),
                      ] else if (_playerState == PlayerState.paused) ...[
                        IconButton(
                          icon: const Icon(Icons.play_arrow, size: 32),
                          onPressed: _retomarAudio,
                        ),
                        IconButton(
                          icon: const Icon(Icons.stop, size: 32),
                          onPressed: _pararAudio,
                        ),
                      ],
                    ],
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24), // 👈 margem extra
                    itemCount: widget.pois.length,
                    itemBuilder: (context, index) {
                      final poi = widget.pois[index];
                      return ListTile(
                        title: Text(poi.titulo),
                        subtitle: Text(poi.descricao),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
