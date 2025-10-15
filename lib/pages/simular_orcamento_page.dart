import 'package:flutter/material.dart';
import 'dart:math';

class SimularOrcamentoPage extends StatefulWidget {
  const SimularOrcamentoPage({super.key});

  @override
  State<SimularOrcamentoPage> createState() => _SimularOrcamentoPageState();
}

class _SimularOrcamentoPageState extends State<SimularOrcamentoPage> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController consumoController = TextEditingController();
  final TextEditingController paineisController = TextEditingController();
  final TextEditingController potenciaController = TextEditingController();
  final TextEditingController precoController = TextEditingController();

  double? valorFinal;
  bool calculando = false;

  void calcularOrcamento() {
    final consumo =
        double.tryParse(consumoController.text.replaceAll(',', '.')) ?? 0;
    final qtdPaineis = int.tryParse(paineisController.text) ?? 0;
    final potenciaTotal =
        double.tryParse(potenciaController.text.replaceAll(',', '.')) ?? 0;
    final precoPorKwp =
        double.tryParse(precoController.text.replaceAll(',', '.')) ?? 0;

    if (consumo <= 0 ||
        qtdPaineis <= 0 ||
        potenciaTotal <= 0 ||
        precoPorKwp <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos corretamente.")),
      );
      return;
    }

    setState(() {
      calculando = true;
    });

    // Cálculo do preço total estimado
    // Exemplo: potencia_total * preco_kwp
    double precoTotal = potenciaTotal * precoPorKwp;

    // (Opcional) simula economia mensal
    double economiaMensal = consumo * 0.85; // 85% do consumo economizado

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        valorFinal = precoTotal;
        calculando = false;
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Simulação de Orçamento"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Cliente: ${nomeController.text}"),
              const SizedBox(height: 8),
              Text("Consumo mensal: ${consumo.toStringAsFixed(2)} kWh"),
              Text("Quantidade de painéis: $qtdPaineis"),
              Text("Potência total: ${potenciaTotal.toStringAsFixed(2)} kWp"),
              const Divider(),
              Text(
                "💰 Preço total estimado: R\$ ${precoTotal.toStringAsFixed(2)}",
              ),
              const SizedBox(height: 8),
              Text(
                "🌞 Economia mensal estimada: R\$ ${economiaMensal.toStringAsFixed(2)}",
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Fechar"),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Simular Orçamento"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _campoTexto("Nome do Cliente", nomeController),
            _campoTexto(
              "Consumo Mensal (kWh)",
              consumoController,
              tipo: TextInputType.number,
            ),
            _campoTexto(
              "Quantidade de Painéis",
              paineisController,
              tipo: TextInputType.number,
            ),
            _campoTexto(
              "Potência Total (kWp)",
              potenciaController,
              tipo: TextInputType.number,
            ),
            _campoTexto(
              "Preço por kWp (R\$)",
              precoController,
              tipo: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: calculando ? null : calcularOrcamento,
              icon: const Icon(Icons.calculate),
              label: Text(calculando ? "Calculando..." : "Simular Orçamento"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            if (valorFinal != null) ...[
              const SizedBox(height: 30),
              Card(
                color: Colors.black87,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        "Resultado da Simulação",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Valor estimado: R\$ ${valorFinal!.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _campoTexto(
    String label,
    TextEditingController controller, {
    TextInputType tipo = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: tipo,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
