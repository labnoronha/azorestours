import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc =
        await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Perfil")),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text("❌ Erro ao carregar dados do utilizador."),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: Text("⚠️ Dados de utilizador não encontrados."),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (data['photoUrl'] != null)
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(data['photoUrl']),
                  )
                else
                  const CircleAvatar(
                    radius: 40,
                    child: Icon(Icons.person, size: 40),
                  ),
                const SizedBox(height: 16),
                Text(
                  data['name'] ?? "Sem nome",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data['email'] ?? "Sem email",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (data['createdAt'] != null)
                  Text(
                    "Conta criada em: ${data['createdAt']}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
