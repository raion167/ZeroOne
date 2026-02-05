import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'menu_lateral.dart';

const Color corPrincipal = Color(0xFFBBFB04);
final supabase = Supabase.instance.client;

class RelatorioEstoquePage extends StatefulWidget {
  final String nomeUsuario;
  final String emailUsuario;

  const RelatorioEstoquePage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  State<RelatorioEstoquePage> createState() => _RelatorioEstoquePageState();
}

class _RelatorioEstoquePageState extends State<RelatorioEstoquePage> {
  bool carregando = true;

  List<Map<String, dynamic>> relatorio = [];
  List<String> usuarios = [];

  String tipoGrafico = "Colunas";
  String campoX = "produto";
  String campoY = "quantidade";
  final camposTexto = ["produto", "usuario"];
  final camposNumero = ["quantidade"];
  DateTimeRange? filtroData;
  String? filtroUsuario;

  @override
  void initState() {
    super.initState();
    carregarRelatorio();
  }

  // ================= CARREGAR RELATÓRIO =================
  Future<void> carregarRelatorio() async {
    setState(() => carregando = true);

    try {
      var query = supabase.from('movimentacoes_estoque').select('''
        quantidade,
        data_movimentacao,
        estoque:produto_id(nome),
        usuario:user_id(nome)
      ''');

      if (filtroUsuario != null) {
        query = query.eq('user_id', filtroUsuario!);
      }

      if (filtroData != null) {
        query = query
            .gte('data_movimentacao', filtroData!.start.toIso8601String())
            .lte('data_movimentacao', filtroData!.end.toIso8601String());
      }

      final response = await query;

      relatorio = List<Map<String, dynamic>>.from(response).map((item) {
        return {
          "produto": item['estoque']?['nome'] ?? "-",
          "quantidade": item['quantidade'] ?? 0,
          "usuario": item['usuario']?['nome'] ?? "-",
        };
      }).toList();

      // carregar usuários para filtro
      final usuariosResp = await supabase.from('usuarios').select('id, nome');

      usuarios = usuariosResp.map<String>((u) => u['id'].toString()).toList();

      setState(() => carregando = false);
    } catch (e) {
      setState(() => carregando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao carregar relatório: $e")));
    }
  }

  // ================= DATE PICKER =================
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

  // ================= GRÁFICO =================
  Widget _buildGrafico() {
    switch (tipoGrafico) {
      case "Linhas":
        return SfCartesianChart(
          backgroundColor: Colors.black,
          series: [
            LineSeries(
              dataSource: relatorio,
              xValueMapper: (d, _) => d[campoX],
              yValueMapper: (d, _) => d[campoY],
              color: corPrincipal,
            ),
          ],
        );

      case "Colunas":
        return SfCartesianChart(
          backgroundColor: Colors.black,
          series: [
            ColumnSeries(
              dataSource: relatorio,
              xValueMapper: (d, _) => d[campoX],
              yValueMapper: (d, _) => d[campoY],
              color: corPrincipal,
            ),
          ],
        );

      case "Pizza":
        return SfCircularChart(
          backgroundColor: Colors.black,
          series: [
            PieSeries(
              dataSource: relatorio,
              xValueMapper: (d, _) => d[campoX],
              yValueMapper: (d, _) => d[campoY],
            ),
          ],
        );

      case "KPI":
        final total = relatorio.fold<num>(
          0,
          (sum, item) => sum + (item[campoY] ?? 0),
        );

        return SfRadialGauge(
          backgroundColor: Colors.black,
          axes: [
            RadialAxis(
              pointers: [
                RangePointer(value: total.toDouble(), color: corPrincipal),
              ],
              annotations: [
                GaugeAnnotation(
                  widget: Text(
                    total.toString(),
                    style: TextStyle(
                      fontSize: 26,
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

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Relatório Estoque"),
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
      ),
      body: BaseScaffold(
        titulo: "",
        nomeUsuario: widget.nomeUsuario,
        emailUsuario: widget.emailUsuario,
        corpo: carregando
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Wrap(
                    spacing: 10,
                    children: [
                      _dropdown(tipoGrafico, [
                        "Linhas",
                        "Colunas",
                        "Pizza",
                        "KPI",
                      ], (v) => setState(() => tipoGrafico = v!)),
                      _dropdown(
                        campoX,
                        camposTexto,
                        (v) => setState(() => campoX = v!),
                      ),
                      _dropdown(
                        campoY,
                        camposNumero,
                        (v) => setState(() => campoY = v!),
                      ),
                      _dropdown(filtroUsuario, usuarios, (v) {
                        filtroUsuario = v;
                        carregarRelatorio();
                      }, hint: "Usuário"),
                      ElevatedButton(
                        onPressed: selecionarPeriodo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: corPrincipal,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text("Data"),
                      ),
                    ],
                  ),
                  Expanded(child: _buildGrafico()),
                ],
              ),
      ),
    );
  }
}

// ================= DROPDOWN =================
Widget _dropdown(
  String? value,
  List<String> items,
  ValueChanged<String?> onChanged, {
  String? hint,
}) {
  return SizedBox(
    width: 180,
    child: DropdownButtonFormField<String>(
      value: value,
      dropdownColor: Colors.black,
      iconEnabledColor: corPrincipal,
      style: const TextStyle(color: corPrincipal),
      hint: hint != null ? Text(hint) : null,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: corPrincipal),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: corPrincipal, width: 2),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    ),
  );
}
