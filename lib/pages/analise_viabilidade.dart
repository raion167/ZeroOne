// lib/pages/analise_viabilidade_page.dart
import 'dart:math';
import 'package:flutter/material.dart';

class AnaliseViabilidadePage extends StatefulWidget {
  const AnaliseViabilidadePage({super.key});

  @override
  State<AnaliseViabilidadePage> createState() => _AnaliseViabilidadePageState();
}

class _AnaliseViabilidadePageState extends State<AnaliseViabilidadePage> {
  final investimentoCtrl = TextEditingController();
  final receitaAnualCtrl = TextEditingController();
  final custosAnualCtrl = TextEditingController();
  String resultado = '';

  void _calcular() {
    final inv = double.tryParse(investimentoCtrl.text) ?? 0.0;
    final receita = double.tryParse(receitaAnualCtrl.text) ?? 0.0;
    final custos = double.tryParse(custosAnualCtrl.text) ?? 0.0;
    final lucro = receita - custos;
    final payback = lucro > 0 ? (inv / lucro) : double.infinity;

    // VPL simplificado com taxa 8% a.a.
    final taxa = 0.08;
    final anos = 10;
    double vpl = -inv;
    for (int t = 1; t <= anos; t++) {
      vpl += lucro / pow((1 + taxa), t);
    }

    setState(() {
      resultado =
          'Payback: ${payback.isFinite ? "${payback.toStringAsFixed(2)} anos" : "Não recupera"}\nVPL (10 anos, 8%): R\$ ${vpl.toStringAsFixed(2)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Análise de Viabilidade')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: investimentoCtrl,
              decoration: const InputDecoration(
                labelText: 'Investimento inicial (R\$)',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: receitaAnualCtrl,
              decoration: const InputDecoration(
                labelText: 'Receita anual (R\$)',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: custosAnualCtrl,
              decoration: const InputDecoration(
                labelText: 'Custos anuais (R\$)',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _calcular,
              child: const Text('Calcular Viabilidade'),
            ),
            const SizedBox(height: 16),
            if (resultado.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(resultado, style: const TextStyle(fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
