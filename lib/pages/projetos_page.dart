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
  List<dynamic> materiais = [];
  Map<int, int> selecionados = {}; // {id_material: quantidade}

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

  Future<void> carregarMateriais() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8080/app/listar_estoque.php"),
      );

      if (response.statusCode != 200) {
        throw Exception("Erro HTTP ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      if (data["success"] == true && data["itens"] != null) {
        setState(() {
          materiais = List<Map<String, dynamic>>.from(data["itens"]);
        });
      } else {
        throw Exception(data["message"] ?? "Resposta inválida do servidor");
      }
    } catch (e) {
      setState(() {
        materiais = [];
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao carregar materiais: $e")));
    }
  }

  void abrirCadastroProjeto() async {
    await carregarEquipes();
    await carregarMateriais();

    final TextEditingController tituloCtrl = TextEditingController();
    final TextEditingController descricaoCtrl = TextEditingController();
    final TextEditingController clienteNomeCtrl = TextEditingController();
    final TextEditingController clienteEmailCtrl = TextEditingController();
    final TextEditingController clienteTelefoneCtrl = TextEditingController();
    String? equipeSelecionada;

    selecionados.clear();
    int etapa = 1; // controla o avanço entre formulário e materiais

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    etapa == 1 ? "Cadastro de Projeto" : "Seleção de Materiais",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: etapa == 1
                          ? Column(
                              children: [
                                TextField(
                                  controller: tituloCtrl,
                                  decoration: const InputDecoration(
                                    labelText: "Título do Projeto",
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: descricaoCtrl,
                                  decoration: const InputDecoration(
                                    labelText: "Descrição",
                                  ),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: clienteNomeCtrl,
                                  decoration: const InputDecoration(
                                    labelText: "Nome do Cliente",
                                  ),
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
                                  items: equipes.map<DropdownMenuItem<String>>((
                                    e,
                                  ) {
                                    return DropdownMenuItem(
                                      value: e["id"].toString(),
                                      child: Text(e["nome"]),
                                    );
                                  }).toList(),
                                  onChanged: (v) => equipeSelecionada = v,
                                ),
                              ],
                            )
                          : Column(
                              children: materiais.map((mat) {
                                final id =
                                    int.tryParse(mat["id"].toString()) ?? 0;
                                final qtdDisponivel =
                                    int.tryParse(
                                      mat["quantidade"].toString(),
                                    ) ??
                                    0;
                                final qtdSelecionada = selecionados[id] ?? 0;

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: ListTile(
                                    title: Text(mat["nome"]),
                                    subtitle: Text(
                                      "Disponível: $qtdDisponivel",
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                          onPressed: qtdSelecionada > 0
                                              ? () {
                                                  setStateDialog(() {
                                                    selecionados[id] =
                                                        qtdSelecionada - 1;
                                                    if (selecionados[id] == 0) {
                                                      selecionados.remove(id);
                                                    }
                                                  });
                                                }
                                              : null,
                                        ),
                                        Text(qtdSelecionada.toString()),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                          ),
                                          onPressed:
                                              qtdSelecionada < qtdDisponivel
                                              ? () {
                                                  setStateDialog(() {
                                                    selecionados[id] =
                                                        qtdSelecionada + 1;
                                                  });
                                                }
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (etapa == 2)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.arrow_back),
                          label: const Text("Voltar"),
                          onPressed: () => setStateDialog(() {
                            etapa = 1;
                          }),
                        ),
                      if (etapa == 1)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text("Avançar"),
                          onPressed: () {
                            if (tituloCtrl.text.isEmpty ||
                                clienteNomeCtrl.text.isEmpty ||
                                equipeSelecionada == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Preencha todos os campos obrigatórios!",
                                  ),
                                ),
                              );
                              return;
                            }
                            setStateDialog(() {
                              etapa = 2;
                            });
                          },
                        ),
                      if (etapa == 2)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text("Salvar Projeto"),
                          onPressed: () async {
                            await cadastrarProjetoComMateriais(
                              tituloCtrl.text,
                              descricaoCtrl.text,
                              clienteNomeCtrl.text,
                              clienteEmailCtrl.text,
                              clienteTelefoneCtrl.text,
                              int.parse(equipeSelecionada!),
                            );
                            Navigator.pop(context);
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> cadastrarProjetoComMateriais(
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
        final projetoId = data["projeto_id"];

        if (selecionados.isNotEmpty) {
          await adicionarMateriaisAoProjeto(projetoId);
        }

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

  Future<void> adicionarMateriaisAoProjeto(int projetoId) async {
    final url = Uri.parse(
      "http://localhost:8080/app/adicionar_materiais_projeto.php",
    );

    final body = {
      "projeto_id": projetoId,
      "materiais": selecionados.entries.map((e) {
        return {"estoque_id": e.key, "quantidade": e.value};
      }).toList(),
    };

    await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
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
