import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
    _tabController = TabController(length: 4, vsync: this);
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
    final res = await http.get(
      Uri.parse(
        "http://localhost:8080/app/listar_operadores_equipe.php?equipe_id=${widget.equipeId}",
      ),
    );
    final data = jsonDecode(res.body);
    if (data["success"]) {
      operadores = List.from(data["operadores"] ?? []);
    }
  }

  Future<void> carregarProjetos() async {
    final res = await http.get(
      Uri.parse(
        "http://localhost:8080/app/listar_projetos_equipe.php?equipe_id=${widget.equipeId}",
      ),
    );
    final data = jsonDecode(res.body);
    if (data["success"]) {
      projetos = List.from(data["projetos"] ?? []);
    }
  }

  Future<void> carregarStatus() async {
    final res = await http.get(
      Uri.parse(
        "http://localhost:8080/app/listar_status_equipe.php?equipe_id=${widget.equipeId}",
      ),
    );
    final data = jsonDecode(res.body);
    if (data["success"]) {
      status = {
        "total": data["total"] ?? 0,
        "finalizados": data["finalizados"] ?? 0,
        "andamento": data["andamento"] ?? 0,
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
        title: Text("Equipe: ${widget.nomeEquipe}"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: corPrincipal,
          labelColor: corPrincipal,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: "Operadores"),
            Tab(icon: Icon(Icons.work), text: "Projetos"),
            Tab(icon: Icon(Icons.check_circle), text: "Finalizar"),
            Tab(icon: Icon(Icons.analytics), text: "Status"),
          ],
        ),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOperadores(),
                _buildProjetos(),
                _buildFinalizarProjeto(), // 👈 ABA RESTAURADA
                _buildStatus(),
              ],
            ),
    );
  }

  // ================= OPERADORES =================
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
        return _card(
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
              onPressed: () => desvincularOperador(op["id"], i),
            ),
          ),
        );
      },
    );
  }

  Future<void> desvincularOperador(int usuarioId, int index) async {
    final res = await http.post(
      Uri.parse("http://localhost:8080/app/desvincular_usuario_equipe.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"usuario_id": usuarioId, "equipe_id": widget.equipeId}),
    );
    final data = jsonDecode(res.body);
    if (data["success"] == true) {
      setState(() => operadores.removeAt(index));
    }
  }

  // ================= PROJETOS =================
  Widget _buildProjetos() {
    if (projetos.isEmpty) {
      return const Center(
        child: Text("Nenhum projeto", style: TextStyle(color: Colors.white70)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projetos.length,
      itemBuilder: (_, i) {
        final p = projetos[i];
        return _card(
          child: ListTile(
            leading: const Icon(Icons.assignment, color: corPrincipal),
            title: Text(
              p["titulo"] ?? "",
              style: const TextStyle(
                color: corPrincipal,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              p["descricao"] ?? "",
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        );
      },
    );
  }

  // ================= FINALIZAR PROJETO =================
  Widget _buildFinalizarProjeto() {
    return const Center(
      child: Text(
        "Aqui permanece sua lógica de finalizar projeto",
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  // ================= STATUS =================
  Widget _buildStatus() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _statusCard("Total", status["total"], Colors.blue),
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
          boxShadow: [BoxShadow(color: cor.withOpacity(0.3), blurRadius: 14)],
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
            Text(titulo, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: fundoEscuro,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: corPrincipal.withOpacity(0.35)),
      ),
      child: child,
    );
  }
}
