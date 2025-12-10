import 'package:flutter/material.dart';
import 'package:zeroone/pages/contas_relatorios.dart';
import 'contas_relatorios.dart';

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
      appBar: AppBar(
        title: const Text("Relatórios Financeiros"),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.black,
          tabs: const [
            Tab(text: "Status"),
            Tab(text: "Evolução Mensal"),
            Tab(text: "Categorias"),
            Tab(text: "Fornecedores"),
            Tab(text: "Heatmap"),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tab,
        children: const [
          // Cada aba exibe um gráfico
          Padding(padding: EdgeInsets.all(16), child: GraficoStatusPagamento()),
          Padding(padding: EdgeInsets.all(16), child: GraficoEvolucaoMensal()),
          Padding(padding: EdgeInsets.all(16), child: GraficoCategorias()),
          Padding(padding: EdgeInsets.all(16), child: GraficoFornecedores()),
          Padding(
            padding: EdgeInsets.all(16),
            child: GraficoHeatmapVencimentos(),
          ),
        ],
      ),
    );
  }
}
