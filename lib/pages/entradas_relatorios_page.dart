import 'package:flutter/material.dart';

class EntradasRelatoriosPage extends StatelessWidget {
  const EntradasRelatoriosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Relatórios e Análises de Entradas")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Análises Rápidas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            _RelatorioCard(
              icon: Icons.calendar_month,
              title: "Entradas por Mês",
              color: Colors.blue,
              onTap: () {},
            ),

            _RelatorioCard(
              icon: Icons.pie_chart,
              title: "Distribuição por Categoria",
              color: Colors.orange,
              onTap: () {},
            ),

            _RelatorioCard(
              icon: Icons.bar_chart,
              title: "Crescimento Anual",
              color: Colors.green,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _RelatorioCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _RelatorioCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(width: 16),
              Text(
                title,
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
