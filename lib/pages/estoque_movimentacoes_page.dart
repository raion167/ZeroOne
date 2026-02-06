import 'package:flutter/material.dart';
import 'package:zeroone/estoque_visao_geral.dart';
import 'package:zeroone/pages/estoque_adicionar_movimentacao.dart';
import 'package:zeroone/pages/lista_movimentacoes_page.dart';
import 'package:zeroone/pages/movimentacao_relatorios_page.dart';
import 'menu_lateral.dart';
import 'estoque_lista_page.dart';
import 'estoque_adicionar_page.dart';
import 'package:zeroone/main.dart';

const Color corPrincipal = Color(0xFFBBFB04);

class EstoqueMovimentacoesPage extends StatelessWidget {
  final String nomeUsuario;
  final String emailUsuario;

  const EstoqueMovimentacoesPage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
        title: const Text("Controle de Movimentações"),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _EstoqueCard(
              icon: Icons.dashboard,
              label: "Visão Geral",
              color: corPrincipal,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EstoqueVisaoGeralPage(
                      nomeUsuario: nomeUsuario,
                      emailUsuario: emailUsuario,
                    ),
                  ),
                );
              },
            ),
            _EstoqueCard(
              icon: Icons.list_alt,
              label: "Movimentações",
              color: corPrincipal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EstoqueMovimentacoesListPage(
                      nomeUsuario: nomeUsuario,
                      emailUsuario: emailUsuario,
                    ),
                  ),
                );
              },
            ),
            _EstoqueCard(
              icon: Icons.add_box,
              label: "Adicionar Movimentação",
              color: corPrincipal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EstoqueAdicionarMovimentacaoPage(
                      nomeUsuario: nomeUsuario,
                      emailUsuario: emailUsuario,
                    ),
                  ),
                );
              },
            ),
            _EstoqueCard(
              icon: Icons.inventory_2,
              label: "Produtos",
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
            /*_EstoqueCard(
              icon: Icons.bar_chart,
              label: "Relatórios",
              color: corPrincipal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MovimentacaoRelatoriosPage(
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

// Widget para cada botão do menu
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
