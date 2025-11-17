import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ContasRelatoriosPage extends StatelessWidget {
  const ContasRelatoriosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Relatórios Financeiros"),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Resumo"),
              Tab(text: "Evolução"),
              Tab(text: "Custos"),
              Tab(text: "Fornecedores"),
              Tab(text: "Auditoria"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AbaResumo(),
            AbaEvolucao(),
            AbaCustos(),
            AbaFornecedores(),
            AbaAuditoria(),
          ],
        ),
      ),
    );
  }
}

//
// ======================================================
// 1️⃣ ABA - RESUMO
// ======================================================
//

class AbaResumo extends StatelessWidget {
  const AbaResumo({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildScroll([
      _titulo("Resumo Financeiro"),
      _card(const GraficoStatusPagamentos()), // gráfico 1
    ]);
  }
}

//
// ======================================================
// 2️⃣ ABA - EVOLUÇÃO
// ======================================================
//

class AbaEvolucao extends StatelessWidget {
  const AbaEvolucao({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildScroll([
      _titulo("Evolução Mensal"),
      _card(const GraficoEvolucaoMensal()), // gráfico 2

      const SizedBox(height: 16),
      _titulo("Fluxo Futuro de Pagamentos"),
      _card(const GraficoFluxoFuturo()), // gráfico 5

      const SizedBox(height: 16),
      _titulo("Status ao Longo dos Meses"),
      _card(const GraficoStatusPorMes()), // gráfico 6
    ]);
  }
}

//
// ======================================================
// 3️⃣ ABA - CUSTOS
// ======================================================
//

class AbaCustos extends StatelessWidget {
  const AbaCustos({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildScroll([
      _titulo("Distribuição por Categoria"),
      _card(const GraficoCategorias()), // gráfico 3

      const SizedBox(height: 16),
      _titulo("Pareto - Itens Críticos"),
      _card(const GraficoPareto()), // gráfico 8
    ]);
  }
}

//
// ======================================================
// 4️⃣ ABA - FORNECEDORES
// ======================================================
//

class AbaFornecedores extends StatelessWidget {
  const AbaFornecedores({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildScroll([
      _titulo("Gastos por Fornecedor"),
      _card(const GraficoFornecedores()), // gráfico 4
    ]);
  }
}

//
// ======================================================
// 5️⃣ ABA - AUDITORIA
// ======================================================
//

class AbaAuditoria extends StatelessWidget {
  const AbaAuditoria({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildScroll([
      _titulo("Concentração de Vencimentos"),
      _card(const GraficoHeatmapVencimentos()), // gráfico 7
    ]);
  }
}

//
// ======================================================
// COMPONENTES REUTILIZÁVEIS
// ======================================================
//

Widget _buildScroll(List<Widget> children) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

Widget _titulo(String t) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );
}

Widget _card(Widget child) {
  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(height: 260, child: child),
    ),
  );
}

//
// ======================================================
// WIDGETS DE GRÁFICO (PLACEHOLDERS)
// Substitua pelos widgets do fl_chart
// ======================================================
//

class GraficoStatusPagamentos extends StatelessWidget {
  const GraficoStatusPagamentos({super.key});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [BarChartRodData(toY: 40, color: Colors.green)],
            showingTooltipIndicators: [0],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [BarChartRodData(toY: 25, color: Colors.orange)],
            showingTooltipIndicators: [0],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [BarChartRodData(toY: 10, color: Colors.red)],
            showingTooltipIndicators: [0],
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return const Text("Pagas");
                  case 1:
                    return const Text("Pendentes");
                  case 2:
                    return const Text("Atrasadas");
                }
                return const Text("");
              },
            ),
          ),
        ),
      ),
    );
  }
}

class GraficoEvolucaoMensal extends StatelessWidget {
  const GraficoEvolucaoMensal({super.key});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            spots: const [
              FlSpot(0, 10),
              FlSpot(1, 12),
              FlSpot(2, 18),
              FlSpot(3, 14),
              FlSpot(4, 20),
              FlSpot(5, 26),
            ],
            barWidth: 4,
            color: Colors.blue,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}

class GraficoFluxoFuturo extends StatelessWidget {
  const GraficoFluxoFuturo({super.key});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 30,
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            spots: const [
              FlSpot(0, 8),
              FlSpot(1, 12),
              FlSpot(2, 18),
              FlSpot(3, 10),
              FlSpot(4, 22),
            ],
            color: Colors.blue,
            barWidth: 4,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [Colors.blue.withOpacity(0.3), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GraficoStatusPorMes extends StatelessWidget {
  const GraficoStatusPorMes({super.key});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: [
          _grupo(1, 10, 6, 2),
          _grupo(2, 14, 4, 3),
          _grupo(3, 18, 7, 1),
        ],
      ),
    );
  }

  BarChartGroupData _grupo(int x, double pagas, double pend, double atr) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: pagas + pend + atr,
          rodStackItems: [
            BarChartRodStackItem(0, pagas, Colors.green),
            BarChartRodStackItem(pagas, pagas + pend, Colors.orange),
            BarChartRodStackItem(pagas + pend, pagas + pend + atr, Colors.red),
          ],
        ),
      ],
    );
  }
}

class GraficoCategorias extends StatelessWidget {
  const GraficoCategorias({super.key});

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        centerSpaceRadius: 55,
        sections: [
          PieChartSectionData(value: 40, title: "Módulos", color: Colors.blue),
          PieChartSectionData(
            value: 25,
            title: "Inversores",
            color: Colors.green,
          ),
          PieChartSectionData(
            value: 15,
            title: "Estrutura",
            color: Colors.orange,
          ),
          PieChartSectionData(value: 10, title: "Mão Obra", color: Colors.red),
          PieChartSectionData(value: 10, title: "Frete", color: Colors.purple),
        ],
      ),
    );
  }
}

class GraficoPareto extends StatelessWidget {
  const GraficoPareto({super.key});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [BarChartRodData(toY: 40, color: Colors.blue)],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [BarChartRodData(toY: 20, color: Colors.blue)],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [BarChartRodData(toY: 15, color: Colors.blue)],
          ),
          BarChartGroupData(
            x: 3,
            barRods: [BarChartRodData(toY: 10, color: Colors.blue)],
          ),
        ],
      ),
    );
  }
}

class GraficoFornecedores extends StatelessWidget {
  const GraficoFornecedores({super.key});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.center,
        barGroups: [
          _bar("SolarTech", 40000, 0),
          _bar("Brasil Solar", 30000, 1),
          _bar("EcoSun", 20000, 2),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (index, meta) {
                switch (index.toInt()) {
                  case 0:
                    return const Text("SolarTech");
                  case 1:
                    return const Text("Brasil Solar");
                  case 2:
                    return const Text("EcoSun");
                }
                return const Text("");
              },
            ),
          ),
        ),
      ),
    );
  }

  BarChartGroupData _bar(String name, double value, int index) {
    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(toY: value / 1000, width: 18, color: Colors.teal),
      ],
    );
  }
}

class GraficoHeatmapVencimentos extends StatelessWidget {
  const GraficoHeatmapVencimentos({super.key});

  @override
  Widget build(BuildContext context) {
    final List<List<int>> valores = [
      [2, 5, 3, 1],
      [4, 8, 2, 0],
      [1, 3, 6, 2],
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: valores.length * 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        int linha = index ~/ 4;
        int coluna = index % 4;
        int valor = valores[linha][coluna];

        return Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(valor / 10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              valor.toString(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}
