import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crescimento Anual")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    "Evolução Mensal",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: LineChart(
                      LineChartData(
                        minX: 1,
                        maxX: 12,
                        minY: 0,
                        maxY: _getMaxY(),

                        // REMOVE GRID E BORDAS
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),

                        // LEGENDAS DOS EIXOS
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
                              reservedSize: 32,
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
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                            ),
                          ),

                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 10000, // ➜ intervalo de 10 mil
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  "R\$ ${value.toInt()}",
                                  style: const TextStyle(fontSize: 11),
                                );
                              },
                            ),
                          ),
                        ),

                        // LINHA DO GRÁFICO
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            dotData: FlDotData(show: true),
                            spots: _buildSpots(),
                          ),
                        ],
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
