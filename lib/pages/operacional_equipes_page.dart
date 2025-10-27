import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zeroone/pages/detalhes_projeto_page.dart';

class OperacionalEquipesPage extends StatefulWidget {
  final String nomeUsuario;
  final String emailUsuario;

  const OperacionalEquipesPage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  State<OperacionalEquipesPage> createState() => _OperacionalEquipesPageState();
}

class _OperacionalEquipesPageState extends State<OperacionalEquipesPage> {
  bool carregando = true;
  List<Map<String, dynamic>> equipes = [];

  @override
  void initState() {
    super.initState();
    carregarEquipes();
  }

  Future<void> carregarEquipes() async {
    setState(() => carregando = true);
    try {
      final res = await http.get(
        Uri.parse("http://localhost:8080/app/listar_equipes.php"),
      );
      final data = jsonDecode(res.body);
      setState(() {
        equipes =
            (data["equipes"] as List?)
                ?.map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [];
        carregando = false;
      });
    } catch (e) {
      setState(() => carregando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao carregar equipes: $e")));
    }
  }

  void abrirCadastroEquipe() {
    final TextEditingController nomeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cadastrar Nova Equipe"),
        content: TextField(
          controller: nomeCtrl,
          decoration: const InputDecoration(
            labelText: "Nome da equipe",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomeCtrl.text.isEmpty) return;
              await cadastrarEquipe(nomeCtrl.text);
              Navigator.pop(context);
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  Future<void> cadastrarEquipe(String nome) async {
    try {
      final res = await http.post(
        Uri.parse("http://localhost:8080/app/cadastrar_equipes.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"nome": nome}),
      );
      final data = jsonDecode(res.body);
      if (data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Equipe cadastrada com sucesso!")),
        );
        carregarEquipes();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  void abrirVincularOperador(int equipeId, String equipeNome) async {
    List<Map<String, dynamic>> usuarios = [];
    String? usuarioSelecionado;

    try {
      final res = await http.get(
        Uri.parse("http://localhost:8080/app/listar_usuarios_operacional.php"),
      );
      final data = jsonDecode(res.body);
      usuarios =
          (data["usuarios"] as List?)
              ?.map((u) => Map<String, dynamic>.from(u))
              .toList() ??
          [];
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao carregar usuários: $e")));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Vincular Operador à equipe '$equipeNome'"),
        content: DropdownButtonFormField<String>(
          hint: const Text("Selecione o operador"),
          items: usuarios
              .map(
                (u) => DropdownMenuItem(
                  value: u["id"].toString(),
                  child: Text(u["nome"]),
                ),
              )
              .toList(),
          onChanged: (v) => usuarioSelecionado = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (usuarioSelecionado == null) return;
              await vincularUsuario(int.parse(usuarioSelecionado!), equipeId);
              Navigator.pop(context);
            },
            child: const Text("Vincular"),
          ),
        ],
      ),
    );
  }

  Future<void> vincularUsuario(int usuarioId, int equipeId) async {
    try {
      final res = await http.post(
        Uri.parse("http://localhost:8080/app/vincular_usuario_equipe.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"usuario_id": usuarioId, "equipe_id": equipeId}),
      );
      final data = jsonDecode(res.body);
      if (data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Operador vinculado com sucesso!")),
        );
        carregarEquipes();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  void abrirDetalhesEquipe(Map<String, dynamic> equipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalhesEquipePage(
          equipeId: int.parse(equipe["id"].toString()),
          nomeEquipe: equipe["nome"],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestão de Equipes Operacionais")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: abrirCadastroEquipe,
        label: const Text("Nova Equipe"),
        icon: const Icon(Icons.add),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: equipes.length,
                itemBuilder: (context, i) {
                  final e = equipes[i];
                  return Card(
                    elevation: 3,
                    child: ListTile(
                      title: Text(e["nome"]),
                      subtitle: Text(
                        "Usuários: ${(e["usuarios"] ?? []).map((u) => u["nome"]).join(', ')}",
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.link),
                        tooltip: "Vincular operador",
                        onPressed: () => abrirVincularOperador(
                          int.parse(e["id"].toString()),
                          e["nome"],
                        ),
                      ),
                      onTap: () => abrirDetalhesEquipe(e),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// -----------------------------------------------------------
// 🔹 SUBTELA DE DETALHES DA EQUIPE COM ABAS REAIS
// -----------------------------------------------------------

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
  List<dynamic> status = [];

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
    try {
      final response = await http.get(
        Uri.parse(
          "http://localhost:8080/app/listar_operadores_equipe.php?equipe_id=${widget.equipeId}",
        ),
      );
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        setState(() {
          operadores = List<dynamic>.from(data["operadores"] ?? []);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao carregar operadores: $e")),
      );
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
      status = List<dynamic>.from(data["status"] ?? []);
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

  // ABA DE OPERADORES CADASTRADOS
  Widget _buildOperadores() {
    if (operadores.isEmpty) {
      return const Center(
        child: Text("Nenhum operador vinculado a esta equipe."),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: operadores.length,
      itemBuilder: (context, index) {
        final op = operadores[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text(op["nome"] ?? "Sem nome"),
            subtitle: Text(op["email"] ?? ""),
          ),
        );
      },
    );
  }

  // ABA DE PROJETOS
  Widget _buildProjetos() {
    if (projetos.isEmpty) {
      return const Center(
        child: Text("Nenhum projeto cadastrado para essa equipe"),
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetalhesProjetoPage(
                    projetoId: int.parse(p["id"].toString()),
                    tituloProjeto: p["titulo"],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ABA DE STATUS DA EQUIPE
  Widget _buildStatus() {
    if (status.isEmpty) {
      return const Center(child: Text("Nenhum status registrado."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: status.length,
      itemBuilder: (context, index) {
        final s = status[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: Text(s["titulo"] ?? "Sem título"),
            subtitle: Text(s["descricao"] ?? ""),
            trailing: Text(s["data"] ?? ""),
          ),
        );
      },
    );
  }
}
