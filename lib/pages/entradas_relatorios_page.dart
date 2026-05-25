import 'package:flutter/material.dart';
import 'package:zeroone/pages/crescimento_anual_page.dart';
import 'package:zeroone/pages/distribuicao_categoria_page.dart';
import 'package:zeroone/pages/entradas_por_mes.dart';

const Color corPrincipal = Color(0xFFBBFB04);

class EntradasRelatoriosPage extends StatelessWidget {
  const EntradasRelatoriosPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Detecta se a tela atual é Desktop ou um Tablet largo
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Relatórios e Análises de Entradas",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        foregroundColor: corPrincipal,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          // Define a largura máxima confortável para o Desktop
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho Interno Estilizado
              const Text(
                "BI & Análise de Dados",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Monitore a saúde financeira do seu negócio através de demonstrativos visuais detalhados.",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),

              // GRID DE CARDS DE RELATÓRIO RESPONSIVOS
              Expanded(
                child: GridView.count(
                  // 3 colunas lado a lado no Desktop, 2 no Mobile
                  crossAxisCount: isDesktop ? 3 : 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  // Mantém o formato retangular deitado no Desktop e quadrado no Mobile
                  childAspectRatio: isDesktop ? 1.5 : 1.0,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _FinanceiroCardAnimado(
                      icon: Icons.calendar_month_outlined,
                      label: "Entradas por Mês",
                      descricao:
                          "Histórico de faturamento mensal comparado e evolução de caixa.",
                      isDesktop: isDesktop,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EntradasPorMesPage(),
                        ),
                      ),
                    ),
                    _FinanceiroCardAnimado(
                      icon: Icons.pie_chart_outline,
                      label: "Distribuição por Categoria",
                      descricao:
                          "Gráficos de pizza segmentando a origem e natureza de cada receita.",
                      isDesktop: isDesktop,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DistribuicaoCategoriaPage(),
                        ),
                      ),
                    ),
                    _FinanceiroCardAnimado(
                      icon: Icons.bar_chart_outlined,
                      label: "Crescimento Anual",
                      descricao:
                          "Métricas consolidadas ano a ano para análise de escalabilidade.",
                      isDesktop: isDesktop,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CrescimentoAnualPage(),
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

class _FinanceiroCardAnimado extends StatefulWidget {
  final IconData icon;
  final String label;
  final String descricao;
  final bool isDesktop;
  final VoidCallback onTap;

  const _FinanceiroCardAnimado({
    required this.icon,
    required this.label,
    required this.descricao,
    required this.isDesktop,
    required this.onTap,
  });

  @override
  State<_FinanceiroCardAnimado> createState() => _FinanceiroCardAnimadoState();
}

class _FinanceiroCardAnimadoState extends State<_FinanceiroCardAnimado>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  bool _isHovered = false; // Estado que controla o efeito neon no Desktop

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
              // Fundo sutilmente mais claro quando o mouse passa por cima
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
                      // LAYOUT DESKTOP: Estrutura horizontal dinâmica
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
                      // LAYOUT MOBILE: Mantém os cards centralizados focados no toque
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
