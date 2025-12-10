import 'package:flutter/material.dart';
import 'package:zeroone/pages/entradas_listagem_page.dart';
import 'package:zeroone/pages/entradas_relatorios_page.dart';
import 'package:zeroone/pages/entradas_visao_geral_page.dart';

class EntradasPage extends StatelessWidget {
  const EntradasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Entradas")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _FinanceiroCard(
              icon: Icons.dashboard_outlined,
              label: "Visão Geral",
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EntradasVisaoGeralPage(),
                  ),
                );
              },
            ),
            _FinanceiroCard(
              icon: Icons.list_alt_outlined,
              label: "Listagem de Entradas",
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EntradasListagemPage(),
                  ),
                );
              },
            ),
            _FinanceiroCard(
              icon: Icons.bar_chart_outlined,
              label: "Relatórios e Análises",
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EntradasRelatoriosPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceiroCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FinanceiroCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 48),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
