import 'dart:convert';
import 'package:flutter/material.dart';
import 'operacional_equipes_page.dart';
import 'package:http/http.dart' as http;

class DetalhesProjetoPage extends StatefulWidget {
  final int projetoId;
  final String tituloProjeto;

  const DetalhesProjetoPage({
    super.key,
    required this.projetoId,
    required this.tituloProjeto,
  });

  @override
  State<DetalhesProjetoPage> createState() => _DetalhesProjetoPageState();
}

class _DetalhesProjetoPageState extends State<DetalhesProjetoPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool carregando = true;
  List<dynamic> materiais = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    carregarMateriais();
  }

  Future<void> carregarMateriais() async {
    try {
      final res = await http.get(
        Uri.parse(
          "http://localhost:8080/app/listar_materiais_projeto.php?projeto_id=${widget.projetoId}",
        ),
      );
      final data = jsonDecode(res.body);
      if (data["success"]) {
        setState(() {
          materiais = data["materiais"];
          carregando = false;
        });
      } else {
        setState(() => carregando = false);
      }
    } catch (e) {
      setState(() => carregando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao carregar materiais: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Projeto: ${widget.tituloProjeto}"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.checklist), text: "Checklist de Materiais"),
            Tab(icon: Icon(Icons.done_all), text: "Finalizar Projeto"),
          ],
        ),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildChecklist(), _buildFinalizar()],
            ),
    );
  }

  Widget _buildChecklist() {
    if (materiais.isEmpty) {
      return const Center(
        child: Text("Nenhum material vinculado a este projeto"),
      );
    }
    return ListView.builder(
      itemCount: materiais.length,
      itemBuilder: (context, i) {
        final m = materiais[i];
        return CheckboxListTile(
          title: Text(m["nome"] ?? "Material"),
          subtitle: Text("Quantidade: ${m["quantidade"] ?? 0}"),
          value: m["checado"] == true,
          onChanged: (v) {
            setState(() => m["checado"] = v);
          },
        );
      },
    );
  }

  Widget _buildFinalizar() {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.check),
        label: const Text("Finalizar Projeto"),
        onPressed: () async {
          final confirmar = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Finalizar Projeto"),
              content: const Text("Deseja realmente finalizar este projeto?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Confirmar"),
                ),
              ],
            ),
          );

          if (confirmar == true) {
            await finalizarProjeto();
          }
        },
      ),
    );
  }

  Future<void> finalizarProjeto() async {
    try {
      final res = await http.post(
        Uri.parse("http://localhost:8080/app/finalizar_projeto.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"projeto_id": widget.projetoId}),
      );
      final data = jsonDecode(res.body);

      if (data["success"]) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Projeto finalizado com sucesso!")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro: ${data["message"]}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }
}
