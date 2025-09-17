class Itinerary {
  final String id;
  final String titulo;
  final String? descricao;
  final List<String> pois;
  final String? imagemUrl;

  /// 🔹 categoria = "walk" ou "car"
  final String? categoria;

  /// 🔹 duração em minutos (guardado como Number no Firestore)
  final int? duracaoEstimada;

  const Itinerary({
    required this.id,
    required this.titulo,
    required this.pois,
    this.descricao,
    this.imagemUrl,
    this.categoria,
    this.duracaoEstimada,
  });

  factory Itinerary.fromFirestore(String id, Map<String, dynamic> data) {
    return Itinerary(
      id: id,
      titulo: data['titulo'] ?? '',
      descricao: data['descricao'],
      pois: data['pois'] != null
          ? List<String>.from(data['pois'] as List<dynamic>)
          : <String>[],
      imagemUrl: data['imagemUrl'],
      categoria: data['categoria'],
      duracaoEstimada: data['duracaoEstimada'] != null
          ? (data['duracaoEstimada'] as num).toInt()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'titulo': titulo,
        'descricao': descricao,
        'pois': pois,
        'imagemUrl': imagemUrl,
        'categoria': categoria,
        'duracaoEstimada': duracaoEstimada,
      };
}
