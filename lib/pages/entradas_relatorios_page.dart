import 'package:flutter/material.dart';
import 'package:zeroone/pages/crescimento_anual_page.dart';
import 'package:zeroone/pages/distribuicao_categoria_page.dart';
import 'package:zeroone/pages/entradas_por_mes.dart';

const Color corPrincipal = Color(0xFFBBFB04);

class EntradasRelatoriosPage extends StatelessWidget {
  const EntradasRelatoriosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Relatórios e Análises de Entradas"),
        foregroundColor: corPrincipal,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _FinanceiroCard(
              icon: Icons.calendar_month_outlined,
              label: "Entradas por Mês",
              corPrincipal: corPrincipal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EntradasPorMesPage()),
                );
              },
            ),
            _FinanceiroCard(
              icon: Icons.pie_chart_outline,
              label: "Distribuição por Categoria",
              corPrincipal: corPrincipal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DistribuicaoCategoriaPage(),
                  ),
                );
              },
            ),
            _FinanceiroCard(
              icon: Icons.bar_chart_outlined,
              label: "Crescimento Anual",
              corPrincipal: corPrincipal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CrescimentoAnualPage(),
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
  final Color corPrincipal;
  final VoidCallback onTap;

  const _FinanceiroCard({
    required this.icon,
    required this.label,
    required this.corPrincipal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black,
      elevation: 8,
      shadowColor: corPrincipal.withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: corPrincipal, width: 1.6),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        splashColor: corPrincipal.withOpacity(0.15),
        highlightColor: corPrincipal.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: corPrincipal),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: corPrincipal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
