import 'package:flutter/material.dart';
import 'package:zeroone/pages/contas_relatorios.dart';
import 'contas_relatorios.dart';

const Color corPrincipal = Color(0xFFBBFB04);

class ContasRelatoriosPage extends StatefulWidget {
  const ContasRelatoriosPage({super.key});

  @override
  State<ContasRelatoriosPage> createState() => _ContasRelatoriosPageState();
}

class _ContasRelatoriosPageState extends State<ContasRelatoriosPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Relatórios Financeiros"),
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
        elevation: 0,
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          indicatorColor: corPrincipal,
          labelColor: corPrincipal,
          unselectedLabelColor: corPrincipal.withOpacity(0.5),
          tabs: const [
            Tab(icon: Icon(Icons.pie_chart_outline), text: "Status"),
            Tab(icon: Icon(Icons.trending_up), text: "Evolução"),
            Tab(icon: Icon(Icons.category_outlined), text: "Categorias"),
            Tab(icon: Icon(Icons.store_outlined), text: "Fornecedores"),
            Tab(icon: Icon(Icons.calendar_month), text: "Heatmap"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _GraficoWrapper(child: GraficoStatusPagamento()),
          _GraficoWrapper(child: GraficoEvolucaoMensal()),
          _GraficoWrapper(child: GraficoCategorias()),
          _GraficoWrapper(child: GraficoFornecedores()),
          _GraficoWrapper(child: GraficoHeatmapVencimentos()),
        ],
      ),
    );
  }
}

class _GraficoWrapper extends StatelessWidget {
  final Widget child;
  const _GraficoWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Colors.black,
        elevation: 10,
        shadowColor: corPrincipal.withOpacity(0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: corPrincipal, width: 1.4),
        ),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}
