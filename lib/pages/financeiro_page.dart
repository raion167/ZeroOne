import 'package:flutter/material.dart';
import 'package:zeroone/pages/contas_pagar_page.dart';
import 'package:zeroone/pages/entradas_page.dart';
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
    // Lista de itens centralizada para facilitar a manutenção
    final List<Map<String, dynamic>> itensMenu = [
      {
        'icon': Icons.payments,
        'label': "Contas a Pagar",
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContasPagarPage()),
            ),
      },
      {
        'icon': Icons.trending_up,
        'label': "Entradas",
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EntradasPage()),
            ),
      },
      // Você pode adicionar novos botões aqui facilmente
    ];

    return BaseScaffold(
      titulo: "Financeiro",
      nomeUsuario: nomeUsuario,
      emailUsuario: emailUsuario,
      corpo: Center(
        // Center + Container com maxWidth impede que os botões estiquem infinitamente no Desktop
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          padding: const EdgeInsets.all(24),
          child: GridView.builder(
            // O MaxCrossAxisExtent define o tamanho máximo de largura de cada card
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220, // Ajuste este valor para aumentar/diminuir os botões
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 1.0, // Garante que o card seja sempre um quadrado
            ),
            itemCount: itensMenu.length,
            itemBuilder: (context, index) {
              return FinanceiroCardAnimado(
                icon: itensMenu[index]['icon'],
                label: itensMenu[index]['label'],
                color: corPrincipal,
                onTap: itensMenu[index]['onTap'],
              );
            },
          ),
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
      lowerBound: 0.92, // Feedback visual de clique um pouco mais perceptível
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
                color: widget.color.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(
              color: widget.color.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.color, size: 42),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: widget.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}