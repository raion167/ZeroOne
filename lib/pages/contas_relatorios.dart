// arquivo: contas_relatorio.dart

import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// --------------------------------------------------
/// Serviço que consome a API de relatórios
/// --------------------------------------------------
class RelatoriosService {
  // Ajuste para a sua URL real (http(s)://seu-servidor/app)
  static const String baseUrl = "http://localhost:8080/app";

  static Future<Map<String, dynamic>> getResumo() async {
    final resp = await http.get(Uri.parse("$baseUrl/resumo.php"));
    if (resp.statusCode != 200) throw Exception("Erro ao carregar resumo");
    final decoded = json.decode(resp.body);
    // Garante que é um mapa e padroniza campos numéricos
    return Map<String, dynamic>.from(decoded);
  }

  static Future<List<dynamic>> getEvolucaoMensal() async {
    final resp = await http.get(Uri.parse("$baseUrl/evolucao.php"));
    if (resp.statusCode != 200) throw Exception("Erro ao carregar evolução");
    return json.decode(resp.body) as List<dynamic>;
  }

  static Future<List<dynamic>> getCategorias() async {
    final resp = await http.get(Uri.parse("$baseUrl/categorias_relatorio.php"));
    if (resp.statusCode != 200) throw Exception("Erro ao carregar categorias");
    return json.decode(resp.body) as List<dynamic>;
  }

  static Future<List<dynamic>> getFornecedores() async {
    final resp = await http.get(Uri.parse("$baseUrl/fornecedores.php"));
    if (resp.statusCode != 200)
      throw Exception("Erro ao carregar fornecedores");
    return json.decode(resp.body) as List<dynamic>;
  }

  static Future<List<dynamic>> getHeatmap() async {
    final resp = await http.get(Uri.parse("$baseUrl/heatmap.php"));
    if (resp.statusCode != 200) throw Exception("Erro ao carregar heatmap");
    return json.decode(resp.body) as List<dynamic>;
  }

  static Future<List<dynamic>> getFluxoFuturo() async {
    final resp = await http.get(Uri.parse("$baseUrl/fluxo_futuro.php"));
    if (resp.statusCode != 200)
      throw Exception("Erro ao carregar fluxo futuro");
    return json.decode(resp.body) as List<dynamic>;
  }
}

/// --------------------------------------------------
/// Widgets de gráficos (consomem RelatoriosService)
/// --------------------------------------------------
//=============== GRAFICO DE STATUS ==================//
class GraficoStatusPagamento extends StatelessWidget {
  const GraficoStatusPagamento({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: RelatoriosService.getResumo(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Erro: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Center(child: Text("Sem dados"));
        }

        final resumo = snapshot.data!;
        double pagas = _toDouble(resumo["pagas"]);
        double pendentes = _toDouble(resumo["pendentes"]);
        double atrasadas = _toDouble(resumo["atrasadas"]);

        return LayoutBuilder(
          builder: (context, constraints) {
            double largura = constraints.maxWidth;
            double barWidth = (largura * 0.12).clamp(16.0, 32.0);
            double fontSize = (largura * 0.04).clamp(10.0, 18.0);

            return BarChart(
              // ANIMAÇÃO (correta: no construtor do BarChart)
              BarChartData(
                barTouchData: BarTouchData(enabled: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: pagas,
                        color: Colors.green,
                        borderRadius: BorderRadius.zero,
                        width: barWidth,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: pendentes,
                        color: Colors.orange,
                        borderRadius: BorderRadius.zero,
                        width: barWidth,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: atrasadas,
                        color: Colors.red,
                        borderRadius: BorderRadius.zero,
                        width: barWidth,
                      ),
                    ],
                  ),
                ],

                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final estilo = TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                        );
                        switch (value.toInt()) {
                          case 0:
                            return Text("Pagas", style: estilo);
                          case 1:
                            return Text("Pendentes", style: estilo);
                          case 2:
                            return Text("Atrasadas", style: estilo);
                          default:
                            return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(fontSize: fontSize),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),

                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    strokeWidth: 0.6,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
              ),
              // coloque a animação AQUI
              swapAnimationDuration: const Duration(milliseconds: 900),
              swapAnimationCurve: Curves.easeOutCubic,
            );
          },
        );
      },
    );
  }
}

//=============== GRAFICO DE EVOLUÇÃO MENSAL ==================//
class GraficoEvolucaoMensal extends StatelessWidget {
  const GraficoEvolucaoMensal({super.key});

  static const List<String> nomesMeses = [
    "", // índice zero ignorado
    "Jan", "Fev", "Mar", "Abr", "Mai", "Jun",
    "Jul", "Ago", "Set", "Out", "Nov", "Dez",
  ];

  double _toDouble(dynamic v) {
    return double.tryParse(v.toString()) ?? 0.0;
  }

