import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color corPrincipal = Color(0xFFBBFB04);

class CrescimentoAnualPage extends StatefulWidget {
  const CrescimentoAnualPage({super.key});

  @override
  State<CrescimentoAnualPage> createState() => _CrescimentoAnualPageState();
}

class _CrescimentoAnualPageState extends State<CrescimentoAnualPage> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  List<Map<String, dynamic>> dados = [];

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    final userId = supabase.auth.currentUser!.id;

    final response = await supabase
        .from('entradas')
        .select('data_competencia, valor_recebido')
        .eq('user_id', userId);

    final Map<int, double> acumulado = {};

    for (var item in response) {
      final data = DateTime.parse(item['data_competencia']);
      final mes = data.month;

      acumulado[mes] =
          (acumulado[mes] ?? 0) + (item['valor_recebido'] as num).toDouble();
    }

    dados = acumulado.entries
        .map((e) => {'mes': e.key, 'total': e.value})
        .toList();

    dados.sort((a, b) => a['mes'].compareTo(b['mes']));

    setState(() => loading = false);
  }

  BoxDecoration neonBox() {
    return BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: corPrincipal.withOpacity(0.6), width: 1.3),
      boxShadow: [
        BoxShadow(
          color: corPrincipal.withOpacity(0.35),
          blurRadius: 22,
          spreadRadius: 2,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(
        title: const Text("Crescimento Anual"),
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "Evolução Mensal",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: corPrincipal,
                      shadows: [
                        Shadow(
                          color: corPrincipal.withOpacity(0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: neonBox(),
                      child: LineChart(
                        LineChartData(
                          minX: 1,
                          maxX: 12,
                          minY: 0,
                          maxY: _getMaxY(),
                          gridData: FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: _titles(),
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              color: corPrincipal,
                              barWidth: 3,
                              spots: _buildSpots(),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    corPrincipal.withOpacity(0.35),
                                    corPrincipal.withOpacity(0.02),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              dotData: FlDotData(show: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  FlTitlesData _titles() {
    const meses = [
      "",
      "Jan",
      "Fev",
      "Mar",
      "Abr",
      "Mai",
      "Jun",
      "Jul",
      "Ago",
      "Set",
      "Out",
      "Nov",
      "Dez",
    ];

    return FlTitlesData(
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTitlesWidget: (value, meta) {
            if (value < 1 || value > 12) return const SizedBox();
            return Text(
              meses[value.toInt()],
              style: const TextStyle(color: Colors.white70),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 60,
          getTitlesWidget: (value, meta) => Text(
            "R\$ ${value.toInt()}",
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _buildSpots() {
    return dados
        .map(
          (e) => FlSpot((e['mes'] as int).toDouble(), (e['total'] as double)),
        )
        .toList();
  }

  double _getMaxY() {
    double max = 0;
    for (var d in dados) {
      if (d['total'] > max) max = d['total'];
    }
    return ((max / 10000).ceil() * 10000).toDouble().clamp(
      10000,
      double.infinity,
    );
  }
}
