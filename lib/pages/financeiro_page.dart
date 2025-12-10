import 'package:flutter/material.dart';
import 'package:zeroone/pages/analise_viabilidade.dart';
import 'package:zeroone/pages/contas_pagar_page.dart';
import 'package:zeroone/pages/demonstracoes_financeiras_page.dart';
import 'package:zeroone/pages/entradas_page.dart';
import 'package:zeroone/pages/gestao_projetos_custos_page.dart';
import 'simular_orcamento_page.dart';
import 'nova_venda_page.dart';
import 'lista_vendas_page.dart';
import 'menu_lateral.dart';

class FinanceiroPage extends StatelessWidget {
  final String nomeUsuario;
  final String emailUsuario;

  const FinanceiroPage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      titulo: "Financeiro",
      nomeUsuario: nomeUsuario,
      emailUsuario: emailUsuario,
      corpo: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _FinanceiroCard(
              icon: Icons.payments,
              label: "Contas a Pagar",
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ContasPagarPage()),
                );
              },
            ),
            _FinanceiroCard(
              icon: Icons.payments,
              label: "Entradas",
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EntradasPage()),
                );
              },
            ),
            _FinanceiroCard(
              icon: Icons.bar_chart,
              label: "Demonstrações Financeiras",
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DemonstracoesFinanceirasPage(),
                  ),
                );
              },
            ),
            _FinanceiroCard(
              icon: Icons.work,
              label: "Analise de Rentabilidade de Projetos",
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GestaoProjetosPage()),
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
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 48),
              const SizedBox(height: 10),
              Text(
                label,
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
