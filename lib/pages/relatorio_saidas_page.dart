import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'menu_lateral.dart';

class RelatorioSaidasPage extends StatefulWidget {
  final String nomeUsuario;
  final String emailUsuario;

  const RelatorioSaidasPage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  State<RelatorioSaidasPage> createState() => _RelatorioSaidasPageState();
}

class _RelatorioSaidasPageState extends State<RelatorioSaidasPage> {
  bool carregando = true;
  List<dynamic> relatorio = [];
  String tipoGrafico = "Colunas";
  String campoX = "produto";
  String campoY = "quantidade";
  final camposDisponiveis = ["produto", "quantidade", "usuario"];
  DateTimeRange? filtroData;
  String? filtroUsuario;
  List<String> usuarios = [];

  Future<void> carregarRelatorio() async {
    setState(() => carregando = true);

    try {
      String baseUrl = "http://localhost:8080"; // Trocar pelo IP se for celular

      String query = "";
      if (filtroUsuario != null) query += "&usuario=$filtroUsuario";
      if (filtroData != null) {
        query +=
            "&data_inicio=${filtroData!.start.toIso8601String()}&data_fim=${filtroData!.end.toIso8601String()}";
      }

      final url = Uri.parse("$baseUrl/app/relatorio_saidas.php?$query");
      print("🔍 Carregando relatório de saídas: $url");

      final response = await http.get(url);
      print("📡 Resposta HTTP: ${response.statusCode}");
      print("📦 Corpo: ${response.body}");

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        setState(() {
          relatorio = List<dynamic>.from(data["dados"] ?? []);
          usuarios = List<String>.from(data["usuarios"] ?? []);
          carregando = false;
        });
      } else {
        setState(() => carregando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nenhum dado encontrado.")),
        );
      }
    } catch (e) {
      setState(() => carregando = false);
      print("❌ Erro ao carregar relatório de saídas: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao carregar dados: $e")));
    }
  }

  @override
  void initState() {
    super.initState();
    carregarRelatorio();
  }

  Future<void> selecionarPeriodo() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: filtroData,
    );
    if (picked != null) {
      setState(() => filtroData = picked);
      carregarRelatorio();
    }
  }

  Widget _buildGrafico() {
    switch (tipoGrafico) {
      case "Linhas":
        return SfCartesianChart(
          title: ChartTitle(text: "Relatório de Saídas"),
          primaryXAxis: CategoryAxis(),
          series: [
            LineSeries<dynamic, String>(
              dataSource: relatorio,
              xValueMapper: (d, _) => d[campoX]?.toString() ?? "",
              yValueMapper: (d, _) => num.tryParse(d[campoY].toString()) ?? 0,
              markerSettings: const MarkerSettings(isVisible: true),
            ),
          ],
        );
      case "Colunas":
        return SfCartesianChart(
          title: ChartTitle(text: "Relatório de Saídas"),
          primaryXAxis: CategoryAxis(),
          series: [
            ColumnSeries<dynamic, String>(
              dataSource: relatorio,
              xValueMapper: (d, _) => d[campoX]?.toString() ?? "",
              yValueMapper: (d, _) => num.tryParse(d[campoY].toString()) ?? 0,
              dataLabelSettings: const DataLabelSettings(isVisible: true),
            ),
          ],
        );
      case "Pizza":
        return SfCircularChart(
          title: ChartTitle(text: "Distribuição de Saídas"),
          legend: const Legend(isVisible: true),
          series: [
            PieSeries<dynamic, String>(
              dataSource: relatorio,
              xValueMapper: (d, _) => d[campoX]?.toString() ?? "",
              yValueMapper: (d, _) => num.tryParse(d[campoY].toString()) ?? 0,
              dataLabelSettings: const DataLabelSettings(isVisible: true),
            ),
          ],
        );
      case "KPI":
        final total = relatorio.fold<num>(
          0,
          (sum, item) => sum + (num.tryParse(item[campoY].toString()) ?? 0),
        );
        return Center(
          child: SfRadialGauge(
            title: GaugeTitle(text: "KPI - Total $campoY"),
            axes: [
              RadialAxis(
                minimum: 0,
                maximum: total * 1.5,
                pointers: [
                  RangePointer(
                    value: total.toDouble(),
                    color: Colors.redAccent,
                  ),
                ],
                annotations: [
                  GaugeAnnotation(
                    widget: Text(
                      total.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      default:
        return const Center(child: Text("Selecione um tipo de gráfico"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      titulo: "Relatório de Saídas",
      nomeUsuario: widget.nomeUsuario,
      emailUsuario: widget.emailUsuario,
      corpo: carregando
          ? const Center(child: CircularProgressIndicator())
          : relatorio.isEmpty
          ? const Center(child: Text("Nenhum dado disponível para exibir."))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: tipoGrafico,
                          items: ["Linhas", "Colunas", "Pizza", "KPI"]
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text("Gráfico de $t"),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => tipoGrafico = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButton<String>(
                          value: campoX,
                          items: camposDisponiveis
                              .map(
                                (f) => DropdownMenuItem(
                                  value: f,
                                  child: Text("Eixo X: $f"),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => campoX = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButton<String>(
                          value: campoY,
                          items: camposDisponiveis
                              .map(
                                (f) => DropdownMenuItem(
                                  value: f,
                                  child: Text("Eixo Y: $f"),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => campoY = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        hint: const Text("Usuário"),
                        value: filtroUsuario,
                        items: usuarios
                            .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() => filtroUsuario = v);
                          carregarRelatorio();
                        },
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: selecionarPeriodo,
                        icon: const Icon(Icons.date_range),
                        label: const Text("Data"),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: StaggeredGrid.count(
                      crossAxisCount: 6,
                      children: [
                        StaggeredGridTile.fit(
                          crossAxisCellCount: 6,
                          child: Container(
                            height: 400,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: _buildGrafico(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
