import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  List<Map<String, String>> usuarios =
      []; // 🔥 Mapeado igual entradas para conter ID e Nome

  bool modoComparativo = false;

  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> carregarRelatorio() async {
    setState(() => carregando = true);

    try {
      // 1. Consulta no Supabase trazendo o relacionamento da FK 'estoque' e filtrando por 'saida'
      var query = supabase
          .from('movimentacoes_estoque')
          .select('''
        id,
        quantidade,
        user_id,
        tipo,
        data_movimentacao,
        estoque (
          nome
        )
      ''')
          .eq('tipo', 'saida'); // 🔥 Diferencial: Filtrando apenas as saídas

      // 2. Aplica os filtros na Query
      if (filtroUsuario != null) {
        query = query.eq('user_id', filtroUsuario!);
      }

      if (filtroData != null) {
        query = query
            .gte('data_movimentacao', filtroData!.start.toIso8601String())
            .lte('data_movimentacao', filtroData!.end.toIso8601String());
      }

      final List<dynamic> dadosDoBanco = await query.order(
        'data_movimentacao',
        ascending: false,
      );

      // 3. Busca a tabela de usuários para cruzar os nomes (Ajuste 'perfis' se necessário)
      final List<dynamic> dadosUsuarios = await supabase
          .from('usuarios')
          .select('id, nome');

      final Map<String, String> mapaNomesUsuarios = {
        for (var u in dadosUsuarios) u['id'].toString(): u['nome'].toString(),
      };

      // 4. Formata os dados para a leitura dos gráficos do Syncfusion
      final dadosFormatados = dadosDoBanco.map((item) {
        final userId = item['user_id']?.toString() ?? '';
        return {
          "produto": item['estoque'] != null
              ? item['estoque']['nome']
              : 'Produto K',
          "quantidade": item['quantidade'],
          "usuario":
              mapaNomesUsuarios[userId] ??
              (userId.length > 8 ? userId.substring(0, 8) : 'N/D'),
          "data_movimentacao": item['data_movimentacao'],
        };
      }).toList();

      // 5. Gera a lista única do Dropdown de filtros
      final List<Map<String, String>> listaDropdownUsuarios = [];
      final setIdsExistentes = dadosDoBanco
          .map((item) => item['user_id']?.toString())
          .toSet();

      for (var id in setIdsExistentes) {
        if (id != null) {
          listaDropdownUsuarios.add({
            "id": id,
            "nome": mapaNomesUsuarios[id] ?? id.substring(0, 8),
          });
        }
      }

      setState(() {
        relatorio = dadosFormatados;
        usuarios = listaDropdownUsuarios;
        carregando = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar dados do Supabase: $e");
      setState(() => carregando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao carregar relatório: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
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
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: corPrincipal,
              onPrimary: Colors.black,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => filtroData = picked);
      carregarRelatorio();
    }
  }

  // ===================== GRAFICO PRINCIPAL =====================
  Widget _graficoPrincipal() {
    switch (tipoGrafico) {
      case "Linhas":
        return SfCartesianChart(
          backgroundColor: Colors.transparent,
          primaryXAxis: CategoryAxis(
            labelStyle: const TextStyle(color: corPrincipal),
            axisLine: const AxisLine(color: corPrincipal),
            majorGridLines: const MajorGridLines(width: 0),
          ),
          primaryYAxis: NumericAxis(
            labelStyle: const TextStyle(color: corPrincipal),
            majorGridLines: MajorGridLines(
              color: corPrincipal.withOpacity(0.15),
            ),
          ),
          series: [
            LineSeries<dynamic, String>(
              dataSource: relatorio,
              color: corPrincipal,
              markerSettings: const MarkerSettings(isVisible: true),
              xValueMapper: (d, _) => d[campoX].toString(),
              yValueMapper: (d, _) {
                final valor = d[campoY];
                if (valor is num) return valor;
                return num.tryParse(valor?.toString() ?? '') ?? 0;
              },
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
              yValueMapper: (d, _) {
                final valor = d[campoY];
                if (valor is num) return valor;
                return num.tryParse(valor?.toString() ?? '') ?? 0;
              },
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
              maximum: total == 0 ? 100 : total * 1.5,
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
            labelStyle: const TextStyle(color: corPrincipal),
          ),
          primaryYAxis: NumericAxis(
            labelStyle: const TextStyle(color: corPrincipal),
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
              yValueMapper: (d, _) {
                final valor = d[campoY];
                if (valor is num) return valor;
                return num.tryParse(valor?.toString() ?? '') ?? 0;
              },
            ),
          ],
        );
    }
  }

  // ===================== COMPARATIVO =====================
  Widget _graficoComparativo() {
    final Map<String, num> dados = {};

    for (var item in relatorio) {
      final usuario = item["usuario"] ?? "N/D";
      dados[usuario] =
          (dados[usuario] ?? 0) +
          (num.tryParse(item["quantidade"].toString()) ?? 0);
    }

    final lista = dados.entries
        .map((e) => {"usuario": e.key, "total": e.value})
        .toList();

    return SfCartesianChart(
      backgroundColor: Colors.black,
      primaryXAxis: CategoryAxis(
        labelStyle: const TextStyle(color: corPrincipal),
      ),
      primaryYAxis: NumericAxis(
        labelStyle: const TextStyle(color: corPrincipal),
      ),
      series: [
        ColumnSeries<dynamic, String>(
          dataSource: lista,
          color: corPrincipal,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(color: corPrincipal),
          ),
          xValueMapper: (d, _) => d["usuario"].toString(),
          yValueMapper: (d, _) => d["total"],
        ),
      ],
    );
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    // 🔥 Removido o Scaffold de fora. O BaseScaffold gerencia a AppBar e o Pop automaticamente.
    return BaseScaffold(
      titulo: "Relatório de Saídas",
      nomeUsuario: widget.nomeUsuario,
      emailUsuario: widget.emailUsuario,
      mostrarBotaoVoltar: true,
      corpo: carregando
          ? const Center(child: CircularProgressIndicator(color: corPrincipal))
          : Column(
              children: [
                /// FILTROS COM SUPORTE A ROLAGEM HORIZONTAL (Previne estouro de tela)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      spacing: 10,
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
                        _dropdownUsuario(filtroUsuario, usuarios, (v) {
                          setState(() => filtroUsuario = v);
                          carregarRelatorio();
                        }, hint: "Usuário"),

                        /// BOTÃO DATA
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),

                        /// BOTÃO COMPARAR
                        ElevatedButton.icon(
                          onPressed: () => setState(
                            () => modoComparativo = !modoComparativo,
                          ),
                          icon: const Icon(Icons.compare, color: Colors.black),
                          label: Text(
                            modoComparativo ? "Visão Geral" : "Comparar",
                            style: const TextStyle(
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                /// CARD DO GRÁFICO
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
                      child: modoComparativo
                          ? _graficoComparativo()
                          : _graficoPrincipal(),
                    ),
                  ),
                ),
              ],
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

  // ===================== DROPDOWN USUÁRIO =====================
  Widget _dropdownUsuario(
    String? value,
    List<Map<String, String>> itens,
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
            .map(
              (e) => DropdownMenuItem<String>(
                value: e["id"],
                child: Text(e["nome"]!),
              ),
            )
            .toList(),
        onChanged: (v) => onChanged(v!),
      ),
    );
  }
}
