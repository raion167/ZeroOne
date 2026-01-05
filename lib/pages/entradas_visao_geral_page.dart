import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiBase = "http://localhost:8080/app/";
const Color corPrincipal = Color(0xFFBBFB04);
const Color corPendente = Colors.redAccent;
const Color corTotal = Colors.blueAccent;

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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Visão Geral de Entradas"),
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: corPrincipal))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Resumo",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: corPrincipal,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      _ResumoCard(
                        title: "Total no Mês",
                        value: "R\$ ${totalMes.toStringAsFixed(2)}",
                        icon: Icons.trending_up,
                        color: corTotal,
                      ),
                      const SizedBox(width: 16),
                      _ResumoCard(
                        title: "Pendente",
                        value: "R\$ ${totalPendente.toStringAsFixed(2)}",
                        icon: Icons.schedule,
                        color: corPendente,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "Últimas Entradas",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: corPrincipal,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: ListView.builder(
                      itemCount: ultimasEntradas.length,
                      itemBuilder: (_, i) {
                        final item = ultimasEntradas[i];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: corPrincipal, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: corPrincipal.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.attach_money,
                              color: corPrincipal,
                            ),
                            title: Text(
                              item["identificador"] ?? "Sem nome",
                              style: const TextStyle(
                                color: corPrincipal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              "R\$ ${item["valor_recebido"]} • ${item["data_recebimento"]}",
                              style: TextStyle(
                                color: corPrincipal.withOpacity(0.8),
                              ),
                            ),
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
  final IconData icon;
  final Color color;

  const _ResumoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.6),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: color.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
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
    );
  }
}
