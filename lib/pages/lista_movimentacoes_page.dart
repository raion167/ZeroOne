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
  List<dynamic> entradas = [];
  List<dynamic> saidas = [];

  // 🔹 Filtros
  DateTimeRange? filtroData;
  String? filtroUsuario;
  List<String> listaUsuarios = [];

  Future<void> carregarMovimentacoes() async {
    setState(() => carregando = true);
    try {
      // Monta query string com filtros
      String query = "?filtro=1";
      if (filtroUsuario != null && filtroUsuario!.isNotEmpty) {
        query += "&usuario=${Uri.encodeComponent(filtroUsuario!)}";
      }
      if (filtroData != null) {
        query +=
            "&data_inicio=${filtroData!.start.toIso8601String()}&data_fim=${filtroData!.end.toIso8601String()}";
      }

      final response = await http.get(
        Uri.parse("http://localhost:8080/app/listar_movimentacoes.php$query"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"] == true) {
          setState(() {
            entradas = List<dynamic>.from(data["entradas"] ?? []);
            saidas = List<dynamic>.from(data["saidas"] ?? []);
            listaUsuarios = List<String>.from(data["usuarios"] ?? []);
            carregando = false;
          });
        } else {
          throw Exception("Erro no servidor: ${data['message']}");
        }
      } else {
        throw Exception("Erro de conexão: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => carregando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao carregar: $e")));
    }
  }

  Future<void> selecionarPeriodo() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: filtroData,
    );
    if (picked != null) {
      setState(() => filtroData = picked);
      carregarMovimentacoes();
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
          : Column(
              children: [
                // 🔹 Filtros
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // Filtro de usuário
                      Expanded(
                        child: DropdownButton<String>(
                          value: filtroUsuario,
                          hint: const Text("Filtrar por usuário"),
                          isExpanded: true,
                          items: listaUsuarios
                              .map(
                                (u) =>
                                    DropdownMenuItem(value: u, child: Text(u)),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              filtroUsuario = value;
                              carregarMovimentacoes();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Filtro de data
                      ElevatedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          filtroData == null
                              ? "Filtrar por data"
                              : "${filtroData!.start.day}/${filtroData!.start.month}/${filtroData!.start.year} - "
                                    "${filtroData!.end.day}/${filtroData!.end.month}/${filtroData!.end.year}",
                        ),
                        onPressed: selecionarPeriodo,
                      ),
                      if (filtroData != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              filtroData = null;
                              carregarMovimentacoes();
                            });
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 🔹 Lista dividida
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _MovimentacaoLista(
                          titulo: "Entradas",
                          cor: Colors.green.shade700,
                          movimentacoes: entradas,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MovimentacaoLista(
                          titulo: "Saídas",
                          cor: Colors.red.shade700,
                          movimentacoes: saidas,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _MovimentacaoLista extends StatelessWidget {
  final String titulo;
  final Color cor;
  final List<dynamic> movimentacoes;

  const _MovimentacaoLista({
    required this.titulo,
    required this.cor,
    required this.movimentacoes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
            const Divider(),
            Expanded(
              child: movimentacoes.isEmpty
                  ? Center(
                      child: Text(
                        "Nenhuma movimentação registrada.",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: movimentacoes.length,
                      itemBuilder: (context, index) {
                        final item = movimentacoes[index];
                        return ListTile(
                          leading: Icon(Icons.inventory_2, color: cor),
                          title: Text(item["produto"] ?? "-"),
                          subtitle: Text(
                            "Qtd: ${item["quantidade"] ?? "-"}\n"
                            "Usuário: ${item["usuario"] ?? "-"}\n"
                            "Data: ${item["data"] ?? "-"}",
                          ),
                          isThreeLine: true,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
