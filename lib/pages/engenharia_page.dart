import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EngenhariaPage extends StatefulWidget {
  const EngenhariaPage({super.key});

  @override
  State<EngenhariaPage> createState() => _EngenhariaPageState();
}

class _EngenhariaPageState extends State<EngenhariaPage> {
  bool carregando = true;
  bool salvando = false;
  List<Map<String, dynamic>> projetos = [];

  @override
  void initState() {
    super.initState();
    carregarProjetos();
  }

  Future<void> carregarProjetos() async {
    setState(() => carregando = true);
    try {
      final res = await http.get(
        Uri.parse("http://localhost:8080/app/listar_projetos_engenharia.php"),
      );
      final data = jsonDecode(res.body);
      if (data["success"] == true) {
        projetos = (data["projetos"] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else {
        projetos = [];
      }
    } catch (e) {
      projetos = [];
    } finally {
      setState(() => carregando = false);
    }
  }

  List<Map<String, dynamic>> filtrar(String status) {
    return projetos.where((p) {
      final s = (p["status"] ?? "").toString().trim().toLowerCase();
      return s == status.toLowerCase();
    }).toList();
  }

  Future<void> moverProjeto(
    Map<String, dynamic> projeto,
    String novoStatus,
  ) async {
    setState(() {
      projeto["status"] = novoStatus;
    });

    setState(() => salvando = true);
    try {
      final res = await http.post(
        Uri.parse("http://localhost:8080/app/atualizar_status_projeto.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": projeto["id"], "status": novoStatus}),
      );
      final data = jsonDecode(res.body);
      if (data["success"] != true) {
        throw Exception();
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao atualizar status.")),
      );
      await carregarProjetos();
    } finally {
      setState(() => salvando = false);
    }
  }

  Widget _buildKanbanColumn(String status, Color cor) {
    final lista = filtrar(status);

    return Expanded(
      child: DragTarget<Map<String, dynamic>>(
        onWillAccept: (data) => data != null && data["status"] != status,
        onAccept: (projeto) => moverProjeto(projeto, status),
        builder: (context, candidateData, rejectedData) {
          return Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cor, width: 1.5),
            ),
            child: Column(
              children: [
                Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: cor,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final projeto in lista)
                          LongPressDraggable<Map<String, dynamic>>(
                            data: projeto,
                            feedback: Material(
                              elevation: 6,
                              child: SizedBox(
                                width: 200,
                                child: _buildCard(projeto, cor, dragging: true),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.4,
                              child: _buildCard(projeto, cor),
                            ),
                            child: _buildCard(projeto, cor),
                          ),
                        if (candidateData.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Icon(Icons.arrow_downward, color: cor),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(
    Map<String, dynamic> projeto,
    Color cor, {
    bool dragging = false,
  }) {
    return Card(
      color: dragging ? Colors.grey[200] : Colors.white,
      elevation: dragging ? 8 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(projeto["titulo"] ?? "Sem título"),
        subtitle: Text(projeto["descricao"] ?? ""),
        leading: Icon(Icons.assignment, color: cor),
        trailing: Text(
          projeto["cliente_nome"]?.toString() ?? "",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        onTap: () => _abrirDetalhesProjeto(projeto),
      ),
    );
  }

  void _abrirDetalhesProjeto(Map<String, dynamic> projeto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(projeto["titulo"] ?? "Detalhes"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Cliente: ${projeto["cliente_nome"] ?? '—'}"),
            const SizedBox(height: 8),
            Text("Descrição: ${projeto["descricao"] ?? '—'}"),
            const SizedBox(height: 8),
            Text("Status: ${projeto["status"] ?? '—'}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fechar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Engenharia - Painel Kanban"),
        backgroundColor: Colors.black87,
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                _buildKanbanColumn("A Fazer", Colors.orange),
                _buildKanbanColumn("Em Andamento", Colors.blue),
                _buildKanbanColumn("Concluído", Colors.green),
              ],
            ),
      floatingActionButton: salvando
          ? const FloatingActionButton(
              backgroundColor: Colors.grey,
              onPressed: null,
              child: CircularProgressIndicator(color: Colors.white),
            )
          : FloatingActionButton(
              backgroundColor: Colors.black,
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
    );
  }
}
