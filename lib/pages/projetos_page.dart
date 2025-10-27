import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProjetosPage extends StatefulWidget {
  const ProjetosPage({super.key});

  @override
  State<ProjetosPage> createState() => _ProjetosPageState();
}

class _ProjetosPageState extends State<ProjetosPage> {
  bool carregando = true;
  List<dynamic> projetos = [];
  List<dynamic> equipes = [];

  @override
  void initState() {
    super.initState();
    carregarProjetos();
  }

  Future<void> carregarProjetos() async {
    setState(() => carregando = true);
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8080/app/listar_projetos.php"),
      );
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        setState(() {
          projetos = data["projetos"];
          carregando = false;
        });
      } else {
        throw Exception(data["message"] ?? "Erro desconhecido");
      }
    } catch (e) {
      setState(() => carregando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao carregar projetos: $e")));
    }
  }

  Future<void> carregarEquipes() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8080/app/listar_equipes.php"),
      );
      final data = jsonDecode(response.body);
      if (data["equipes"] != null) {
        equipes = data["equipes"];
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao carregar equipes: $e")));
    }
  }

  void abrirCadastroProjeto() async {
    await carregarEquipes();
    final TextEditingController tituloCtrl = TextEditingController();
    final TextEditingController descricaoCtrl = TextEditingController();
    final TextEditingController clienteNomeCtrl = TextEditingController();
    final TextEditingController clienteEmailCtrl = TextEditingController();
    final TextEditingController clienteTelefoneCtrl = TextEditingController();

    String? equipeSelecionada;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Novo Projeto"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloCtrl,
                decoration: const InputDecoration(
                  labelText: "Titulo do Projeto",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descricaoCtrl,
                decoration: const InputDecoration(labelText: "Descrição"),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: clienteNomeCtrl,
                decoration: const InputDecoration(labelText: "Nome do Cliente"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: clienteEmailCtrl,
                decoration: const InputDecoration(
                  labelText: "E-mail do Cliente",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: clienteTelefoneCtrl,
                decoration: const InputDecoration(
                  labelText: "Telefone do Cliente",
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                hint: const Text("Selecione a Equipe"),
                items: equipes.map<DropdownMenuItem<String>>((e) {
                  return DropdownMenuItem(
                    value: e["id"].toString(),
                    child: Text(e["nome"]),
                  );
                }).toList(),
                onChanged: (v) => equipeSelecionada = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (tituloCtrl.text.isEmpty ||
                  clienteNomeCtrl.text.isEmpty ||
                  equipeSelecionada == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Preencha todos os campos obrigatórios!"),
                  ),
                );
                return;
              }

              await cadastrarProjeto(
                tituloCtrl.text,
                descricaoCtrl.text,
                clienteNomeCtrl.text,
                clienteEmailCtrl.text,
                clienteTelefoneCtrl.text,
                int.parse(equipeSelecionada!),
              );
              Navigator.pop(context);
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  Future<void> cadastrarProjeto(
    String titulo,
    String descricao,
    String clienteNome,
    String clienteEmail,
    String clienteTelefone,
    int equipeId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("http://localhost:8080/app/cadastrar_projeto.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "titulo": titulo,
          "descricao": descricao,
          "cliente_nome": clienteNome,
          "cliente_email": clienteEmail,
          "cliente_telefone": clienteTelefone,
          "equipe_id": equipeId,
        }),
      );

      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Projeto cadastrado com sucesso!")),
        );
        carregarProjetos();
      } else {
        throw Exception(data["message"] ?? "Erro desconhecido");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao cadastrar projeto: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Projetos de Energia Solar"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: abrirCadastroProjeto,
        label: const Text("Novo Projeto"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.black,
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : projetos.isEmpty
          ? const Center(child: Text("Nenhum projeto cadastrado."))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: projetos.length,
              itemBuilder: (context, index) {
                final p = projetos[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.assignment, color: Colors.orange),
                    title: Text(p["titulo"]),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Cliente: ${p["cliente_nome"] ?? "—"}"),
                        Text("Equipe: ${p["equipe_nome"] ?? "Sem equipe"}"),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
