import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'menu_lateral.dart';

const Color corPrincipal = Color(0xffbbfb04);

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

    String query = "";
    if (filtroUsuario != null) query += "&usuario=$filtroUsuario";
    if (filtroData != null) {
      query +=
          "&data_inicio=${filtroData!.start.toIso8601String()}&data_fim=${filtroData!.end.toIso8601String()}";
    }

    final response = await http.get(
      Uri.parse("http://localhost:8080/app/relatorio_saidas.php?$query"),
    );

    final data = jsonDecode(response.body);

    if (data["success"] == true) {
      setState(() {
        relatorio = List<dynamic>.from(data["dados"] ?? []);
        usuarios = List<String>.from(data["usuarios"] ?? []);
        carregando = false;
      });
    } else {
      carregando = false;
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

  // ===================== GRÁFICO =====================
  Widget _graficoPrincipal() {
    switch (tipoGrafico) {
      case "Linhas":
        return SfCartesianChart(
          backgroundColor: Colors.transparent,
          primaryXAxis: CategoryAxis(
            labelStyle: const TextStyle(color: corPrincipal),
          ),
          primaryYAxis: NumericAxis(
            labelStyle: const TextStyle(color: corPrincipal),
          ),
          series: [
            LineSeries<dynamic, String>(
              dataSource: relatorio,
              color: corPrincipal,
              markerSettings: const MarkerSettings(isVisible: true),
              xValueMapper: (d, _) => d[campoX].toString(),
              yValueMapper: (d, _) => num.tryParse(d[campoY].toString()) ?? 0,
            ),
          ],
        );

      case "Pizza":
        return SfCircularChart(
          legend: const Legend(
            isVisible: true,
            textStyle: TextStyle(color: corPrincipal),
          ),
          series: [
            PieSeries<dynamic, String>(
              dataSource: relatorio,
              xValueMapper: (d, _) => d[campoX].toString(),
              yValueMapper: (d, _) => num.tryParse(d[campoY].toString()) ?? 0,
              dataLabelSettings: const DataLabelSettings(
                isVisible: true,
                textStyle: TextStyle(color: corPrincipal),
              ),
            ),
          ],
        );

      case "KPI":
        final total = relatorio.fold<num>(
          0,
          (sum, item) => sum + (num.tryParse(item[campoY].toString()) ?? 0),
        );

        return SfRadialGauge(
          axes: [
            RadialAxis(
              minimum: 0,
              maximum: total * 1.5,
              axisLineStyle: const AxisLineStyle(color: Colors.white24),
              pointers: [
                RangePointer(value: total.toDouble(), color: corPrincipal),
              ],
              annotations: [
                GaugeAnnotation(
                  widget: Text(
                    total.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: corPrincipal,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      default:
        return SfCartesianChart(
          backgroundColor: Colors.transparent,
          primaryXAxis: CategoryAxis(
            labelStyle: const TextStyle(color: corPrincipal, fontSize: 10),
            labelAlignment: LabelAlignment.center,
            labelRotation: -0,
            labelIntersectAction: AxisLabelIntersectAction.wrap,
            majorGridLines: const MajorGridLines(width: 0),
            axisLine: const AxisLine(color: corPrincipal),
          ),
          primaryYAxis: NumericAxis(
            labelStyle: const TextStyle(color: corPrincipal),
            majorGridLines: MajorGridLines(
              color: corPrincipal.withOpacity(0.15),
            ),
          ),
          series: [
            ColumnSeries<dynamic, String>(
              dataSource: relatorio,
              color: corPrincipal,
              dataLabelSettings: const DataLabelSettings(
                isVisible: true,
                textStyle: TextStyle(color: corPrincipal),
              ),
              xValueMapper: (d, _) => d[campoX].toString(),
              yValueMapper: (d, _) => num.tryParse(d[campoY].toString()) ?? 0,
            ),
          ],
        );
    }
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      /// APPBAR IGUAL AO RELATÓRIO DE ENTRADAS
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: corPrincipal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Relatório de Saídas",
          style: TextStyle(color: corPrincipal, fontWeight: FontWeight.bold),
        ),
      ),

      body: BaseScaffold(
        titulo: "",
        nomeUsuario: widget.nomeUsuario,
        emailUsuario: widget.emailUsuario,
        corpo: carregando
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  /// FILTROS
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _dropdown(tipoGrafico, [
                          "Linhas",
                          "Colunas",
                          "Pizza",
                          "KPI",
                        ], (v) => setState(() => tipoGrafico = v)),
                        _dropdown(
                          campoX,
                          camposDisponiveis,
                          (v) => setState(() => campoX = v),
                        ),
                        _dropdown(
                          campoY,
                          camposDisponiveis,
                          (v) => setState(() => campoY = v),
                        ),
                        _dropdown(filtroUsuario, usuarios, (v) {
                          setState(() => filtroUsuario = v);
                          carregarRelatorio();
                        }, hint: "Usuário"),
                        ElevatedButton.icon(
                          onPressed: selecionarPeriodo,
                          icon: const Icon(
                            Icons.date_range,
                            color: Colors.black,
                          ),
                          label: const Text(
                            "Data",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: corPrincipal,
                            elevation: 8,
                            shadowColor: corPrincipal.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// CARD DO GRÁFICO (IGUAL AO ENTRADAS)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: corPrincipal.withOpacity(0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: corPrincipal.withOpacity(0.15),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: _graficoPrincipal(),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ===================== DROPDOWN PADRÃO =====================
  Widget _dropdown(
    String? value,
    List<String> itens,
    Function(String) onChanged, {
    String? hint,
  }) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        value: value,
        hint: hint != null
            ? Text(hint, style: const TextStyle(color: corPrincipal))
            : null,
        dropdownColor: Colors.black,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.black,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: corPrincipal.withOpacity(0.5)),
          ),
        ),
        style: const TextStyle(color: corPrincipal),
        items: itens
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => onChanged(v!),
      ),
    );
  }
}
