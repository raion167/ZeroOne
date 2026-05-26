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
        final id = filtroUsuario!.split("|").last;
        query = query.eq('user_id', id);
      }

      if (filtroData != null) {
        query = query
            .gte('data_movimentacao', filtroData!.start.toIso8601String())
            .lte('data_movimentacao', filtroData!.end.toIso8601String());
      }

      final response = await query;

      relatorio = List<Map<String, dynamic>>.from(response).map((item) {
        final qtd = item['quantidade'];

        num quantidadeNumerica = 0;
        if (qtd is num) {
          quantidadeNumerica = qtd;
        } else if (qtd != null) {
          quantidadeNumerica = num.tryParse(qtd.toString()) ?? 0;
        }

        return {
          "produto": item['estoque']?['nome']?.toString() ?? "-",
          "quantidade": quantidadeNumerica,
          "usuario": item['usuario']?['nome']?.toString() ?? "-",
        };
      }).toList();

      campoY = "quantidade";

      final usuariosResp = await supabase.from('usuarios').select('id, nome');

      usuarios = usuariosResp
          .map<String>((u) => "${u['nome']}|${u['id']}")
          .toList();

      setState(() => carregando = false);
    } catch (e) {
      setState(() => carregando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro relatório: $e")));
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
    num parseValor(dynamic valor) {
      if (valor == null) return 0;
      if (valor is num) return valor;
      return num.tryParse(valor.toString()) ?? 0;
    }

    switch (tipoGrafico) {
      case "Linhas":
        return SfCartesianChart(
          backgroundColor: Colors.black,
          // 🔥 CORREÇÃO: Define que o eixo X aceita textos/categorias
          primaryXAxis: const CategoryAxis(
            labelStyle: TextStyle(color: Colors.white),
          ),
          primaryYAxis: const NumericAxis(
            labelStyle: TextStyle(color: Colors.white),
          ),
          series: [
            LineSeries<Map<String, dynamic>, String>(
              dataSource: relatorio,
              xValueMapper: (d, _) => d[campoX]?.toString() ?? "",
              yValueMapper: (d, _) => parseValor(d[campoY]),
              color: corPrincipal,
            ),
          ],
        );

      case "Colunas":
        return SfCartesianChart(
          backgroundColor: Colors.black,
          // 🔥 CORREÇÃO: Define que o eixo X aceita textos/categorias
          primaryXAxis: const CategoryAxis(
            labelStyle: TextStyle(color: Colors.white),
          ),
          primaryYAxis: const NumericAxis(
            labelStyle: TextStyle(color: Colors.white),
          ),
          series: [
            ColumnSeries<Map<String, dynamic>, String>(
              dataSource: relatorio,
              xValueMapper: (d, _) => d[campoX]?.toString() ?? "",
              yValueMapper: (d, _) => parseValor(d[campoY]),
              color: corPrincipal,
            ),
          ],
        );

      case "Pizza":
        return SfCircularChart(
          backgroundColor: Colors.black,
          legend: const Legend(
            isVisible: true,
            textStyle: TextStyle(color: Colors.white),
          ),
          series: [
            PieSeries<Map<String, dynamic>, String>(
              dataSource: relatorio,
              xValueMapper: (d, _) => d[campoX]?.toString() ?? "",
              yValueMapper: (d, _) => parseValor(d[campoY]),
              dataLabelSettings: const DataLabelSettings(isVisible: true),
            ),
          ],
        );

      case "KPI":
        final total = relatorio.fold<num>(
          0,
          (sum, item) => sum + parseValor(item[campoY]),
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
                    total.toStringAsFixed(0),
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
    // 🔥 CORREÇÃO: Removido o Scaffold/AppBar redundantes de cima
    return BaseScaffold(
      titulo: "Relatório de Estoque",
      nomeUsuario: widget.nomeUsuario,
      emailUsuario: widget.emailUsuario,
      mostrarBotaoVoltar: true,
      corpo: carregando
          ? const Center(child: CircularProgressIndicator(color: corPrincipal))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
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
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: ElevatedButton.icon(
                            onPressed: selecionarPeriodo,
                            icon: const Icon(Icons.date_range),
                            label: Text(
                              filtroData == null
                                  ? "Filtrar Data"
                                  : "Data Ativa",
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: corPrincipal,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D0D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: _buildGrafico(),
                    ),
                  ),
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
  return Padding(
    padding: const EdgeInsets.all(6),
    child: SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: Colors.black,
        iconEnabledColor: corPrincipal,
        style: const TextStyle(color: corPrincipal),
        hint: hint != null
            ? Text(hint, style: const TextStyle(color: Colors.white54))
            : null,
        decoration: InputDecoration(
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: corPrincipal, width: 2),
          ),
        ),
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e.contains('|') ? e.split('|').first : e,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    ),
  );
}
