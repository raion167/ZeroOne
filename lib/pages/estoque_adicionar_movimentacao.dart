import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color corPrincipal = Color(0xFFBBFB04);
final supabase = Supabase.instance.client;

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
  List<Map<String, dynamic>> produtos = [];
  Map<String, dynamic>? produtoSelecionado;
  final quantidadeCtrl = TextEditingController();
  String tipo = "entrada";
  bool carregandoProdutos = true;

  @override
  void initState() {
    super.initState();
    carregarProdutos();
  }

  // ================= CARREGAR PRODUTOS =================
  Future<void> carregarProdutos() async {
    try {
      final response = await supabase
          .from('estoque')
          .select('id, nome, quantidade')
          .order('nome');

      setState(() {
        produtos = List<Map<String, dynamic>>.from(response);
        carregandoProdutos = false;
      });
    } catch (e) {
      setState(() => carregandoProdutos = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  // ================= SALVAR MOVIMENTAÇÃO =================
  Future<void> salvarMovimentacao() async {
    if (produtoSelecionado == null || quantidadeCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informe produto e quantidade")),
      );
      return;
    }

    try {
      final user = supabase.auth.currentUser;
      final quantidade = int.parse(quantidadeCtrl.text);
      final produtoId = produtoSelecionado!["id"];

      // 🔹 Busca quantidade atual no estoque
      final estoqueAtual = await supabase
          .from('estoque')
          .select('quantidade')
          .eq('id', produtoId)
          .single();

      int qtdAtual = estoqueAtual['quantidade'] ?? 0;

      // 🔹 Calcula nova quantidade
      int novaQtd;

      if (tipo == "entrada") {
        novaQtd = qtdAtual + quantidade;
      } else {
        novaQtd = qtdAtual - quantidade;

        if (novaQtd < 0) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Estoque insuficiente")));
          return;
        }
      }

      // 🔹 Atualiza estoque
      await supabase
          .from('estoque')
          .update({'quantidade': novaQtd})
          .eq('id', produtoId);

      // 🔹 Salva movimentação
      await supabase.from('movimentacoes_estoque').insert({
        "produto_id": produtoId,
        "user_id": user?.id,
        "tipo": tipo,
        "quantidade": quantidade,
        "data_movimentacao": DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Movimentação registrada!")));

      quantidadeCtrl.clear();
      produtoSelecionado = null;

      carregarProdutos(); // atualiza dropdown
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Adicionar Movimentação"),
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
      ),
      body: carregandoProdutos
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ToggleButtons(
                    isSelected: [tipo == "entrada", tipo == "saida"],
                    onPressed: (index) {
                      setState(() {
                        tipo = index == 0 ? "entrada" : "saida";
                      });
                    },
                    borderColor: corPrincipal,
                    selectedBorderColor: corPrincipal,
                    fillColor: corPrincipal,
                    selectedColor: Colors.black,
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text("Entrada"),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text("Saída"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  DropdownButtonFormField<Map<String, dynamic>>(
                    dropdownColor: Colors.black,
                    value: produtoSelecionado,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Produto",
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                    items: produtos.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(
                          "${p['nome']} (Qtd: ${p['quantidade']})",
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => produtoSelecionado = v),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: quantidadeCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Quantidade",
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),

                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: salvarMovimentacao,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: corPrincipal,
                    ),
                    child: const Text(
                      "Salvar",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
