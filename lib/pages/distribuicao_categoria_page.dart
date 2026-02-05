import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeroone/pages/contas_visao_geral.dart';

final supabase = Supabase.instance.client;

class DistribuicaoCategoriaPage extends StatefulWidget {
  const DistribuicaoCategoriaPage({super.key});

  @override
  State<DistribuicaoCategoriaPage> createState() =>
      _DistribuicaoCategoriaPageState();
}

class _DistribuicaoCategoriaPageState extends State<DistribuicaoCategoriaPage> {
  bool loading = true;
  List<Map<String, dynamic>> dados = [];

  String get userId => supabase.auth.currentUser!.id;

  final List<Color> cores = [
    Colors.cyanAccent,
    Colors.blueAccent,
    Colors.tealAccent,
    Colors.greenAccent,
    Colors.lightBlueAccent,
    Colors.purpleAccent,
  ];

  @override
  void initState() {
    super.initState();
    carregar();
  }

  // ================== SUPABASE ==================
  Future<void> carregar() async {
    setState(() => loading = true);

    final res = await supabase
        .from('entradas')
        .select('categoria, valor_recebido')
        .eq('user_id', userId);

    final Map<String, double> mapa = {};

    for (final e in res) {
      final categoria = (e['categoria'] ?? 'Outros').toString();
      final valor = double.tryParse(e['valor_recebido'].toString()) ?? 0;

      mapa[categoria] = (mapa[categoria] ?? 0) + valor;
    }

    setState(() {
      dados = mapa.entries
          .map((e) => {'categoria': e.key, 'total': e.value})
          .toList();
      loading = false;
    });
  }

  // ================== TOTAL ==================
  double get valorTotal {
    double total = 0;
    for (var item in dados) {
      total += (item["total"] as num).toDouble();
    }
    return total;
  }

  // ================== VISUAL (INALTERADO) ==================
  BoxDecoration neonBox() {
    return BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: corPrincipal.withOpacity(0.6), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: corPrincipal.withOpacity(0.35),
          blurRadius: 20,
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
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
        title: const Text("Distribuição por Categoria"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : dados.isEmpty
          ? const Center(child: Text("Nenhum dado encontrado"))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // CARD DO GRAFICO
                  Container(
                    height: 500,
                    padding: const EdgeInsets.all(16),
                    decoration: neonBox(),
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 55,
                        startDegreeOffset: -90,
                        pieTouchData: PieTouchData(enabled: true),
                        sections: gerarFatias(),
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 900),
                      swapAnimationCurve: Curves.easeInOutCubic,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // LEGENDA
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: neonBox(),
                      child: buildLegenda(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ================== FATIAS ==================
  List<PieChartSectionData> gerarFatias() {
    return List.generate(dados.length, (i) {
      final item = dados[i];
      final total = valorTotal;
      final valor = (item["total"] as num).toDouble();
      final percentual = total == 0 ? 0 : (valor / total) * 100;

      return PieChartSectionData(
        value: valor,
        radius: 70,
        color: cores[i % cores.length],
        title: "${percentual.toStringAsFixed(1)}%",
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          shadows: [Shadow(color: Colors.white, blurRadius: 6)],
        ),
      );
    });
  }

  // ================== LEGENDA ==================
  Widget buildLegenda() {
    return ListView.separated(
      itemCount: dados.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white10),
      itemBuilder: (_, i) {
        final item = dados[i];
        final valor = (item["total"] as num).toDouble();

        return Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: cores[i % cores.length],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cores[i % cores.length].withOpacity(0.7),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Text(
                item["categoria"],
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),

            Text(
              "R\$ ${valor.toStringAsFixed(2)}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }
}
