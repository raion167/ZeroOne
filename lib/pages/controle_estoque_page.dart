import 'package:flutter/material.dart';
import 'package:zeroone/pages/estoque_adicionar_page.dart';
import 'package:zeroone/pages/estoque_lista_page.dart';
import 'package:zeroone/pages/estoque_movimentacoes_page.dart';
import 'package:zeroone/pages/estoque_relatorios_page.dart';
import 'menu_lateral.dart';
import 'estoque_lista_page.dart';
import 'estoque_adicionar_page.dart';
import 'estoque_movimentacoes_page.dart';
import 'estoque_relatorios_page.dart';

const Color corPrincipal = Color(0xFFBBFB04);

class ControleEstoquePage extends StatelessWidget {
  final String nomeUsuario;
  final String emailUsuario;

  const ControleEstoquePage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      titulo: "Controle de Estoque",
      nomeUsuario: nomeUsuario,
      emailUsuario: emailUsuario,
      corpo: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _EstoqueCard(
              icon: Icons.inventory,
              label: "Itens em Estoque",
              color: corPrincipal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EstoqueListaPage(
                      nomeUsuario: nomeUsuario,
                      emailUsuario: emailUsuario,
                    ),
                  ),
                );
              },
            ),
            _EstoqueCard(
              icon: Icons.add_box,
              label: "Adicionar Item",
              color: corPrincipal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EstoqueAdicionarPage(
                      nomeUsuario: nomeUsuario,
                      emailUsuario: emailUsuario,
                    ),
                  ),
                );
              },
            ),
            _EstoqueCard(
              icon: Icons.swap_horiz,
              label: "Movimentações",
              color: corPrincipal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EstoqueMovimentacoesPage(
                      nomeUsuario: nomeUsuario,
                      emailUsuario: emailUsuario,
                    ),
                  ),
                );
              },
            ),
            /*_EstoqueCard(
              icon: Icons.bar_chart,
              label: "Relatórios",
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EstoqueRelatoriosPage(
                      nomeUsuario: nomeUsuario,
                      emailUsuario: emailUsuario,
                    ),
                  ),
                );
              },
            ),*/
          ],
        ),
      ),
    );
  }
}

class _EstoqueCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _EstoqueCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      color: Colors.black,
      shadowColor: color.withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(18),
        side: BorderSide(color: color.withOpacity(0.9), width: 1.4),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 14),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
