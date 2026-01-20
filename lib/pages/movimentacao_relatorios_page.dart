import 'package:flutter/material.dart';
import 'package:zeroone/pages/contas_pagar_page.dart';
import 'package:zeroone/pages/relatorio_entradas_page.dart';
import 'package:zeroone/pages/relatorio_estoque_page.dart';
import 'package:zeroone/pages/relatorio_perdas_page.dart';
import 'package:zeroone/pages/relatorio_saidas_page.dart';
import 'menu_lateral.dart';

const Color corPrincipal = Color(0xFFBBFB04);

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
            FinanceiroCardAnimado(
              icon: Icons.inventory_2,
              label: "Relatório de Estoque",
              color: corPrincipal,
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
            FinanceiroCardAnimado(
              icon: Icons.warning_amber,
              label: "Relatório de Perdas",
              color: corPrincipal,
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
            FinanceiroCardAnimado(
              icon: Icons.arrow_upward,
              label: "Relatório de Entradas",
              color: corPrincipal,
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
            FinanceiroCardAnimado(
              icon: Icons.arrow_downward,
              label: "Relatório de Saídas",
              color: corPrincipal,
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
            color: const Color(0xff0d0d0d),
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
