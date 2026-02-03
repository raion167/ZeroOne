// arquivo: contas_relatorio.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeroone/main.dart';

final supabase = Supabase.instance.client;

double _toDouble(dynamic v) {
  return double.tryParse(v.toString()) ?? 0.0;
}

/// --------------------------------------------------
/// SERVIÇO DE RELATÓRIOS (SUPABASE)
/// --------------------------------------------------
class RelatoriosService {
  static String get userId => supabase.auth.currentUser!.id;

  // ================= RESUMO =================
  static Future<Map<String, dynamic>> getResumo() async {
    final res = await supabase
        .from('contas_pagar')
        .select('status')
        .eq('user_id', userId);

    int pagas = 0;
    int pendentes = 0;
    int atrasadas = 0;

    for (final c in res) {
      switch (c['status']) {
        case 'Pago':
          pagas++;
          break;
        case 'Atrasado':
          atrasadas++;
          break;
        default:
          pendentes++;
      }
    }

    return {'pagas': pagas, 'pendentes': pendentes, 'atrasadas': atrasadas};
  }

  // ================= EVOLUÇÃO =================
  static Future<List<dynamic>> getEvolucaoMensal() async {
    final res = await supabase
        .from('contas_pagar')
        .select('vencimento, valor')
        .eq('user_id', userId);

    final Map<int, double> mapa = {};

    for (final c in res) {
      final mes = DateTime.parse(c['vencimento']).month;
      mapa[mes] = (mapa[mes] ?? 0) + _toDouble(c['valor']);
    }

    return mapa.entries.map((e) => {'mes': e.key, 'total': e.value}).toList();
  }

  // ================= CATEGORIAS =================
  static Future<List<dynamic>> getCategorias() async {
    final res = await supabase
        .from('contas_pagar')
        .select('categoria, valor')
        .eq('user_id', userId);

    final Map<String, double> mapa = {};
    for (final c in res) {
      final cat = (c['categoria'] ?? 'Outros').toString();
      mapa[cat] = (mapa[cat] ?? 0) + _toDouble(c['valor']);
    }

    final total = mapa.values.fold<double>(0, (a, b) => a + b);

    return mapa.entries
        .map(
          (e) => {
            'categoria': e.key,
            'valor': total == 0 ? 0 : (e.value / total) * 100,
          },
        )
        .toList();
  }

  // ================= FORNECEDORES =================
  static Future<List<dynamic>> getFornecedores() async {
    final res = await supabase
        .from('contas_pagar')
        .select('fornecedor, valor')
        .eq('user_id', userId);

    final Map<String, double> mapa = {};
    for (final c in res) {
      final forn = (c['fornecedor'] ?? 'Outros').toString();
      mapa[forn] = (mapa[forn] ?? 0) + _toDouble(c['valor']);
    }

    return mapa.entries
        .map((e) => {'fornecedor': e.key, 'total': e.value})
        .toList();
  }

  // ================= HEATMAP =================
  static Future<List<dynamic>> getHeatmap() async {
    final res = await supabase
        .from('contas_pagar')
        .select('vencimento')
        .eq('user_id', userId);

    int inicio = 0, meio = 0, fim = 0;

    for (final c in res) {
      final dia = DateTime.parse(c['vencimento']).day;
      if (dia <= 10) {
        inicio++;
      } else if (dia <= 20) {
        meio++;
      } else {
        fim++;
      }
    }

    return [
      [inicio, meio, fim],
    ];
  }
}

/// --------------------------------------------------
/// GRÁFICOS (VISUAL 100% PRESERVADO)
/// --------------------------------------------------

class GraficoStatusPagamento extends StatelessWidget {
  const GraficoStatusPagamento({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: RelatoriosService.getResumo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final d = snapshot.data!;
        return BarChart(
          BarChartData(
            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: d['pagas'].toDouble(),
                    color: Colors.green,
                  ),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(
                    toY: d['pendentes'].toDouble(),
                    color: Colors.orange,
                  ),
                ],
              ),
              BarChartGroupData(
                x: 2,
                barRods: [
                  BarChartRodData(
                    toY: d['atrasadas'].toDouble(),
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class GraficoEvolucaoMensal extends StatelessWidget {
  const GraficoEvolucaoMensal({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: RelatoriosService.getEvolucaoMensal(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final spots = snapshot.data!
            .map<FlSpot>(
              (e) =>
                  FlSpot((e['mes'] as int).toDouble(), _toDouble(e['total'])),
            )
            .toList();

        return LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: corPrincipal,
              ),
            ],
          ),
        );
      },
    );
  }
}

class GraficoCategorias extends StatelessWidget {
  const GraficoCategorias({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: RelatoriosService.getCategorias(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return PieChart(
          PieChartData(
            sections: snapshot.data!.map<PieChartSectionData>((e) {
              return PieChartSectionData(
                value: _toDouble(e['valor']),
                title: e['categoria'],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class GraficoFornecedores extends StatelessWidget {
  const GraficoFornecedores({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: RelatoriosService.getFornecedores(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return BarChart(
          BarChartData(
            barGroups: snapshot.data!.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: _toDouble(e.value['total']),
                    color: corPrincipal,
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class GraficoHeatmapVencimentos extends StatelessWidget {
  const GraficoHeatmapVencimentos({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: RelatoriosService.getHeatmap(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final valores = snapshot.data!.first as List;

        return Row(
          children: valores
              .map<Widget>(
                (v) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    height: 60,
                    color: corPrincipal.withOpacity(0.3 + (v / 10)),
                    child: Center(
                      child: Text(
                        v.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
