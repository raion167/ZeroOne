import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'menu_lateral.dart';

class EstoqueAdicionarMovimentacaoPage extends StatefulWidget {
  final String nomeUsuario;
  final String emailUsuario;

  const EstoqueAdicionarMovimentacaoPage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  State<EstoqueAdicionarMovimentacaoPage> createState() =>
      _EstoqueAdicionarMovimentacaoPageState();
}

class _EstoqueAdicionarMovimentacaoPageState
    extends State<EstoqueAdicionarMovimentacaoPage> {
  List<dynamic> produtos = [];
  Map<String, dynamic>? produtoSelecionado;
  final TextEditingController quantidadeCtrl = TextEditingController();
  String tipo = "entrada";
  bool carregandoProdutos = true;

  @override
  void initState() {
    super.initState();
    carregarProdutos();
  }

  Future<void> carregarProdutos() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8080/app/listar_estoque.php"),
      );
      final data = jsonDecode(response.body);

      if (data["success"]) {
        setState(() {
          produtos = data["produtos"] ?? data["itens"] ?? [];
          carregandoProdutos = false;
        });
      } else {
        throw Exception("Erro ao carregar produtos");
      }
    } catch (e) {
      setState(() => carregandoProdutos = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao carregar produtos: $e")));
    }
  }

  Future<void> salvarMovimentacao() async {
    if (produtoSelecionado == null || quantidadeCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selecione o produto e informe a quantidade"),
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("http://localhost:8080/app/adicionar_movimentacao.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "produto": produtoSelecionado!["nome"],
          "quantidade": quantidadeCtrl.text,
          "tipo": tipo,
          "usuario": widget.nomeUsuario, // 🔹 envia o usuário logado
        }),
      );

      final data = jsonDecode(response.body);
      if (data["success"]) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Movimentação registrada com sucesso!")),
        );
        setState(() {
          produtoSelecionado = null;
          quantidadeCtrl.clear();
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro: ${data["message"]}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao enviar dados: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      titulo: "Adicionar Movimentação",
      nomeUsuario: widget.nomeUsuario,
      emailUsuario: widget.emailUsuario,
      corpo: carregandoProdutos
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 🔹 Botões de seleção de tipo
                  ToggleButtons(
                    isSelected: [tipo == "entrada", tipo == "saida"],
                    onPressed: (index) {
                      setState(() {
                        tipo = index == 0 ? "entrada" : "saida";
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    selectedColor: Colors.white,
                    fillColor: tipo == "entrada"
                        ? Colors.green
                        : Colors.redAccent,
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text("Entrada"),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text("Saída"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 🔹 Menu suspenso de produtos
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: produtoSelecionado,
                    decoration: const InputDecoration(
                      labelText: "Produto",
                      border: OutlineInputBorder(),
                    ),
                    items: produtos.map<DropdownMenuItem<Map<String, dynamic>>>(
                      (item) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: item,
                          child: Text(
                            "${item["nome"]} (Qtd: ${item["quantidade"]})",
                          ),
                        );
                      },
                    ).toList(),
                    onChanged: (value) {
                      setState(() {
                        produtoSelecionado = value;
                        // 🔹 Quando o produto é selecionado, mostra a quantidade atual
                        quantidadeCtrl.text =
                            value?["quantidade"]?.toString() ?? "";
                      });
                    },
                  ),

                  const SizedBox(height: 15),

                  // 🔹 Campo de quantidade
                  TextField(
                    controller: quantidadeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: tipo == "entrada"
                          ? "Quantidade adicionada"
                          : "Quantidade retirada",
                      border: const OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 🔹 Botão de salvar
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tipo == "entrada"
                          ? Colors.green
                          : Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 14,
                      ),
                    ),
                    onPressed: salvarMovimentacao,
                    label: const Text("Registrar Movimentação"),
                  ),
                ],
              ),
            ),
    );
  }
}
