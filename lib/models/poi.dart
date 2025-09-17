class POI {
  final String id;
  final String titulo;
  final double lat, lng;
  final double raio;
  final String descricao;       // 🔹 Agora sempre não nulo
  final String? imagemUrl;
  final String? audioUrl;
  final String trigger;
  final String? categoria;
  final List<String>? tags;

  const POI({
    required this.id,
    required this.titulo,
    required this.lat,
    required this.lng,
    this.raio = 150,
    this.descricao = "",        // 🔹 Default vazio
    this.imagemUrl,
    this.audioUrl,
    this.trigger = 'enter',
    this.categoria,
    this.tags,
  });

  factory POI.fromFirestore(String id, Map<String, dynamic> data) {
    return POI(
      id: id,
      titulo: data['titulo'] ?? '',
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      raio: (data['raio'] as num?)?.toDouble() ?? 150,
      descricao: data['descricao'] ?? "",  // 🔹 nunca fica null
      imagemUrl: data['imagemUrl'],
      audioUrl: data['audioUrl'],
      trigger: data['trigger'] ?? 'enter',
      categoria: data['categoria'],
      tags: data['tags'] != null
          ? List<String>.from(data['tags'] as List<dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'titulo': titulo,
        'lat': lat,
        'lng': lng,
        'raio': raio,
        'descricao': descricao,
        'imagemUrl': imagemUrl,
        'audioUrl': audioUrl,
        'trigger': trigger,
        'categoria': categoria,
        'tags': tags,
      };
}
