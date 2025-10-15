import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NovaVendaPage extends StatefulWidget {
  const NovaVendaPage({super.key});

  @override
  State<NovaVendaPage> createState() => _NovaVendaPageState();
}

class _NovaVendaPageState extends State<NovaVendaPage> {
  final TextEditingController clienteController = TextEditingController();
  final TextEditingController produtoController = TextEditingController();
  final TextEditingController quantidadeController = TextEditingController();
  final TextEditingController precoController = TextEditingController();

  bool carregando = false;

  Future<void> salvarVenda() async {
    if (clienteController.text.isEmpty || produtoController.text.isEmpty)
      return;

    setState(() => carregando = true);

    final response = await http.post(
      Uri.parse("http://localhost:8080/app/salvar_venda.php"),
      body: {
        "cliente": clienteController.text,
        "produto": produtoController.text,
        "quantidade": quantidadeController.text,
        "preco": precoController.text,
      },
    );

    setState(() => carregando = false);

    final data = json.decode(response.body);
    if (data["success"]) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Venda registrada com sucesso!")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: ${data['message']}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nova Venda")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: clienteController,
              decoration: const InputDecoration(labelText: "Cliente"),
            ),
            TextField(
              controller: produtoController,
              decoration: const InputDecoration(labelText: "Produto"),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quantidadeController,
                    decoration: const InputDecoration(labelText: "Qtd"),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: precoController,
                    decoration: const InputDecoration(labelText: "Preço"),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: carregando ? null : salvarVenda,
              icon: const Icon(Icons.save),
              label: const Text("Salvar Venda"),
            ),
          ],
        ),
      ),
    );
  }
}
