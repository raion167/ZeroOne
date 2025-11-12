import 'package:flutter/material.dart';

class ContasRelatoriosPage extends StatelessWidget {
  const ContasRelatoriosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Relatórios Financeiros")),
      body: const Center(
        child: Text("Relatórios PDF, CSV, filtros e exportação."),
      ),
    );
  }
}
