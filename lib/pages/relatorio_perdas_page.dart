import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'menu_lateral.dart';

const Color corPrincipal = Color(0xFFBBFB04);

class RelatorioPerdasPage extends StatefulWidget {
  final String nomeUsuario;
  final String emailUsuario;

  const RelatorioPerdasPage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  State<RelatorioPerdasPage> createState() => _RelatorioPerdasPageState();
}

class _RelatorioPerdasPageState extends State<RelatorioPerdasPage> {
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

  @override
  void initState() {
    super.initState();
    carregarRelatorio();
  }

  Future<void> carregarRelatorio() async {
    setState(() => carregando = true);

    String query = "";
    if (filtroUsuario != null) query += "&usuario=$filtroUsuario";
    if (filtroData != null) {
      query +=
          "&data_inicio=${filtroData!.start.toIso8601String()}"
          "&data_fim=${filtroData!.end.toIso8601String()}";
    }

    final response = await http.get(
      Uri.parse("http://localhost:8080/app/relatorio_perdas.php?$query"),
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
        return _graficoCartesian(
          LineSeries<dynamic, String>(
            dataSource: relatorio,
            xValueMapper: (d, _) => d[campoX]?.toString() ?? "",
            yValueMapper: (d, _) => num.tryParse(d[campoY].toString()) ?? 0,
            color: corPrincipal,
            markerSettings: const MarkerSettings(isVisible: true),
          ),
        );

      case "Colunas":
        return _graficoCartesian(
          ColumnSeries<dynamic, String>(
            dataSource: relatorio,
            xValueMapper: (d, _) => d[campoX]?.toString() ?? "",
            yValueMapper: (d, _) => num.tryParse(d[campoY].toString()) ?? 0,
            color: corPrincipal,
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              textStyle: TextStyle(color: corPrincipal),
            ),
          ),
        );

      case "Pizza":
        return SfCircularChart(
          backgroundColor: Colors.black,
          title: ChartTitle(
            text: "Distribuição de Perdas",
            textStyle: TextStyle(color: corPrincipal),
          ),
          legend: Legend(
            isVisible: true,
            textStyle: TextStyle(color: corPrincipal),
          ),
          series: [
            PieSeries<dynamic, String>(
              dataSource: relatorio,
              xValueMapper: (d, _) => d[campoX]?.toString() ?? "",
              yValueMapper: (d, _) => num.tryParse(d[campoY].toString()) ?? 0,
              dataLabelSettings: DataLabelSettings(
                isVisible: true,
                textStyle: TextStyle(color: corPrincipal),
              ),
              pointColorMapper: (_, __) => corPrincipal,
            ),
          ],
        );

      case "KPI":
        final total = relatorio.fold<num>(
          0,
          (sum, item) => sum + (num.tryParse(item[campoY].toString()) ?? 0),
        );

        return SfRadialGauge(
          backgroundColor: Colors.black,
          title: GaugeTitle(
            text: "KPI - Total de Perdas",
            textStyle: TextStyle(color: corPrincipal),
          ),
          axes: [
            RadialAxis(
              minimum: 0,
              maximum: total * 1.5,
              axisLabelStyle: GaugeTextStyle(color: corPrincipal),
              pointers: [
                RangePointer(value: total.toDouble(), color: corPrincipal),
              ],
              annotations: [
                GaugeAnnotation(
                  widget: Text(
                    total.toStringAsFixed(0),
                    style: TextStyle(
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
        return const SizedBox();
    }
  }

  /// ====== GRÁFICO COMPARATIVO ======
  Widget _buildGraficoComparativo() {
    final Map<String, num> perdasPorUsuario = {};

    for (var item in relatorio) {
      final usuario = item["usuario"] ?? "Desconhecido";
      final qtd = num.tryParse(item["quantidade"].toString()) ?? 0;
      perdasPorUsuario[usuario] = (perdasPorUsuario[usuario] ?? 0) + qtd;
    }

    final dados = perdasPorUsuario.entries
        .map((e) => {"usuario": e.key, "total": e.value})
        .toList();

    return _graficoCartesian(
      ColumnSeries<dynamic, String>(
        dataSource: dados,
        xValueMapper: (d, _) => d["usuario"],
        yValueMapper: (d, _) => d["total"],
        color: corPrincipal,
        dataLabelSettings: DataLabelSettings(
          isVisible: true,
          textStyle: TextStyle(color: corPrincipal),
        ),
      ),
      titulo: "Comparativo de Perdas por Usuário",
    );
  }

  /// ====== CARTESIAN PADRÃO ======
  Widget _graficoCartesian(CartesianSeries series, {String? titulo}) {
    return SfCartesianChart(
      backgroundColor: Colors.black,
      title: ChartTitle(
        text: titulo ?? "Relatório de Perdas",
        textStyle: TextStyle(color: corPrincipal),
      ),
      primaryXAxis: CategoryAxis(
        labelStyle: TextStyle(color: corPrincipal),
        axisLine: AxisLine(color: corPrincipal),
        majorGridLines: const MajorGridLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        labelStyle: TextStyle(color: corPrincipal),
        majorGridLines: MajorGridLines(color: corPrincipal.withOpacity(0.15)),
      ),
      series: [series],
    );
  }

  /// ====== INTERFACE ======
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: corPrincipal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Relatório de Perdas",
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
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _filtroDropdown(
                          value: tipoGrafico,
                          items: ["Linhas", "Colunas", "Pizza", "KPI"],
                          labelBuilder: (v) => "Gráfico: $v",
                          onChanged: (v) => setState(() => tipoGrafico = v!),
                        ),
                        _filtroDropdown(
                          value: campoX,
                          items: camposDisponiveis,
                          labelBuilder: (v) => "Eixo X: $v",
                          onChanged: (v) => setState(() => campoX = v!),
                        ),
                        _filtroDropdown(
                          value: campoY,
                          items: camposDisponiveis,
                          labelBuilder: (v) => "Eixo Y: $v",
                          onChanged: (v) => setState(() => campoY = v!),
                        ),
                        _filtroDropdown(
                          value: filtroUsuario,
                          items: usuarios,
                          hint: "Usuário",
                          onChanged: (v) {
                            setState(() => filtroUsuario = v);
                            carregarRelatorio();
                          },
                        ),
                        ElevatedButton.icon(
                          onPressed: selecionarPeriodo,
                          icon: const Icon(Icons.date_range),
                          label: const Text("Data"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: corPrincipal,
                            foregroundColor: Colors.black,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => setState(
                            () => modoComparativo = !modoComparativo,
                          ),
                          icon: const Icon(Icons.compare_arrows),
                          label: Text(
                            modoComparativo
                                ? "Visão Geral"
                                : "Comparar Usuários",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: corPrincipal,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: corPrincipal.withOpacity(0.7),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: corPrincipal.withOpacity(0.25),
                              blurRadius: 12,
                              spreadRadius: 1,
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
    );
  }
}

/// ====== DROPDOWN PADRÃO ======
Widget _filtroDropdown({
  required String? value,
  required List<String> items,
  required ValueChanged<String?> onChanged,
  String? hint,
  String Function(String)? labelBuilder,
}) {
  return SizedBox(
    width: 200,
    child: DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      dropdownColor: Colors.black,
      iconEnabledColor: corPrincipal,
      style: TextStyle(color: corPrincipal),
      hint: hint != null
          ? Text(hint, style: TextStyle(color: corPrincipal))
          : null,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: corPrincipal),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: corPrincipal, width: 2),
        ),
      ),
      items: items.map((e) {
        return DropdownMenuItem<String>(
          value: e,
          child: Text(
            labelBuilder != null ? labelBuilder(e) : e,
            style: TextStyle(color: corPrincipal),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    ),
  );
}
