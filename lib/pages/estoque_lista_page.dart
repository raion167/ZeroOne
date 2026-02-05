import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'menu_lateral.dart';

final supabase = Supabase.instance.client;

class EstoqueListaPage extends StatefulWidget {
  final String nomeUsuario;
  final String emailUsuario;

  const EstoqueListaPage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  State<EstoqueListaPage> createState() => _EstoqueListaPageState();
}

class _EstoqueListaPageState extends State<EstoqueListaPage> {
  List<Map<String, dynamic>> produtos = [];
  bool carregando = true;

  // 🔹 BUSCAR PRODUTOS NO SUPABASE
  Future<void> carregarProdutos() async {
    setState(() => carregando = true);

    try {
      final res = await supabase.from('estoque').select().order('nome');

      setState(() {
        produtos = List<Map<String, dynamic>>.from(res);
        carregando = false;
      });
    } catch (e) {
      setState(() => carregando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao carregar estoque: $e")));
    }
  }

  // 🔹 DELETAR PRODUTO
  Future<void> deletarProduto(String id) async {
    try {
      await supabase.from('estoque').delete().eq('id', id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Produto removido com sucesso")),
      );

      carregarProdutos();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao deletar produto: $e")));
    }
  }

  @override
  void initState() {
    super.initState();
    carregarProdutos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
        title: const Text("Itens em Estoque"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : produtos.isEmpty
          ? const Center(
              child: Text(
                "Nenhum produto encontrado.",
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: produtos.length,
              itemBuilder: (context, index) {
                final item = produtos[index];

                return Card(
                  color: Colors.black,
                  shadowColor: corPrincipal.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: corPrincipal.withOpacity(0.9),
                      width: 1.4,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: corPrincipal,
                      child: const Icon(Icons.inventory, color: Colors.black),
                    ),

                    title: Text(
                      item["nome"],
                      style: const TextStyle(
                        color: corPrincipal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: Text(
                      "Quantidade: ${item["quantidade"]} | "
                      "Preço: R\$ ${item["preco"]}",
                      style: const TextStyle(color: Colors.white),
                    ),

                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => deletarProduto(item["id"]),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
