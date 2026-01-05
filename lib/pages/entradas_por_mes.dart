import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

const String apiBase = "http://localhost:8080/app/";

class EntradasPorMesPage extends StatefulWidget {
  const EntradasPorMesPage({super.key});

  @override
  State<EntradasPorMesPage> createState() => _EntradasPorMesPageState();
}

class _EntradasPorMesPageState extends State<EntradasPorMesPage> {
  bool loading = true;
  List<Map<String, dynamic>> dados = [];

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    try {
      final url = Uri.parse("${apiBase}entradas_por_mes.php");
      final response = await http.get(url);

      final json = jsonDecode(response.body);

      if (json["success"]) {
        setState(() {
          final lista = json["entradas"];

          if (lista != null && lista is List) {
            setState(() {
              dados = List<Map<String, dynamic>>.from(lista);
            });
          } else {
            setState(() {
              dados = [];
            });
          }
          loading = false;
        });
      }
    } catch (e) {
      print("Erro: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Entradas por Mês")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    "Gráfico de Entradas Mensais",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),

                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),

                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() < dados.length) {
                                  final mes = dados[value.toInt()]["mes"];
                                  final partes = mes.split("-");
                                  return Text("${partes[1]}/${partes[0]}");
                                }
                                return const Text("");
                              },
                            ),
                          ),
                        ),

                        barGroups: dados.asMap().entries.map((e) {
                          int index = e.key;
                          double valor = double.parse(e.value["total"]);

                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: valor,
                                width: 18,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
