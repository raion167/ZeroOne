import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zeroone/pages/contas_listagem.dart';

const Color corPrincipal = Color(0xFFBBFB04);
const Color fundoPreto = Colors.black;
const Color cardPreto = Color.fromARGB(255, 20, 20, 20);

class ProjetosPage extends StatefulWidget {
  const ProjetosPage({super.key});

  @override
  State<ProjetosPage> createState() => _ProjetosPageState();
}

class _ProjetosPageState extends State<ProjetosPage>
    with SingleTickerProviderStateMixin {
  bool carregando = true;
  List<dynamic> projetos = [];
  List<dynamic> equipes = [];
  List<dynamic> materiais = [];
  Map<int, int> selecionados = {};
  String searchQuery = "";

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        throw Exception(data["message"]);
      }
    } catch (e) {
      setState(() => carregando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao carregar projetos: $e")));
    }
  }

  Future<void> carregarEquipes() async {
    final response = await http.get(
      Uri.parse("http://localhost:8080/app/listar_equipes.php"),
    );
    final data = jsonDecode(response.body);
    equipes = data["equipes"] ?? [];
  }

  Future<void> carregarMateriais() async {
    final response = await http.get(
      Uri.parse("http://localhost:8080/app/listar_estoque.php"),
    );
    final data = jsonDecode(response.body);
    materiais = data["itens"] ?? [];
  }

  List<dynamic> filtrarProjetos(String status) {
    final lista = projetos.where((p) {
      final st = (p["status"] ?? "").toString().toLowerCase();
      if (status == "Em Andamento") {
        return st == "em andamento" || st == "a fazer";
      }
      return st == "concluído";
    }).toList();

    if (searchQuery.isEmpty) return lista;

    return lista.where((p) {
      return (p["cliente_nome"] ?? "").toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
    }).toList();
  }

  // ================== CADASTRO DE PROJETO (INALTERADO) ==================

  void abrirCadastroProjeto() async {
    await carregarEquipes();
    await carregarMateriais();

    final tituloCtrl = TextEditingController();
    final descricaoCtrl = TextEditingController();
    final clienteNomeCtrl = TextEditingController();
    final clienteEmailCtrl = TextEditingController();
    final clienteTelefoneCtrl = TextEditingController();
    String? equipeSelecionada;

    selecionados.clear();
    int etapa = 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            backgroundColor: cardPreto,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: corPrincipal),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Text(
                        etapa == 1 ? "Cadastro de Projeto" : "Materiais",
                        style: const TextStyle(
                          color: corPrincipal,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(flex: 2),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: etapa == 1
                          ? Column(
                              children: [
                                _campo(tituloCtrl, "Título"),
                                _campo(descricaoCtrl, "Descrição"),
                                _campo(clienteNomeCtrl, "Cliente"),
                                _campo(clienteEmailCtrl, "E-mail"),
                                _campo(clienteTelefoneCtrl, "Telefone"),
                                DropdownButtonFormField<String>(
                                  dropdownColor: cardPreto,
                                  decoration: _inputDecoration("Equipe"),
                                  items: equipes.map((e) {
                                    return DropdownMenuItem(
                                      value: e["id"].toString(),
                                      child: Text(
                                        e["nome"],
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (v) => equipeSelecionada = v,
                                ),
                              ],
                            )
                          : Column(
                              children: materiais.map((m) {
                                final id = int.parse(m["id"].toString());
                                final disp = int.parse(
                                  m["quantidade"].toString(),
                                );
                                final sel = selecionados[id] ?? 0;

                                return Card(
                                  color: fundoPreto,
                                  child: ListTile(
                                    title: Text(
                                      m["nome"],
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "Disponível: $disp",
                                      style: TextStyle(color: corPrincipal),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove,
                                            color: corPrincipal,
                                          ),
                                          onPressed: sel > 0
                                              ? () => setStateDialog(() {
                                                  selecionados[id] = sel - 1;
                                                  if (selecionados[id] == 0) {
                                                    selecionados.remove(id);
                                                  }
                                                })
                                              : null,
                                        ),
                                        Text(
                                          "$sel",
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add,
                                            color: corPrincipal,
                                          ),
                                          onPressed: sel < disp
                                              ? () => setStateDialog(() {
                                                  selecionados[id] = sel + 1;
                                                })
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
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (etapa == 2)
                        TextButton(
                          onPressed: () => setStateDialog(() => etapa = 1),
                          child: const Text(
                            "Voltar",
                            style: TextStyle(color: corPrincipal),
                          ),
                        ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: corPrincipal,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () async {
                          if (etapa == 1) {
                            setStateDialog(() => etapa = 2);
                          } else {
                            await cadastrarProjetoComMateriais(
                              tituloCtrl.text,
                              descricaoCtrl.text,
                              clienteNomeCtrl.text,
                              clienteEmailCtrl.text,
                              clienteTelefoneCtrl.text,
                              int.parse(equipeSelecionada!),
                            );
                            Navigator.pop(context);
                          }
                        },
                        child: Text(etapa == 1 ? "Avançar" : "Salvar"),
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
      carregarProjetos();
    }
  }

  Future<void> adicionarMateriaisAoProjeto(int projetoId) async {
    await http.post(
      Uri.parse("http://localhost:8080/app/adicionar_materiais_projeto.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "projeto_id": projetoId,
        "materiais": selecionados.entries
            .map((e) => {"estoque_id": e.key, "quantidade": e.value})
            .toList(),
      }),
    );
  }

  // ================== UI ==================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundoPreto,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
        title: const Text("Projetos"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: corPrincipal,
          labelColor: corPrincipal,
          tabs: const [
            Tab(text: "Em Andamento"),
            Tab(text: "Concluídos"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: corPrincipal,
        foregroundColor: Colors.black,
        onPressed: abrirCadastroProjeto,
        icon: const Icon(Icons.add),
        label: const Text(
          "Novo Projeto",
          style: TextStyle(fontWeight: FontWeight.w100),
        ),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator(color: corPrincipal))
          : TabBarView(
              controller: _tabController,
              children: [_lista("Em Andamento"), _lista("Concluído")],
            ),
    );
  }

  Widget _lista(String status) {
    final lista = filtrarProjetos(status);
    if (lista.isEmpty) {
      return const Center(
        child: Text("Nenhum projeto", style: TextStyle(color: Colors.white70)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: lista.length,
      itemBuilder: (_, i) {
        final p = lista[i];
        return Card(
          color: cardPreto,
          child: ListTile(
            leading: const Icon(Icons.assignment, color: corPrincipal),
            title: Text(
              p["titulo"],
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              "Cliente: ${p["cliente_nome"]}",
              style: TextStyle(color: corPrincipal),
            ),
          ),
        );
      },
    );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: corPrincipal),
    filled: true,
    fillColor: fundoPreto,
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: corPrincipal),
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

Widget _campo(TextEditingController c, String label) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
    ),
  );
}
