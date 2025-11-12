import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

    _tabController.addListener(() {
      if (_tabController.index == 2) {
        setState(() {}); // força atualização da aba Status
      }
    });

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
      setState(() {
        operadores = List<dynamic>.from(data["operadores"] ?? []);
      });
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
      setState(() {
        projetos = List<dynamic>.from(data["projetos"] ?? []);
      });
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
      setState(() {
        status = {
          "total": data["total"],
          "finalizados": data["finalizados"],
          "andamento": data["andamento"],
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Equipe: ${widget.nomeEquipe}"),
        bottom: TabBar(
          controller: _tabController,
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

  // Dentro do _buildOperadores()
  Widget _buildOperadores() {
    // Se não houver operadores vinculados, mostra mensagem
    if (operadores.isEmpty) {
      return const Center(
        child: Text("Nenhum operador vinculado a esta equipe."),
      );
    }

    // Lista de operadores vinculados à equipe
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: operadores.length,
      itemBuilder: (context, index) {
        final op = operadores[index];
        return Card(
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text(op["nome"] ?? "Sem nome"),
            subtitle: Text(op["email"] ?? ""),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: "Desvincular operador",
              onPressed: () async {
                // Função para desvincular operador da equipe
                final success = await desvincularOperador(op["id"]);
                if (success) {
                  setState(() {
                    operadores.removeAt(index);
                  });
                }
              },
            ),
          ),
        );
      },
    );
  }

  // Função para desvincular operador da equipe
  Future<bool> desvincularOperador(int usuarioId) async {
    try {
      final res = await http.post(
        Uri.parse("http://localhost:8080/app/desvincular_usuario_equipe.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "usuario_id": usuarioId,
          "equipe_id": widget.equipeId,
        }),
      );
      final data = jsonDecode(res.body);
      if (data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Operador desvinculado com sucesso!")),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Erro ao desvincular")),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: $e")));
      return false;
    }
  }

  Widget _buildProjetos() {
    if (projetos.isEmpty) {
      return const Center(
        child: Text("Nenhum projeto cadastrado para esta equipe."),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: projetos.length,
      itemBuilder: (context, index) {
        final p = projetos[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.assignment),
            title: Text(p["titulo"] ?? "Projeto sem título"),
            subtitle: Text(p["descricao"] ?? ""),
          ),
        );
      },
    );
  }

  Widget _buildStatus() {
    if (status.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    //final dados = status[];

    final totalOS = status["total"] ?? 0;
    final osFinalizadas = status["finalizados"] ?? 0;
    final osAndamento = status["andamento"] ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                child: _buildStatusCard(
                  titulo: "Total de OS",
                  valor: totalOS.toString(),
                  cor: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: _buildStatusCard(
                  titulo: "Finalizadas",
                  valor: osFinalizadas.toString(),
                  cor: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: _buildStatusCard(
                  titulo: "Em andamento",
                  valor: osAndamento.toString(),
                  cor: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required String titulo,
    required String valor,
    required Color cor,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          children: [
            Text(
              valor,
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
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
