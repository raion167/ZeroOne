import 'package:flutter/material.dart';
import 'package:zeroone/pages/controle_estoque_page.dart';
import 'package:zeroone/pages/financeiro_page.dart';
import 'monitoramento_clientes_page.dart';
import 'pagina_inicial.dart';
import 'package:zeroone/main.dart';

class BaseScaffold extends StatelessWidget {
  final String titulo;
  final Widget corpo;
  final String nomeUsuario;
  final String emailUsuario;

  const BaseScaffold({
    super.key,
    required this.titulo,
    required this.corpo,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.black),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(
                      nomeUsuario: nomeUsuario,
                      emailUsuario: emailUsuario,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.wallet),
              title: const Text("Financeiro"),
              onTap: () {
                Navigator.pop(context);
                /*Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FinanceiroPage(
                      nomeUsuario: nomeUsuario,
                      emailUsuario: emailUsuario,
                    ),
                  ),
                );*/
              },
            ),
            ListTile(
              leading: const Icon(Icons.money),
              title: const Text("Vendas"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FinanceiroPage(
                      nomeUsuario: nomeUsuario,
                      emailUsuario: emailUsuario,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text("Controle de Estoque"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ControleEstoquePage(
                      nomeUsuario: nomeUsuario,
                      emailUsuario: emailUsuario,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bolt),
              title: const Text("Monitoramento"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MonitoramentoClientesPage(
                      nomeUsuario: nomeUsuario, // Passe o nome do usuário
                      emailUsuario: emailUsuario, // Passe o email do usuário
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Perfil"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Sair"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
      body: corpo,
    );
  }
}
