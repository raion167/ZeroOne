import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:zeroone/pages/entradas_relatorios_page.dart';

const Color corPrincipal = Color(0xFFBBFB04);

class CrescimentoAnualPage extends StatefulWidget {
  const CrescimentoAnualPage({super.key});

  @override
  State<CrescimentoAnualPage> createState() => _CrescimentoAnualPageState();
}

class _CrescimentoAnualPageState extends State<CrescimentoAnualPage> {
  bool loading = true;
  List dados = [];

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    final url = Uri.parse("http://localhost:8080/app/crescimento_anual.php");
    final response = await http.get(url);

    final json = jsonDecode(response.body);

    setState(() {
      dados = json["data"];
      loading = false;
    });
  }

  BoxDecoration neonBox() {
    return BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: corPrincipal.withOpacity(0.6), width: 1.3),
      boxShadow: [
        BoxShadow(
          color: corPrincipal.withOpacity(0.35),
          blurRadius: 22,
          spreadRadius: 2,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(
        title: const Text("Crescimento Anual"),
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "Evolução Mensal",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: corPrincipal,
                      shadows: [
                        Shadow(
                          color: corPrincipal.withOpacity(0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: neonBox(),
                      child: LineChart(
                        LineChartData(
                          minX: 1,
                          maxX: 12,
                          minY: 0,
                          maxY: _getMaxY(),

                          gridData: FlGridData(show: false),
                          borderData: FlBorderData(show: false),

                          titlesData: FlTitlesData(
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),

                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  const meses = [
                                    "",
                                    "Jan",
                                    "Fev",
                                    "Mar",
                                    "Abr",
                                    "Mai",
                                    "Jun",
                                    "Jul",
                                    "Ago",
                                    "Set",
                                    "Out",
                                    "Nov",
                                    "Dez",
                                  ];

                                  if (value < 1 || value > 12) {
                                    return const SizedBox();
                                  }
                                  return Text(
                                    meses[value.toInt()],
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  );
                                },
                              ),
                            ),

                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 10000,
                                reservedSize: 60,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    "R\$ ${value.toInt()}",
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              color: corPrincipal,
                              barWidth: 3,
                              spots: _buildSpots(),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    corPrincipal.withOpacity(0.35),
                                    corPrincipal.withOpacity(0.02),
                                  ],
                                  begin: AlignmentGeometry.topCenter,
                                  end: AlignmentGeometry.bottomCenter,
                                ),
                              ),
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, bar, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: corPrincipal,
                                    strokeWidth: 2,
                                    strokeColor: corPrincipal.withOpacity(0.9),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Converte dados do backend em pontos do gráfico
  List<FlSpot> _buildSpots() {
    return dados.map((item) {
      double mes = double.tryParse(item["mes"].toString()) ?? 0;
      double total =
          double.tryParse(item["total"].toString().replaceAll(",", ".")) ?? 0;
      return FlSpot(mes, total);
    }).toList();
  }

  /// MaxY arredondado sempre para o próximo múltiplo de 10.000
  double _getMaxY() {
    double maxValue = 0;

    for (var item in dados) {
      double val =
          double.tryParse(item["total"].toString().replaceAll(",", ".")) ?? 0;
      if (val > maxValue) maxValue = val;
    }

    // Arredonda para cima para múltiplo de 10k
    double next = ((maxValue / 10000).ceil() * 10000).toDouble();

    return next == 0 ? 10000 : next; // garante mínimo de 10k
  }
}
