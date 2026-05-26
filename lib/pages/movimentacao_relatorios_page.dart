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
    // Detecta se a tela atual é Desktop ou um Tablet largo
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return BaseScaffold(
      titulo: "Relatórios de Movimentação",
      nomeUsuario: nomeUsuario,
      emailUsuario: emailUsuario,
      mostrarBotaoVoltar:
          true, // 🔥 Adicionado o botão voltar nativo do BaseScaffold
      corpo: Center(
        child: Container(
          // Define a mesma largura máxima confortável para o conteúdo
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho Interno Estilizado igual ao financeiro
              const Text(
                "Análises e Balanço de Estoque",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Selecione um dos relatórios operacionais abaixo para visualizar e exportar dados consolidados.",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),

              // GRID DE CARDS RESPONSIVOS
              Expanded(
                child: GridView.count(
                  crossAxisCount: isDesktop ? 3 : 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: isDesktop ? 1.5 : 1.0,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    FinanceiroCardAnimado(
                      icon: Icons.inventory_2_outlined,
                      label: "Relatório de Estoque",
                      descricao:
                          "Análise completa do inventário atual, níveis de produtos e curva ABC.",
                      isDesktop: isDesktop,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RelatorioEstoquePage(
                            nomeUsuario: nomeUsuario,
                            emailUsuario: emailUsuario,
                          ),
                        ),
                      ),
                    ),
                    /*FinanceiroCardAnimado(
                      icon: Icons.warning_amber_rounded,
                      label: "Relatório de Perdas",
                      descricao:
                          "Histórico de mercadorias danificadas, vencidas ou baixas justificadas.",
                      isDesktop: isDesktop,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RelatorioPerdasPage(
                            nomeUsuario: nomeUsuario,
                            emailUsuario: emailUsuario,
                          ),
                        ),
                      ),
                    ),*/
                    FinanceiroCardAnimado(
                      icon: Icons.arrow_upward_rounded,
                      label: "Relatório de Entradas",
                      descricao:
                          "Balanço total de novas mercadorias recebidas e reposições de fornecedores.",
                      isDesktop: isDesktop,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RelatorioEntradasPage(
                            nomeUsuario: nomeUsuario,
                            emailUsuario: emailUsuario,
                          ),
                        ),
                      ),
                    ),
                    FinanceiroCardAnimado(
                      icon: Icons.arrow_downward_rounded,
                      label: "Relatório de Saídas",
                      descricao:
                          "Fluxo de produtos expedidos, vendas realizadas e saídas operacionais.",
                      isDesktop: isDesktop,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RelatorioSaidasPage(
                            nomeUsuario: nomeUsuario,
                            emailUsuario: emailUsuario,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Componente idêntico ao de Contas a Pagar com suporte a hover e layout Desktop/Mobile
class FinanceiroCardAnimado extends StatefulWidget {
  final IconData icon;
  final String label;
  final String descricao;
  final bool isDesktop;
  final VoidCallback onTap;

  const FinanceiroCardAnimado({
    super.key,
    required this.icon,
    required this.label,
    required this.descricao,
    required this.isDesktop,
    required this.onTap,
  });

  @override
  State<FinanceiroCardAnimado> createState() => _FinanceiroCardAnimadoState();
}

class _FinanceiroCardAnimadoState extends State<FinanceiroCardAnimado>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
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
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.reverse(),
        onTapUp: (_) {
          _controller.forward();
          widget.onTap();
        },
        onTapCancel: () => _controller.forward(),
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _isHovered
                  ? const Color(0xFF141414)
                  : const Color(0xFF0B0B0B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isHovered
                    ? corPrincipal
                    : corPrincipal.withOpacity(0.35),
                width: _isHovered ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: corPrincipal.withOpacity(_isHovered ? 0.4 : 0.2),
                  blurRadius: _isHovered ? 25 : 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: widget.isDesktop
                  ? Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: corPrincipal.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            widget.icon,
                            color: corPrincipal,
                            size: 40,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.label,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.descricao,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.45),
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: corPrincipal,
                          size: 14,
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(widget.icon, color: corPrincipal, size: 44),
                        const SizedBox(height: 14),
                        Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: corPrincipal,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
