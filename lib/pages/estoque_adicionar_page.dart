import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'menu_lateral.dart';

class EstoqueAdicionarPage extends StatefulWidget {
  final String nomeUsuario;
  final String emailUsuario;

  const EstoqueAdicionarPage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  State<EstoqueAdicionarPage> createState() => _EstoqueAdicionarPageState();
}

class _EstoqueAdicionarPageState extends State<EstoqueAdicionarPage> {
  final TextEditingController nomeCtrl = TextEditingController();
  final TextEditingController qtdCtrl = TextEditingController();
  final TextEditingController precoCtrl = TextEditingController();

  bool carregando = false;

  Future<void> adicionarProduto() async {
    final nome = nomeCtrl.text.trim();
    final qtdText = qtdCtrl.text.trim();
    final precoText = precoCtrl.text.trim();

    if (nome.isEmpty || qtdText.isEmpty || precoText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos.")),
      );
      return;
    }

    int quantidade;
    double preco;
    try {
      quantidade = int.parse(qtdText);
      preco = double.parse(precoText.replaceAll(',', '.')); // aceita vírgula
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quantidade ou preço inválido.")),
      );
      return;
    }

    setState(() => carregando = true);

    try {
      final response = await http.post(
        Uri.parse("http://localhost:8080/app/adicionar_estoque.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nome": nome,
          "quantidade": quantidade,
          "preco": preco,
        }),
      );

      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "Resposta sem mensagem.")),
      );

      if (data["success"] == true) {
        nomeCtrl.clear();
        qtdCtrl.clear();
        precoCtrl.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao adicionar produto: $e")));
    } finally {
      setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      titulo: "Adicionar Item",
      nomeUsuario: widget.nomeUsuario,
      emailUsuario: widget.emailUsuario,
      corpo: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nomeCtrl,
              decoration: const InputDecoration(labelText: "Nome do Produto"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: qtdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantidade"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: precoCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: "Preço Unitário (R\$)",
              ),
            ),
            const SizedBox(height: 20),
            carregando
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: adicionarProduto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text(
                      "Salvar",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
