import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'menu_lateral.dart';

class OperacionalPage extends StatefulWidget {
  final String nomeUsuario;
  final String emailUsuario;

  const OperacionalPage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  State<OperacionalPage> createState() => _OperacionalPageState();
}

class _OperacionalPageState extends State<OperacionalPage> {
  bool carregando = true;
  List<Map<String, dynamic>> equipes = [];
  List<dynamic> usuarios = [];
  final TextEditingController nomeEquipeCtrl = TextEditingController();
  String? usuarioSelecionado;
  int? equipeSelecionada;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  /// Carrega equipes e usuários do backend
  Future<void> carregarDados() async {
    setState(() => carregando = true);
    try {
      final responseEquipes = await http.get(
        Uri.parse("http://localhost:8080/app/listar_equipes.php"),
      );
      final responseUsuarios = await http.get(
        Uri.parse("http://localhost:8080/app/listar_usuarios_operacional.php"),
      );

      final dataEquipes = jsonDecode(responseEquipes.body);
      final dataUsuarios = jsonDecode(responseUsuarios.body);

      setState(() {
        equipes = dataEquipes["equipes"] ?? [];
        usuarios = dataUsuarios["usuarios"] ?? [];
        carregando = false;
      });
    } catch (e) {
      setState(() => carregando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao carregar dados: $e")));
    }
  }

  /// Cadastrar nova equipe
  Future<void> cadastrarEquipe() async {
    if (nomeEquipeCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Informe o nome da equipe")));
      return;
    }
    try {
      final response = await http.post(
        Uri.parse("http://localhost:8080/app/cadastrar_equipe.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"nome": nomeEquipeCtrl.text}),
      );

      final data = jsonDecode(response.body);
      if (data["success"]) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Equipe cadastrada com sucesso")),
        );
        nomeEquipeCtrl.clear();
        carregarDados();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data["message"] ?? "Erro")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  /// Vincular usuário à equipe
  Future<void> vincularUsuario() async {
    if (usuarioSelecionado == null || equipeSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione usuário e equipe")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("http://localhost:8080/app/vincular_usuario_equipe.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "usuario_id": usuarioSelecionado,
          "equipe_id": equipeSelecionada,
        }),
      );

      final data = jsonDecode(response.body);
      if (data["success"]) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuário vinculado com sucesso")),
        );
        setState(() {
          usuarioSelecionado = null;
          equipeSelecionada = null;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data["message"] ?? "Erro")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      titulo: "Operacional",
      nomeUsuario: widget.nomeUsuario,
      emailUsuario: widget.emailUsuario,
      corpo: carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ==== CADASTRO DE EQUIPES ====
                  const Text(
                    "Cadastrar nova equipe",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nomeEquipeCtrl,
                          decoration: const InputDecoration(
                            labelText: "Nome da equipe",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: cadastrarEquipe,
                        child: const Text("Cadastrar"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  /// ==== VINCULAR USUÁRIO À EQUIPE ====
                  const Text(
                    "Vincular usuário a equipe",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: usuarioSelecionado,
                          hint: const Text("Selecionar usuário"),
                          items: usuarios
                              .map(
                                (u) => DropdownMenuItem(
                                  value: u["id"].toString(),
                                  child: Text(u["nome"]),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => usuarioSelecionado = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: equipeSelecionada,
                          hint: const Text("Selecionar equipe"),
                          items: (equipes ?? [])
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e["id"] as int,
                                  child: Text(e["nome"]),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => equipeSelecionada = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: vincularUsuario,
                        child: const Text("Vincular"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  /// ==== LISTA DE EQUIPES ====
                  const Text(
                    "Equipes existentes",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...equipes.map(
                    (e) => Card(
                      child: ListTile(
                        title: Text(e["nome"]),
                        subtitle: Text(
                          "Usuários: ${(e["usuarios"] ?? []).map((u) => u["nome"]).join(", ")}",
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
