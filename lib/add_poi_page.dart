import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddPOIPage extends StatefulWidget {
  const AddPOIPage({super.key});

  @override
  State<AddPOIPage> createState() => _AddPOIPageState();
}

class _AddPOIPageState extends State<AddPOIPage> {
  final _formKey = GlobalKey<FormState>();

  final _idController = TextEditingController();
  final _tituloController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _raioController = TextEditingController(text: "150");
  final _descricaoController = TextEditingController();
  final _imagemUrlController = TextEditingController();
  final _audioUrlController = TextEditingController();
  final _categoriaController = TextEditingController();

  bool _saving = false;

  Future<void> _savePOI() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance
          .collection('pois')
          .doc(_idController.text.trim())
          .set({
        "titulo": _tituloController.text.trim(),
        "lat": double.parse(_latController.text.trim()),
        "lng": double.parse(_lngController.text.trim()),
        "raio": double.parse(_raioController.text.trim()),
        "descricao": _descricaoController.text.trim(),
        "imagemUrl": _imagemUrlController.text.trim(),
        "audioUrl": _audioUrlController.text.trim(),
        "trigger": "enter",
        "categoria": _categoriaController.text.trim(),
        "tags": [],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ POI adicionado com sucesso!")),
        );
      }
      _formKey.currentState!.reset();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Erro: $e")),
        );
      }
    }

    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Adicionar POI")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(labelText: "ID (ex: angra_municipio)"),
                validator: (v) => v == null || v.isEmpty ? "Obrigatório" : null,
              ),
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: "Título"),
                validator: (v) => v == null || v.isEmpty ? "Obrigatório" : null,
              ),
              TextFormField(
                controller: _latController,
                decoration: const InputDecoration(labelText: "Latitude"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _lngController,
                decoration: const InputDecoration(labelText: "Longitude"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _raioController,
                decoration: const InputDecoration(labelText: "Raio (m)"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: "Descrição"),
                maxLines: 3,
              ),
              TextFormField(
                controller: _imagemUrlController,
                decoration: const InputDecoration(labelText: "Imagem URL"),
              ),
              TextFormField(
                controller: _audioUrlController,
                decoration: const InputDecoration(labelText: "Áudio URL"),
              ),
              TextFormField(
                controller: _categoriaController,
                decoration: const InputDecoration(labelText: "Categoria"),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.save),
                label: const Text("Guardar POI"),
                onPressed: _saving ? null : _savePOI,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
