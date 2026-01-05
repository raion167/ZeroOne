import 'package:flutter/material.dart';
import 'package:zeroone/pages/contas_relatorios_page.dart';
import 'package:zeroone/pages/menu_lateral.dart';
import 'contas_visao_geral.dart';
import 'contas_listagem.dart';

const Color corPrincipal = Color(0xFFBBFB04);

class ContasPagarPage extends StatelessWidget {
  const ContasPagarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Contas a Pagar"),
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            FinanceiroCardAnimado(
              icon: Icons.dashboard,
              label: "Visão Geral",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ContasVisaoGeralPage(),
                  ),
                );
              },
            ),
            FinanceiroCardAnimado(
              icon: Icons.list_alt,
              label: "Listagem de Contas",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContasListagemPage()),
                );
              },
            ),
            FinanceiroCardAnimado(
              icon: Icons.bar_chart,
              label: "Relatórios e Análises",
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

class FinanceiroCardAnimado extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const FinanceiroCardAnimado({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<FinanceiroCardAnimado> createState() => _FinanceiroCardAnimadoState();
}

class _FinanceiroCardAnimadoState extends State<FinanceiroCardAnimado>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );

    _scale = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onTap();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: const Color(0xFF0B0B0B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: corPrincipal.withOpacity(0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: corPrincipal.withOpacity(0.35),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: corPrincipal, size: 48),
                const SizedBox(height: 12),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: corPrincipal,
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
