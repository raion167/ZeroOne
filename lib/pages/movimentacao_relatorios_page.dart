import 'package:flutter/material.dart';
import 'package:zeroone/pages/relatorio_entradas_page.dart';
import 'package:zeroone/pages/relatorio_estoque_page.dart';
import 'package:zeroone/pages/relatorio_perdas_page.dart';
import 'package:zeroone/pages/relatorio_saidas_page.dart';
import 'menu_lateral.dart';

class MovimentacaoRelatoriosPage extends StatelessWidget {
  final String nomeUsuario;
  final String emailUsuario;

  const MovimentacaoRelatoriosPage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      titulo: "Relatórios de Movimentação",
      nomeUsuario: nomeUsuario,
      emailUsuario: emailUsuario,
      corpo: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _RelatorioCard(
              icon: Icons.inventory_2,
              label: "Relatório de Estoque",
              color: Colors.blue.shade700,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RelatorioEstoquePage(
                      nomeUsuario: nomeUsuario,
                      emailUsuario: emailUsuario,
                    ),
                  ),
                );
              },
            ),
            _RelatorioCard(
              icon: Icons.warning_amber,
              label: "Relatório de Perdas",
              color: Colors.red.shade700,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RelatorioPerdasPage(
                      nomeUsuario: nomeUsuario,
                      emailUsuario: emailUsuario,
                    ),
                  ),
                );
              },
            ),
            _RelatorioCard(
              icon: Icons.arrow_upward,
              label: "Relatório de Entradas",
              color: Colors.green.shade700,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RelatorioEntradasPage(
                      nomeUsuario: nomeUsuario,
                      emailUsuario: emailUsuario,
                    ),
                  ),
                );
              },
            ),
            _RelatorioCard(
              icon: Icons.arrow_upward,
              label: "Relatório de Saídas",
              color: Colors.orange.shade700,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RelatorioSaidasPage(
                      nomeUsuario: nomeUsuario,
                      emailUsuario: emailUsuario,
                    ),
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

class _RelatorioCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RelatorioCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.85), color.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
