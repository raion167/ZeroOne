import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DemonstracoesFinanceirasPage extends StatefulWidget {
  const DemonstracoesFinanceirasPage({super.key});

  @override
  State<DemonstracoesFinanceirasPage> createState() =>
      _DemonstracoesFinanceirasPageState();
}

class _DemonstracoesFinanceirasPageState
    extends State<DemonstracoesFinanceirasPage> {
  bool loading = true;
  List<Map<String, dynamic>> demonstrativos = [];

  @override
  void initState() {
    super.initState();
    _loadDemo();
  }

  Future<void> _loadDemo() async {
    setState(() => loading = true);
    try {
      // Ex: fetch demonstrativos do servidor
      // final res = await http.get(Uri.parse('http://localhost:8080/app/demonstrativos.php'));
      // demonstrativos = List<Map<String,dynamic>>.from(jsonDecode(res.body)['items']);

      // Mock
      demonstrativos = [
        {"ano": 2024, "receita": 120000.0, "despesas": 80000.0},
        {"ano": 2025, "receita": 150000.0, "despesas": 90000.0},
      ];
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  void _exportCSV() {
    // Implementar geração CSV/Export real
    final csv = StringBuffer();
    csv.writeln('ano,receita,despesas,resultado');
    for (final d in demonstrativos) {
      final res = (d['receita'] as double) - (d['despesas'] as double);
      csv.writeln('${d['ano']},${d['receita']},${d['despesas']},$res');
    }
    // Você pode salvar em arquivo local / compartilhar
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('CSV gerado (placeholder).')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demonstrações Financeiras')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: demonstrativos.length,
                      itemBuilder: (ctx, i) {
                        final d = demonstrativos[i];
                        final resultado =
                            (d['receita'] as double) -
                            (d['despesas'] as double);
                        return Card(
                          child: ListTile(
                            title: Text('Ano ${d['ano']}'),
                            subtitle: Text(
                              'Receita: R\$ ${d['receita'].toStringAsFixed(2)} • Despesas: R\$ ${d['despesas'].toStringAsFixed(2)}',
                            ),
                            trailing: Text(
                              'Resultado: R\$ ${resultado.toStringAsFixed(2)}',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _exportCSV,
                    icon: const Icon(Icons.file_download),
                    label: const Text('Exportar CSV'),
                  ),
                ],
              ),
            ),
    );
  }
}
