import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:zeroone/pages/contas_visao_geral.dart';

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
      backgroundColor: const Color(0xff0b0f14),
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
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: neonBox(corPrincipal),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          borderData: FlBorderData(show: false),

                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) =>
                                FlLine(color: Colors.white10, strokeWidth: 1),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 42,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  );
                                },
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
                                    return Text(
                                      "${partes[1]}/${partes[0]}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          barGroups: dados.asMap().entries.map((e) {
                            int index = e.key;
                          }),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  BoxDecoration neonBox(Color cor) {
    return BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: cor.withOpacity(0.6), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: cor.withOpacity(0.35),
          blurRadius: 18,
          spreadRadius: 1,
        ),
      ],
    );
  }
}
