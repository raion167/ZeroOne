import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;
const Color corPrincipal = Color(0xFFBBFB04);

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

  @override
  void initState() {
    super.initState();
    carregarResumo();
  }

  Future<void> carregarResumo() async {
    try {
      final response = await supabase
          .from('estoque')
          .select('nome, quantidade, preco');

      int somaItens = 0;
      double somaValor = 0;
      List<Map<String, dynamic>> dist = [];
      List<String> baixos = [];

      for (final item in response) {
        final int qtd = item['quantidade'];
        final double preco = (item['preco'] as num).toDouble();

        somaItens += qtd;
        somaValor += qtd * preco;

        dist.add({'nome': item['nome'], 'quantidade': qtd});

        if (qtd <= 5) {
          baixos.add(item['nome']);
        }
      }

      dist.sort((a, b) => b['quantidade'].compareTo(a['quantidade']));

      setState(() {
        totalItens = somaItens;
        valorTotal = somaValor;
        distribuicao = dist.take(10).toList();
        produtosBaixos = baixos;
        carregando = false;
      });
    } catch (e) {
      setState(() => carregando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao carregar dados: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
        title: const Text("Visão Geral de Estoque"),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ResumoCard(
                        titulo: "Total de Itens",
                        valor: "$totalItens",
                      ),
                      _ResumoCard(
                        titulo: "Valor Total",
                        valor: "R\$ ${valorTotal.toStringAsFixed(2)}",
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _CardProdutosBaixos(produtosBaixos: produtosBaixos),
                  const SizedBox(height: 30),
                  const Text(
                    "Distribuição dos Produtos (Top 10)",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: corPrincipal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _graficoDistribuicao(),
                ],
              ),
            ),
    );
  }

  Widget _graficoDistribuicao() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: corPrincipal.withOpacity(0.8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: corPrincipal.withOpacity(0.5),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SizedBox(
        height: 250,
        child: BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              topTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= distribuicao.length) {
                      return const SizedBox();
                    }
                    return Transform.rotate(
                      angle: -0.6,
                      child: Text(
                        distribuicao[index]['nome'],
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: distribuicao.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: (entry.value['quantidade'] as num).toDouble(),
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [corPrincipal.withOpacity(0.6), corPrincipal],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _ResumoCard extends StatelessWidget {
  final String titulo;
  final String valor;

  const _ResumoCard({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.42,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: corPrincipal.withOpacity(0.9), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: corPrincipal.withOpacity(0.5),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            titulo,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(
              color: corPrincipal,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardProdutosBaixos extends StatelessWidget {
  final List<String> produtosBaixos;

  const _CardProdutosBaixos({required this.produtosBaixos});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: corPrincipal.withOpacity(0.9), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: corPrincipal.withOpacity(0.4),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Itens em Baixa",
            style: TextStyle(
              color: corPrincipal,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          produtosBaixos.isEmpty
              ? const Text(
                  "Nenhum item em baixa",
                  style: TextStyle(color: Colors.white70),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: produtosBaixos.map((produto) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        "• $produto",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}
