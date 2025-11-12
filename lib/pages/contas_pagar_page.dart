import 'package:flutter/material.dart';
import 'contas_visao_geral.dart';
import 'contas_listagem.dart';
import 'contas_relatorios.dart';
import 'contas_analises.dart';

class ContasPagarPage extends StatelessWidget {
  const ContasPagarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contas a Pagar")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _FinanceiroCard(
              icon: Icons.dashboard,
              label: "Visão Geral",
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ContasVisaoGeralPage(),
                  ),
                );
              },
            ),
            _FinanceiroCard(
              icon: Icons.list_alt,
              label: "Listagem de Contas",
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContasListagemPage()),
                );
              },
            ),
            _FinanceiroCard(
              icon: Icons.bar_chart,
              label: "Relatórios e Análises Financeiras",
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ContasRelatoriosPage(),
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
