import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeroone/pages/contas_visao_geral.dart';

final supabase = Supabase.instance.client;

class EntradasPorMesPage extends StatefulWidget {
  const EntradasPorMesPage({super.key});

  @override
  State<EntradasPorMesPage> createState() => _EntradasPorMesPageState();
}

class _EntradasPorMesPageState extends State<EntradasPorMesPage> {
  bool loading = true;
  List<Map<String, dynamic>> dados = [];

  String get userId => supabase.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    try {
      final res = await supabase
          .from('entradas')
          .select('data_competencia, valor_recebido')
          .eq('user_id', userId);

      final Map<String, double> totalPorMes = {};

      for (final e in res) {
        final data = DateTime.parse(e['data_competencia']);
        final chaveMes =
            "${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}";

        final valor = double.tryParse(e['valor_recebido'].toString()) ?? 0;

        totalPorMes[chaveMes] = (totalPorMes[chaveMes] ?? 0) + valor;
      }

      final lista = totalPorMes.entries.map((e) {
        return {'mes': e.key, 'total': e.value.toStringAsFixed(2)};
      }).toList();

      lista.sort(
        (a, b) => (a['mes'] as DateTime).compareTo(b['mes'] as DateTime),
      );

      setState(() {
        dados = lista;
        loading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar entradas por mês: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(
        title: const Text("Entradas por Mês"),
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    "Entradas Mensais",
                    style: TextStyle(
                      color: corPrincipal,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: corPrincipal, blurRadius: 12)],
                    ),
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
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: corPrincipal.withOpacity(0.16),
                              strokeWidth: 1,
                            ),
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
                                      fontSize: 13,
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
                                    final mes = dados[value.toInt()]['mes'];
                                    final partes = mes.split('-');
                                    return Text(
                                      "${partes[1]}/${partes[0]}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),

                          barGroups: dados.asMap().entries.map((e) {
                            final index = e.key;
                            final valor = double.parse(e.value['total']);

                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: valor,
                                  width: 18,
                                  color: corPrincipal,
                                  borderRadius: BorderRadius.circular(6),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: valor,
                                    color: corPrincipal.withOpacity(0.1),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
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
