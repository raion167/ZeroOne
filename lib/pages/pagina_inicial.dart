import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final String nomeUsuario;
  final String emailUsuario;

  const HomePage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bem-vindo, $nomeUsuario")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: NetworkImage(
                      "https://via.placeholder.com/150",
                    ), // substitua pela real
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nomeUsuario,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    emailUsuario,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Início"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Perfil"),
              onTap: () {
                // Navegar para a tela de perfil
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Sair"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/'); // volta pro login
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text("Página Inicial", style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
