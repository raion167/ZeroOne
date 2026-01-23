import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'finalizar_projeto_page.dart';

const Color corPrincipal = Color(0xFFBBFB04);
const Color fundoEscuro = Color(0xFF0D0D0D);

class DetalhesEquipePage extends StatefulWidget {
  final int equipeId;
  final String nomeEquipe;

  const DetalhesEquipePage({
    super.key,
    required this.equipeId,
    required this.nomeEquipe,
  });

  @override
  State<DetalhesEquipePage> createState() => _DetalhesEquipePageState();
}

class _DetalhesEquipePageState extends State<DetalhesEquipePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool carregando = true;

  List<dynamic> operadores = [];
  List<dynamic> projetos = [];
  Map<String, dynamic> status = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    carregarDados();
  }

  Future<void> carregarDados() async {
    setState(() => carregando = true);
    await Future.wait([
      carregarOperadores(),
      carregarProjetos(),
      carregarStatus(),
    ]);
    setState(() => carregando = false);
  }

  Future<void> carregarOperadores() async {
    final response = await http.get(
      Uri.parse(
        "http://localhost:8080/app/listar_operadores_equipe.php?equipe_id=${widget.equipeId}",
      ),
    );
    final data = jsonDecode(response.body);
    if (data["success"]) {
      operadores = List<dynamic>.from(data["operadores"] ?? []);
    }
  }

  Future<void> carregarProjetos() async {
    final response = await http.get(
      Uri.parse(
        "http://localhost:8080/app/listar_projetos_equipe.php?equipe_id=${widget.equipeId}",
      ),
    );
    final data = jsonDecode(response.body);
    if (data["success"]) {
      projetos = List<dynamic>.from(data["projetos"] ?? []);
    }
  }

  Future<void> carregarStatus() async {
    final response = await http.get(
      Uri.parse(
        "http://localhost:8080/app/listar_status_equipe.php?equipe_id=${widget.equipeId}",
      ),
    );
    final data = jsonDecode(response.body);
    if (data["success"]) {
      status = {
        "total": data["total"],
        "finalizados": data["finalizados"],
        "andamento": data["andamento"],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: corPrincipal,
          labelColor: corPrincipal,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: "Operadores"),
            Tab(icon: Icon(Icons.work), text: "Projetos"),
            Tab(icon: Icon(Icons.analytics), text: "Status"),
          ],
        ),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildOperadores(), _buildProjetos(), _buildStatus()],
            ),
    );
  }

  // ================= ABA OPERADORES =================
  Widget _buildOperadores() {
    if (operadores.isEmpty) {
      return const Center(
        child: Text(
          "Nenhum operador vinculado",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: operadores.length,
      itemBuilder: (_, i) {
        final op = operadores[i];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: fundoEscuro,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: corPrincipal.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(color: corPrincipal.withOpacity(0.25), blurRadius: 12),
            ],
          ),
          child: ListTile(
            leading: const Icon(Icons.person, color: corPrincipal),
            title: Text(
              op["nome"] ?? "",
              style: const TextStyle(
                color: corPrincipal,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              op["email"] ?? "",
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: Colors.redAccent,
              ),
              onPressed: () async {
                final ok = await desvincularOperador(op["id"]);
                if (ok) {
                  setState(() => operadores.removeAt(i));
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<bool> desvincularOperador(int usuarioId) async {
    final res = await http.post(
      Uri.parse("http://localhost:8080/app/desvincular_usuario_equipe.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"usuario_id": usuarioId, "equipe_id": widget.equipeId}),
    );
    final data = jsonDecode(res.body);
    return data["success"] == true;
  }

  // ================= ABA PROJETOS =================
  Widget _buildProjetos() {
    if (projetos.isEmpty) {
      return const Center(
        child: Text(
          "Nenhum projeto cadastrado",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projetos.length,
      itemBuilder: (context, index) {
        final p = projetos[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: fundoEscuro,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: corPrincipal.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(color: corPrincipal.withOpacity(0.25), blurRadius: 12),
            ],
          ),
          child: ListTile(
            leading: const Icon(Icons.assignment, color: corPrincipal),
            title: Text(
              p["titulo"] ?? "Projeto sem título",
              style: const TextStyle(
                color: corPrincipal,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              p["descricao"] ?? "",
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: corPrincipal,
            ),
            onTap: () async {
              final bool? finalizado = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FinalizarProjetoPage(
                    projetoId: int.parse(p["id"].toString()),
                  ),
                ),
              );
              if (finalizado == true) {
                await carregarProjetos();
                await carregarStatus();
                setState(() {});
              }
            },
          ),
        );
      },
    );
  }

  // ================= ABA STATUS =================
  Widget _buildStatus() {
    if (status.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _statusCard("Total OS", status["total"], Colors.blue),
          const SizedBox(width: 12),
          _statusCard("Finalizadas", status["finalizados"], Colors.green),
          const SizedBox(width: 12),
          _statusCard("Em andamento", status["andamento"], Colors.orange),
        ],
      ),
    );
  }

  Widget _statusCard(String titulo, int valor, Color cor) {
    return Expanded(
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: fundoEscuro,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cor.withOpacity(0.5)),
          boxShadow: [BoxShadow(color: cor.withOpacity(0.35), blurRadius: 14)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              valor.toString(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
