import 'package:flutter/material.dart';
import 'menu_lateral.dart';
import 'operacional_equipes_page.dart';
import 'operacional_operadores_page.dart';

const Color corPrincipal = Color(0xFFBBFB04);

class OperacionalPage extends StatelessWidget {
  final String nomeUsuario;
  final String emailUsuario;

  const OperacionalPage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      titulo: "Operacional",
      nomeUsuario: nomeUsuario,
      emailUsuario: emailUsuario,
      corpo: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _OperacionalCardAnimado(
              icon: Icons.groups,
              label: "Equipes",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OperacionalEquipesPage(
                      nomeUsuario: nomeUsuario,
                      emailUsuario: emailUsuario,
                    ),
                  ),
                );
              },
            ),
            _OperacionalCardAnimado(
              icon: Icons.engineering,
              label: "Operadores",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OperacionalOperadoresPage(),
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

class _OperacionalCardAnimado extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OperacionalCardAnimado({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_OperacionalCardAnimado> createState() =>
      _OperacionalCardAnimadoState();
}

class _OperacionalCardAnimadoState extends State<_OperacionalCardAnimado>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
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
        scale: _controller,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xff0d0d0d),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: corPrincipal.withOpacity(0.4), width: 1),
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
                Icon(widget.icon, size: 48, color: corPrincipal),
                const SizedBox(height: 12),
                Text(
                  widget.label,
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
      ),
    );
  }
}
