import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'menu_lateral.dart';

class EstoqueMovimentacoesListPage extends StatefulWidget {
  final String nomeUsuario;
  final String emailUsuario;

  const EstoqueMovimentacoesListPage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  State<EstoqueMovimentacoesListPage> createState() =>
      _EstoqueMovimentacoesListPageState();
}

class _EstoqueMovimentacoesListPageState
    extends State<EstoqueMovimentacoesListPage> {
  bool carregando = true;
  List<Map<String, dynamic>> movimentacoes = [];

  Future<void> carregarMovimentacoes() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8080/app/listar_movimentacoes.php"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            movimentacoes = List<Map<String, dynamic>>.from(
              data["movimentacoes"],
            );
            carregando = false;
          });
        } else {
          throw Exception("Erro ao carregar movimentações");
        }
      } else {
        throw Exception("Erro de conexão: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => carregando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao carregar dados: $e")));
    }
  }

  @override
  void initState() {
    super.initState();
    carregarMovimentacoes();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      titulo: "Movimentações de Estoque",
      nomeUsuario: widget.nomeUsuario,
      emailUsuario: widget.emailUsuario,
      corpo: carregando
          ? const Center(child: CircularProgressIndicator())
          : movimentacoes.isEmpty
          ? const Center(child: Text("Nenhuma movimentação encontrada."))
          : ListView.builder(
              itemCount: movimentacoes.length,
              itemBuilder: (context, index) {
                final item = movimentacoes[index];
                final tipo = item['tipo'] == 'entrada' ? "Entrada" : "Saída";
                final cor = item['tipo'] == 'entrada'
                    ? Colors.green
                    : Colors.red;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.grey[900],
                  child: ListTile(
                    leading: Icon(
                      tipo == "Entrada"
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: cor,
                    ),
                    title: Text(
                      item['produto'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Quantidade: ${item['quantidade']} • $tipo\nData/Hora: ${item['data_hora']}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
