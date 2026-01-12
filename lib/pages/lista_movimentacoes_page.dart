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

  DateTimeRange? filtroData;
  String? filtroUsuario;
  List<String> listaUsuarios = [];

  Future<void> carregarMovimentacoes() async {
    setState(() => carregando = true);
    try {
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

      final data = jsonDecode(response.body);

      setState(() {
        entradas = List<dynamic>.from(data["entradas"] ?? []);
        saidas = List<dynamic>.from(data["saidas"] ?? []);
        listaUsuarios = List<String>.from(data["usuarios"] ?? []);
        carregando = false;
      });
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
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: corPrincipal,
              surface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Movimentações"),
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔹 FILTROS
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: _neonBox(),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          dropdownColor: Colors.black,
                          value: filtroUsuario,
                          hint: const Text(
                            "Filtrar por usuário",
                            style: TextStyle(color: Colors.white70),
                          ),
                          iconEnabledColor: corPrincipal,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputNeon(),
                          items: listaUsuarios
                              .map(
                                (u) =>
                                    DropdownMenuItem(value: u, child: Text(u)),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() => filtroUsuario = v);
                            carregarMovimentacoes();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          side: BorderSide(color: corPrincipal),
                        ),
                        icon: Icon(Icons.date_range, color: corPrincipal),
                        label: Text(
                          filtroData == null
                              ? "Data"
                              : "${filtroData!.start.day}/${filtroData!.start.month} - ${filtroData!.end.day}/${filtroData!.end.month}",
                          style: const TextStyle(color: Colors.white),
                        ),
                        onPressed: selecionarPeriodo,
                      ),
                      if (filtroData != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: () {
                            setState(() => filtroData = null);
                            carregarMovimentacoes();
                          },
                        ),
                    ],
                  ),
                ),

                // 🔹 LISTAS
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _MovimentacaoLista(
                          titulo: "Entradas",
                          cor: Colors.greenAccent,
                          movimentacoes: entradas,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MovimentacaoLista(
                          titulo: "Saídas",
                          cor: Colors.redAccent,
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

// 🔹 CARD DE MOVIMENTAÇÃO
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
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withOpacity(0.9)),
        boxShadow: [
          BoxShadow(
            color: cor.withOpacity(0.5),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              titulo,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
          ),
          const Divider(color: Colors.white12),
          Expanded(
            child: movimentacoes.isEmpty
                ? const Center(
                    child: Text(
                      "Nenhuma movimentação",
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    itemCount: movimentacoes.length,
                    itemBuilder: (_, i) {
                      final item = movimentacoes[i];
                      return ListTile(
                        leading: Icon(Icons.inventory_2, color: cor),
                        title: Text(
                          item["produto"] ?? "-",
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          "Qtd: ${item["quantidade"]}\nUsuário: ${item["usuario"]}\nData: ${item["data"]}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// 🔹 DECORAÇÕES
BoxDecoration _neonBox() => BoxDecoration(
  color: Colors.black,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: corPrincipal),
  boxShadow: [BoxShadow(color: corPrincipal.withOpacity(0.4), blurRadius: 16)],
);

InputDecoration _inputNeon() => InputDecoration(
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