  int? _mesToInt(dynamic mes) {
    final num = int.tryParse(mes.toString());
    if (num != null && num >= 1 && num <= 12) return num;

    final regex = RegExp(r'(\d{1,2})');
    final match = regex.firstMatch(mes.toString());
    if (match != null) {
      final m = int.tryParse(match.group(1)!);
      if (m != null && m >= 1 && m <= 12) return m;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: RelatoriosService.getEvolucaoMensal(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Erro: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Sem dados"));
        }

        final lista = snapshot.data!;
        final spots = <FlSpot>[];
        double maxY = 0;

        for (var e in lista) {
          if (e is Map && e.containsKey("mes") && e.containsKey("total")) {
            final mesNum = _mesToInt(e["mes"]);
            final valor = _toDouble(e["total"]);

            if (mesNum != null) {
              spots.add(FlSpot(mesNum.toDouble(), valor));
              if (valor > maxY) maxY = valor;
            }
          }
        }

        // 🔥 define o máximo ajustado para múltiplo de 10.000
        const intervalo = 10000.0;
        double maxYajustado = ((maxY / intervalo).ceil() * intervalo);

        if (maxYajustado == 0) {
          maxYajustado = intervalo; // evita gráfico vazio
        }

        return LineChart(
          LineChartData(
            minX: 1,
            maxX: 12,
            minY: 0,
            maxY: maxYajustado,

            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                barWidth: 3,
                color: Colors.blue,
                dotData: FlDotData(show: false),
              ),
            ],

            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 1, // 🔥 força exibir somente valores inteiros
                  getTitlesWidget: (value, meta) {
                    final mesIndex = value.toInt();

                    // 🔥 só mostra se for mês de 1 a 12
                    if (mesIndex < 1 || mesIndex > 12 || value % 1 != 0) {
                      return const SizedBox.shrink();
                    }

                    return Text(
                      nomesMeses[mesIndex],
                      style: const TextStyle(fontSize: 12),
                    );
                  },
                ),
              ),

              // 🔥 EIXO Y SUBINDO DE 10.000 EM 10.000
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  interval: intervalo,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 11),
                    );
                  },
                ),
              ),

              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
          ),
        );
      },
    );
  }
}

//=============== GRAFICO DE CATEGORIAS ==================//
class GraficoCategorias extends StatelessWidget {
  const GraficoCategorias({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: RelatoriosService.getCategorias(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Erro: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Sem dados"));
        }

        final lista = snapshot.data!;
        final sections = lista.asMap().entries.map<PieChartSectionData>((
          entry,
        ) {
          final e = entry.value;
          final value = _toDouble(e["valor"]);
          final title = (e["categoria"] ?? "").toString();
          final color = Colors.primaries[entry.key % Colors.primaries.length];
          return PieChartSectionData(value: value, title: title, color: color);
        }).toList();

        return PieChart(
          PieChartData(centerSpaceRadius: 55, sections: sections),
        );
      },
    );
  }
}

//=============== GRAFICO DE FORNECEDORES ==================//
class GraficoFornecedores extends StatelessWidget {
  const GraficoFornecedores({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: RelatoriosService.getFornecedores(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Erro: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Sem dados"));
        }

        final dados = snapshot.data!;
        final groups = dados.asMap().entries.map<BarChartGroupData>((entry) {
          final e = entry.value;
          final index = entry.key;
          final total = _toDouble(e["total"]);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(toY: total / 1000, width: 18, color: Colors.teal),
            ],
          );
        }).toList();

        return BarChart(BarChartData(barGroups: groups));
      },
    );
  }
}

//=============== GRAFICO DE HEATMAP ==================//
class GraficoHeatmapVencimentos extends StatelessWidget {
  const GraficoHeatmapVencimentos({super.key});

  static const colunas = [
    "Início do Mês 1-10",
    "Meio do Mês 11-20",
    "Fim do Mês 21–31",
  ];
  static const linhas = ["Vencimentos"];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: RelatoriosService.getHeatmap(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Erro: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Sem dados"));
        }

        final matriz = (snapshot.data! as List)
            .map<List<int>>(
              (linha) => List<int>.from(linha.map((v) => _toDouble(v).toInt())),
            )
            .toList();

        final rows = matriz.length;
        final cols = matriz[0].length;

        return Column(
          children: [
            // CABEÇALHO DAS COLUNAS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: colunas.map((e) {
                return SizedBox(
                  width: 70,
                  child: Center(
                    child: Text(
                      e,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 8),

            // LINHA ÚNICA COM O HEATMAP
            SizedBox(
              height: 80,
              child: Row(
                children: List.generate(cols, (c) {
                  final valor = matriz[0][c];
                  final intensidade = (valor / 10).clamp(0.0, 1.0);

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(intensidade),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          valor.toString(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // NOME DA LINHA
            const SizedBox(height: 4),
            const Text(
              "Vencimentos",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
    );
  }
}

double _toDouble(dynamic v) {
  return double.tryParse(v.toString()) ?? 0.0;
}
