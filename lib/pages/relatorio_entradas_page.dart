import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'menu_lateral.dart';

class RelatorioEntradasPage extends StatefulWidget {
  final String nomeUsuario;
  final String emailUsuario;

  const RelatorioEntradasPage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  State<RelatorioEntradasPage> createState() => _RelatorioEntradasPageState();
}

class _RelatorioEntradasPageState extends State<RelatorioEntradasPage> {
  bool carregando = true;
  List<dynamic> relatorio = [];
  String tipoGrafico = "Colunas";
  String campoX = "produto";
  String campoY = "quantidade";
  final camposDisponiveis = ["produto", "quantidade", "usuario"];
  DateTimeRange? filtroData;
  String? filtroUsuario;
  List<String> usuarios = [];
  bool modoComparativo = false;

  Future<void> carregarRelatorio() async {
    setState(() => carregando = true);
    String query = "";
    if (filtroUsuario != null) query += "&usuario=$filtroUsuario";
    if (filtroData != null) {
      query +=
          "&data_inicio=${filtroData!.start.toIso8601String()}&data_fim=${filtroData!.end.toIso8601String()}";
    }

    final response = await http.get(
      Uri.parse("http://localhost:8080/app/relatorio_entradas.php?$query"),
    );

    final data = jsonDecode(response.body);

    if (data["success"] == true) {
      setState(() {
        relatorio = List<dynamic>.from(data["dados"] ?? []);
        usuarios = List<String>.from(data["usuarios"] ?? []);
        carregando = false;
      });
    } else {
      setState(() => carregando = false);
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

  /// ====== GRÁFICO PRINCIPAL ======
  Widget _buildGraficoPrincipal() {
    switch (tipoGrafico) {
      case "Linhas":
        return SfCartesianChart(
          title: ChartTitle(text: "Relatório de Entradas"),
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
          title: ChartTitle(text: "Relatório de Entradas"),
          primaryXAxis: CategoryAxis(),
          series: [
            ColumnSeries<dynamic, String>(
              dataSource: relatorio,
              xValueMapper: (d, _) => d[campoX]?.toString() ?? "",
              yValueMapper: (d, _) => num.tryParse(d[campoY].toString()) ?? 0,
              dataLabelSettings: const DataLabelSettings(isVisible: true),
              color: Colors.greenAccent.shade700,
            ),
          ],
        );
      case "Pizza":
        return SfCircularChart(
          title: ChartTitle(text: "Distribuição de Entradas"),
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
            title: GaugeTitle(text: "KPI - Total de ${campoY.toUpperCase()}"),
            axes: [
              RadialAxis(
                minimum: 0,
                maximum: total * 1.5,
                pointers: [
                  RangePointer(value: total.toDouble(), color: Colors.green),
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

  /// ====== GRÁFICO COMPARATIVO ======
  Widget _buildGraficoComparativo() {
    Map<String, num> entradasPorUsuario = {};
    for (var item in relatorio) {
      String usuario = item["usuario"] ?? "Desconhecido";
      num qtd = num.tryParse(item["quantidade"].toString()) ?? 0;
      entradasPorUsuario[usuario] = (entradasPorUsuario[usuario] ?? 0) + qtd;
    }

    final dados = entradasPorUsuario.entries
        .map((e) => {"usuario": e.key, "total": e.value})
        .toList();

    return SfCartesianChart(
      title: ChartTitle(text: "Comparativo de Entradas por Usuário"),
      primaryXAxis: CategoryAxis(),
      legend: const Legend(isVisible: false),
      series: [
        ColumnSeries<dynamic, String>(
          dataSource: dados,
          xValueMapper: (d, _) => d["usuario"].toString(),
          yValueMapper: (d, _) => d["total"],
          dataLabelSettings: const DataLabelSettings(isVisible: true),
          color: Colors.greenAccent.shade700,
        ),
      ],
    );
  }

  /// ====== INTERFACE ======
  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      titulo: "Relatório de Entradas",
      nomeUsuario: widget.nomeUsuario,
      emailUsuario: widget.emailUsuario,
      corpo: carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      DropdownButton<String>(
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
                      DropdownButton<String>(
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
                      DropdownButton<String>(
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
                      ElevatedButton.icon(
                        onPressed: selecionarPeriodo,
                        icon: const Icon(Icons.date_range),
                        label: const Text("Data"),
                      ),
                      ElevatedButton.icon(
                        onPressed: () =>
                            setState(() => modoComparativo = !modoComparativo),
                        icon: const Icon(Icons.compare_arrows),
                        label: Text(
                          modoComparativo
                              ? "Ver Visão Geral"
                              : "Comparar Usuários",
                        ),
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
                          child: GestureDetector(
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
                              child: modoComparativo
                                  ? _buildGraficoComparativo()
                                  : _buildGraficoPrincipal(),
                            ),
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
