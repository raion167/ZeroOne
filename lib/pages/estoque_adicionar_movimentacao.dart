import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'menu_lateral.dart';

/// 🔹 COR PRINCIPAL (MESMA DAS OUTRAS TELAS)
const Color corPrincipal = Color(0xFFBBFB04);

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

      if (data["success"] == true) {
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
          "usuario": widget.nomeUsuario,
        }),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Adicionar Movimentação"),
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: carregandoProdutos
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: _neonBox(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// 🔹 TIPO (ENTRADA / SAÍDA)
                    ToggleButtons(
                      isSelected: [tipo == "entrada", tipo == "saida"],
                      onPressed: (index) {
                        setState(() {
                          tipo = index == 0 ? "entrada" : "saida";
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      borderColor: corPrincipal,
                      selectedBorderColor: tipo == "entrada"
                          ? corPrincipal
                          : Colors.redAccent,
                      color: Colors.white70,
                      selectedColor: Colors.black,
                      fillColor: tipo == "entrada"
                          ? corPrincipal
                          : Colors.redAccent,
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text("Entrada"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text("Saída"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    /// 🔹 PRODUTO
                    DropdownButtonFormField<Map<String, dynamic>>(
                      dropdownColor: Colors.black,
                      value: produtoSelecionado,
                      style: const TextStyle(color: Colors.white),
                      iconEnabledColor: corPrincipal,
                      decoration: _inputNeon(label: "Produto"),
                      items: produtos.map((item) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: item,
                          child: Text(
                            "${item["nome"]} (Qtd: ${item["quantidade"]})",
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          produtoSelecionado = value;
                          quantidadeCtrl.text =
                              value?["quantidade"]?.toString() ?? "";
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    /// 🔹 QUANTIDADE
                    TextField(
                      controller: quantidadeCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputNeon(
                        label: tipo == "entrada"
                            ? "Quantidade adicionada"
                            : "Quantidade retirada",
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// 🔹 BOTÃO SALVAR
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        side: BorderSide(
                          color: tipo == "entrada"
                              ? corPrincipal
                              : Colors.redAccent,
                        ),
                        shadowColor: tipo == "entrada"
                            ? corPrincipal
                            : Colors.redAccent,
                        elevation: 10,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 24,
                        ),
                      ),
                      onPressed: salvarMovimentacao,
                      label: Text(
                        "Registrar Movimentação",
                        style: TextStyle(
                          color: tipo == "entrada"
                              ? corPrincipal
                              : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// 🔹 DECORAÇÕES NEON (REUTILIZÁVEIS)
BoxDecoration _neonBox() => BoxDecoration(
  color: Colors.black,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: corPrincipal),
  boxShadow: [
    BoxShadow(
      color: corPrincipal.withOpacity(0.4),
      blurRadius: 18,
      spreadRadius: 2,
    ),
  ],
);

InputDecoration _inputNeon({required String label}) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(color: Colors.white70),
  filled: true,
  fillColor: Colors.black,
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: corPrincipal),
    borderRadius: BorderRadius.circular(12),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: corPrincipal, width: 2),
    borderRadius: BorderRadius.circular(12),
  ),
);
