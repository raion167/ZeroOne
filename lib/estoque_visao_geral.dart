import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:zeroone/pages/menu_lateral.dart';

class EstoqueVisaoGeralPage extends StatefulWidget {
  final String nomeUsuario;
  final String emailUsuario;

  const EstoqueVisaoGeralPage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  State<EstoqueVisaoGeralPage> createState() => _EstoqueVisaoGeralPageState();
}

class _EstoqueVisaoGeralPageState extends State<EstoqueVisaoGeralPage> {
  bool carregando = true;
  int totalItens = 0;
  double valorTotal = 0.0;
  List<Map<String, dynamic>> distribuicao = [];
  List<String> produtosBaixos = [];

  Future<void> carregarResumo() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8080/app/estoque_resumo.php"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"] == true) {
          setState(() {
            totalItens = data["total_itens"];
            valorTotal = double.tryParse(data["valor_total"].toString()) ?? 0.0;
            distribuicao = List<Map<String, dynamic>>.from(
              data["distribuicao"],
            );
            produtosBaixos = List<String>.from(data["produtos_baixos"]);
            carregando = false;
          });
        } else {
          throw Exception("Erro ao carregar dados do servidor");
        }
      } else {
        throw Exception("Erro de conexão: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => carregando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao carregar dados: $e")));
    }
  }

  @override
  void initState() {
    super.initState();
    carregarResumo();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      titulo: "Visão Geral do Estoque",
      nomeUsuario: widget.nomeUsuario,
      emailUsuario: widget.emailUsuario,
      corpo: carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 🔹 Cards de resumo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ResumoCard(
                        titulo: "Total de Itens",
                        valor: "$totalItens",
                        cor: Colors.blue,
                      ),
                      _ResumoCard(
                        titulo: "Valor Total",
                        valor: "R\$ ${valorTotal.toStringAsFixed(2)}",
                        cor: Colors.green,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 🔹 Card de produtos em baixa
                  _CardProdutosBaixos(produtosBaixos: produtosBaixos),

                  const SizedBox(height: 30),

                  // 🔹 Gráfico de distribuição
                  const Text(
                    "Distribuição dos Produtos (Top 10)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(),
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= distribuicao.length) {
                                  return const SizedBox();
                                }
                                return Transform.rotate(
                                  angle: -0.6,
                                  child: Text(
                                    distribuicao[index]['nome'],
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: distribuicao.asMap().entries.map((entry) {
                          int index = entry.key;
                          final item = entry.value;
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY:
                                    double.tryParse(
                                      item['quantidade'].toString(),
                                    ) ??
                                    0,
                                color: Colors.blueAccent,
                                width: 16,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// 🔹 Card genérico para total e valor
class _ResumoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color cor;

  const _ResumoCard({
    required this.titulo,
    required this.valor,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              titulo,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔹 Novo card para produtos em baixa quantidade
class _CardProdutosBaixos extends StatelessWidget {
  final List<String> produtosBaixos;

  const _CardProdutosBaixos({required this.produtosBaixos});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Itens em Baixa",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            produtosBaixos.isEmpty
                ? const Text(
                    "Nenhum item em baixa.",
                    style: TextStyle(color: Colors.white70),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: produtosBaixos
                        .map(
                          (produto) => Text(
                            "• $produto",
                            style: const TextStyle(color: Colors.white),
                          ),
                        )
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }
}
