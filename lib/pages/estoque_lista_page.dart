import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'menu_lateral.dart';

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
  List produtos = [];
  bool carregando = true;

  // 🔹 Função para buscar os produtos do backend PHP
  Future<void> carregarProdutos() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8080/app/listar_estoque.php"),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        setState(() {
          produtos = data["itens"];
          carregando = false;
        });
      } else {
        setState(() {
          carregando = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Nenhum produto encontrado.")));
      }
    } catch (e) {
      setState(() => carregando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao carregar produtos: $e")));
    }
  }

  Future<void> deletarProduto(String id) async {
    try {
      final response = await http.post(
        Uri.parse("http://localhost:8080/app/deletar_estoque.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": id}),
      );

      final data = jsonDecode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "Erro ao deletar.")),
      );

      if (data["success"] == true) carregarProdutos();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao excluir produto: $e")));
    }
  }

  @override
  void initState() {
    super.initState();
    carregarProdutos();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      titulo: "Itens em Estoque",
      nomeUsuario: widget.nomeUsuario,
      emailUsuario: widget.emailUsuario,
      corpo: carregando
          ? const Center(child: CircularProgressIndicator())
          : produtos.isEmpty
          ? const Center(child: Text("Nenhum produto encontrado."))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: produtos.length,
              itemBuilder: (context, index) {
                final item = produtos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: const Icon(Icons.inventory, color: Colors.black),
                    ),
                    title: Text(
                      item["nome"],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      "Quantidade: ${item["quantidade"]} | Preço: R\$ ${item["preco"]}",
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (valor) {
                        if (valor == "editar") {
                          // 🔹 Aqui você pode abrir a tela de edição futuramente
                        } else if (valor == "excluir") {
                          deletarProduto(item["id"]);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: "editar",
                          child: Text("Editar"),
                        ),
                        const PopupMenuItem(
                          value: "excluir",
                          child: Text("Excluir"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
