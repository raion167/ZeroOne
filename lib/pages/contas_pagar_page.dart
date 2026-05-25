import 'package:flutter/material.dart';
import 'package:zeroone/pages/contas_relatorios_page.dart';
import 'contas_visao_geral.dart';
import 'contas_listagem.dart';

const Color corPrincipal = Color(0xFFBBFB04);

class ContasPagarPage extends StatelessWidget {
  const ContasPagarPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Detecta se a tela atual é Desktop ou um Tablet largo
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Contas a Pagar",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          // Define uma largura máxima confortável para o conteúdo não esticar infinitamente no Desktop
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho Interno Estilizado
              const Text(
                "Gerenciamento de Saídas",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Selecione um dos módulos operacionais abaixo para gerenciar seus lançamentos financeiros.",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),

              // GRID DE CARD RESPONSIVO
              Expanded(
                child: GridView.count(
                  // No Desktop deixa as 3 opções lado a lado. No Mobile, divide em 2 colunas.
                  crossAxisCount: isDesktop ? 3 : 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  // Controla a proporção do card: no desktop ele vira um retângulo deitado macio (1.5)
                  childAspectRatio: isDesktop ? 1.5 : 1.0,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    FinanceiroCardAnimado(
                      icon: Icons.dashboard_customize_outlined,
                      label: "Visão Geral",
                      descricao:
                          "Painel com gráficos de fluxo de caixa e resumo de vencimentos.",
                      isDesktop: isDesktop,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ContasVisaoGeralPage(),
                        ),
                      ),
                    ),
                    FinanceiroCardAnimado(
                      icon: Icons.format_list_bulleted_rounded,
                      label: "Listagem de Contas",
                      descricao:
                          "Pesquise faturas, aplique filtros avançados e dê baixa em pagamentos.",
                      isDesktop: isDesktop,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ContasListagemPage(),
                        ),
                      ),
                    ),
                    FinanceiroCardAnimado(
                      icon: Icons.analytics_outlined,
                      label: "Relatórios e Análises",
                      descricao:
                          "Balanço consolidado de despesas e exportação de dados.",
                      isDesktop: isDesktop,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ContasRelatoriosPage(),
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
  bool _isHovered = false; // Controla se o mouse está em cima do card (Desktop)

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
              // Muda o fundo sutilmente quando passa o mouse no desktop
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
                      // LAYOUT DESKTOP: Ícone na esquerda, textos empilhados na direita
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
                      // LAYOUT MOBILE: Mantém a estrutura clássica centralizada
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
