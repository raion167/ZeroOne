import 'package:flutter/material.dart';

class ContasAnalisesPage extends StatelessWidget {
  const ContasAnalisesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Análises Financeiras")),
      body: const Center(
        child: Text("Análises gráficas, projeções, previsões e insights."),
      ),
    );
  }
}
