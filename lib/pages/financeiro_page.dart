import 'package:flutter/material.dart';
import 'package:zeroone/pages/analise_viabilidade.dart';
import 'package:zeroone/pages/contas_pagar_page.dart';
import 'package:zeroone/pages/demonstracoes_financeiras_page.dart';
import 'package:zeroone/pages/entradas_page.dart';
import 'package:zeroone/pages/gestao_projetos_custos_page.dart';
import 'menu_lateral.dart';
import 'package:zeroone/main.dart';

const Color corPrincipal = Color(0xFFBBFB04);

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
            FinanceiroCardAnimado(
              icon: Icons.payments,
              label: "Contas a Pagar",
              color: corPrincipal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ContasPagarPage()),
                );
              },
            ),
            FinanceiroCardAnimado(
              icon: Icons.trending_up,
              label: "Entradas",
              color: corPrincipal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EntradasPage()),
                );
              },
            ),
            FinanceiroCardAnimado(
              icon: Icons.bar_chart,
              label: "Demonstrações",
              color: corPrincipal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DemonstracoesFinanceirasPage(),
                  ),
                );
              },
            ),
            FinanceiroCardAnimado(
              icon: Icons.work,
              label: "Rentabilidade",
              color: corPrincipal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GestaoProjetosPage()),
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
  final Color color;
  final VoidCallback onTap;

  const FinanceiroCardAnimado({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
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
      duration: const Duration(milliseconds: 160),
      lowerBound: 0.95,
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
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.35),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(color: widget.color.withOpacity(0.4), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: widget.color, size: 48),
                const SizedBox(height: 12),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: widget.color,
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
