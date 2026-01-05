import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

class DistribuicaoCategoriaPage extends StatefulWidget {
  const DistribuicaoCategoriaPage({super.key});

  @override
  State<DistribuicaoCategoriaPage> createState() =>
      _DistribuicaoCategoriaPageState();
}

class _DistribuicaoCategoriaPageState extends State<DistribuicaoCategoriaPage> {
  bool loading = true;
  List dados = [];

  final List<Color> cores = [
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.cyan,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    final url = Uri.parse(
      "http://localhost:8080/app/distribuicao_categoria.php",
    );
    final response = await http.get(url);

    final json = jsonDecode(response.body);
    setState(() {
      dados = json["data"] ?? [];
      loading = false;
    });
  }

  double get valorTotal {
    double total = 0;
    for (var item in dados) {
      total += double.tryParse(item["total"].toString()) ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Distribuição por Categoria")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : dados.isEmpty
          ? const Center(child: Text("Nenhum dado encontrado"))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // 🔥 Gráfico
                  SizedBox(
                    height: 300,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        startDegreeOffset: -90,
                        // 🔥 Animação suave
                        pieTouchData: PieTouchData(enabled: true),
                        sections: gerarFatias(),
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 800),
                      swapAnimationCurve: Curves.easeOutCubic,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔥 Legenda lateral
                  Expanded(child: buildLegenda()),
                ],
              ),
            ),
    );
  }

  /// 🔹 Gera as fatias do gráfico com porcentagem + cores + títulos
  List<PieChartSectionData> gerarFatias() {
    return List.generate(dados.length, (i) {
      final item = dados[i];
      final total = valorTotal;

      final valor = double.tryParse(item["total"].toString()) ?? 0;
      final percentual = total == 0 ? 0 : (valor / total) * 100;

      return PieChartSectionData(
        value: valor,
        radius: 65,
        color: cores[i % cores.length],
        title: "${percentual.toStringAsFixed(1)}%",
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  /// 🔹 Legenda com cor + categoria + valor total
  Widget buildLegenda() {
    return ListView.builder(
      itemCount: dados.length,
      itemBuilder: (_, i) {
        final item = dados[i];
        final valor = double.tryParse(item["total"].toString()) ?? 0;

        return Row(
          children: [
            // bolinha de cor
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: cores[i % cores.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),

            // Categoria
            Expanded(
              child: Text(
                item["categoria"],
                style: const TextStyle(fontSize: 16),
              ),
            ),

            // Valor
            Text(
              "R\$ ${valor.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
    );
  }
}
