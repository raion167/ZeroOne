import 'package:flutter/material.dart';
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
              icon: Icons.add_shopping_cart,
              label: "Nova Venda",
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NovaVendaPage(),
                  ),
                );
              },
            ),
            _FinanceiroCard(
              icon: Icons.list,
              label: "Lista de Vendas",
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ListaVendasPage(),
                  ),
                );
              },
            ),
            _FinanceiroCard(
              icon: Icons.picture_as_pdf,
              label: "Simular Orçamento",
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SimularOrcamentoPage(),
                  ),
                );
              },
            ),
            _FinanceiroCard(
              icon: Icons.settings,
              label: "Configurações",
              color: Colors.grey,
              onTap: () {},
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
