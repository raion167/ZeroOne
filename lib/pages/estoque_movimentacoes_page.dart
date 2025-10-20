import 'package:flutter/material.dart';
import 'package:zeroone/estoque_visao_geral.dart';
import 'package:zeroone/pages/estoque_adicionar_movimentacao.dart';
import 'package:zeroone/pages/lista_movimentacoes_page.dart';
import 'package:zeroone/pages/movimentacao_relatorios_page.dart';
import 'menu_lateral.dart';
import 'estoque_lista_page.dart';
import 'estoque_adicionar_page.dart';

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
          children: [
            _EstoqueCard(
              icon: Icons.dashboard,
              label: "Visão Geral",
              color: Colors.blue,
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
              color: Colors.orange,
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
              color: Colors.green,
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
              color: Colors.purple,
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
              icon: Icons.bar_chart,
              label: "Relatórios",
              color: Colors.red,
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
            ),
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
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
