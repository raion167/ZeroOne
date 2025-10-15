import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ListaVendasPage extends StatefulWidget {
  const ListaVendasPage({super.key});

  @override
  State<ListaVendasPage> createState() => _ListaVendasPageState();
}

class _ListaVendasPageState extends State<ListaVendasPage> {
  List vendas = [];
  bool carregando = true;

  Future<void> carregarVendas() async {
    final response = await http.get(
      Uri.parse("http://localhost:8080/app/listar_vendas.php"),
    );
    final data = json.decode(response.body);
    setState(() {
      vendas = data;
      carregando = false;
    });
  }

  @override
  void initState() {
    super.initState();
    carregarVendas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lista de Vendas")),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: vendas.length,
              itemBuilder: (context, index) {
                final venda = vendas[index];
                return ListTile(
                  leading: const Icon(Icons.shopping_cart),
                  title: Text("Cliente: ${venda['cliente_nome']}"),
                  subtitle: Text("Valor: R\$ ${venda['valor_total']}"),
                  trailing: Text(venda['status']),
                );
              },
            ),
    );
  }
}
