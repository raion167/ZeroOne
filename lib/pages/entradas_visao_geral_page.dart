import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiBase = "http://localhost:8080/app/";

class EntradasVisaoGeralPage extends StatefulWidget {
  const EntradasVisaoGeralPage({super.key});

  @override
  State<EntradasVisaoGeralPage> createState() => _EntradasVisaoGeralPageState();
}

class _EntradasVisaoGeralPageState extends State<EntradasVisaoGeralPage> {
  bool loading = true;

  double totalMes = 0;
  double totalPendente = 0;
  List ultimasEntradas = [];

  @override
  void initState() {
    super.initState();
    carregarVisaoGeral();
  }

  Future<void> carregarVisaoGeral() async {
    final url = Uri.parse("${apiBase}visao_geral_entradas.php");
    final response = await http.get(url);

    final data = jsonDecode(response.body);

    if (data["success"]) {
      setState(() {
        totalMes = (data["total_mes"] as num).toDouble();
        totalPendente = (data["total_pendente"] as num).toDouble();
        ultimasEntradas = data["ultimas"] ?? [];
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Visão Geral de Entradas")),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Resumo",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      _ResumoCard(
                        title: "Total no Mês",
                        value: "R\$ ${totalMes.toStringAsFixed(2)}",
                        color: Colors.green,
                      ),
                      const SizedBox(width: 16),
                      _ResumoCard(
                        title: "Pendente",
                        value: "R\$ ${totalPendente.toStringAsFixed(2)}",
                        color: Colors.orange,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    "Últimas Entradas",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: ListView.builder(
                      itemCount: ultimasEntradas.length,
                      itemBuilder: (_, i) {
                        final item = ultimasEntradas[i];
                        return ListTile(
                          leading: const Icon(
                            Icons.attach_money,
                            color: Colors.green,
                          ),
                          title: Text(item["identificador"] ?? "Sem nome"),
                          subtitle: Text(
                            "R\$ ${item["valor_recebido"]} • ${item["data_recebimento"]}",
                          ),
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

class _ResumoCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _ResumoCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
