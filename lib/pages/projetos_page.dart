import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color corPrincipal = Color(0xFFBBFB04);
const Color fundoPreto = Colors.black;
const Color cardPreto = Color.fromARGB(255, 20, 20, 20);

final supabase = Supabase.instance.client;

class ProjetosPage extends StatefulWidget {
  const ProjetosPage({super.key});

  @override
  State<ProjetosPage> createState() => _ProjetosPageState();
}

class _ProjetosPageState extends State<ProjetosPage>
    with SingleTickerProviderStateMixin {
  bool carregando = true;

  List projetos = [];
  List equipes = [];
  List materiais = [];
  List clientes = [];

  Map<String, int> selecionados = {};
  String searchQuery = "";

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    carregarProjetos();
  }

  // ================= CARREGAMENTOS =================

  Future<void> carregarProjetos() async {
    setState(() => carregando = true);

    try {
      projetos = await supabase
          .from('projetos')
          .select('*, clientes(nome)')
          .order('id', ascending: false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }

    setState(() => carregando = false);
  }

  Future<void> carregarEquipes() async {
    equipes = await supabase.from('equipes').select('id, nome');
  }

  Future<void> carregarMateriais() async {
    materiais = await supabase.from('estoque').select('id, nome, quantidade');
  }

  Future<void> carregarClientes() async {
    clientes = await supabase.from('clientes').select('id, nome');
  }

  // ================= FILTRO =================

  List filtrarProjetos(String status) {
    final lista = projetos.where((p) {
      final st = (p["status"] ?? "").toLowerCase();

      if (status == "Em Andamento") {
        return st == "em andamento" || st == "a fazer";
      }
      return st == "concluído";
    }).toList();

    if (searchQuery.isEmpty) return lista;

    return lista.where((p) {
      return (p["clientes"]?["nome"] ?? "").toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
    }).toList();
  }

  // ================= CADASTRO =================

  void abrirCadastroProjeto() async {
    await carregarEquipes();
    await carregarMateriais();
    await carregarClientes();

    final tituloCtrl = TextEditingController();
    final descricaoCtrl = TextEditingController();

    String? equipeSelecionada;
    String? clienteSelecionado;

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
                        etapa == 1 ? "Cadastro Projeto" : "Materiais",
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

                                DropdownButtonFormField<String>(
                                  dropdownColor: cardPreto,
                                  decoration: _inputDecoration("Cliente"),
                                  items: clientes.map((c) {
                                    return DropdownMenuItem(
                                      value: c["id"].toString(),
                                      child: Text(
                                        c["nome"],
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (v) {
                                    setStateDialog(() {
                                      clienteSelecionado = v;
                                    });
                                  },
                                ),

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
                                  onChanged: (v) {
                                    setStateDialog(() {
                                      equipeSelecionada = v;
                                    });
                                  },
                                ),
                              ],
                            )
                          : Column(
                              children: materiais.map((m) {
                                final id = m["id"].toString();
                                final disp = m["quantidade"] ?? 0;
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
                                      style: const TextStyle(
                                        color: corPrincipal,
                                      ),
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

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: corPrincipal,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () async {
                      if (etapa == 1) {
                        if (clienteSelecionado == null ||
                            equipeSelecionada == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Selecione cliente e equipe"),
                            ),
                          );
                          return;
                        }

                        setStateDialog(() => etapa = 2);
                      } else {
                        await cadastrarProjetoComMateriais(
                          tituloCtrl.text,
                          descricaoCtrl.text,
                          clienteSelecionado!,
                          equipeSelecionada!,
                        );

                        Navigator.pop(context);
                      }
                    },
                    child: Text(etapa == 1 ? "Avançar" : "Salvar"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= INSERT COMPLETO =================

  Future<void> cadastrarProjetoComMateriais(
    String titulo,
    String descricao,
    String clienteId,
    String equipeId,
  ) async {
    /// 1️⃣ CRIA PROJETO
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception("Usuário não logado");
    }
    final projeto = await supabase
        .from('projetos')
        .insert({
          "nome": titulo,
          "descricao": descricao,
          "cliente_id": clienteId,
          "user_id": user!.id,
          "equipe_id": equipeId,
          "status": "em andamento",
        })
        .select()
        .single();

    final projetoId = projeto['id'];

    /// 2️⃣ VINCULA EQUIPE AO PROJETO
    await supabase.from('equipes_projetos').insert({
      "projeto_id": projetoId,
      "equipe_id": equipeId,
    });

    /// 3️⃣ INSERE MATERIAIS
    if (selecionados.isNotEmpty) {
      final dados = selecionados.entries.map((e) {
        return {
          "projeto_id": projetoId,
          "estoque_id": e.key,
          "quantidade_necessaria": e.value,
        };
      }).toList();

      await supabase.from('materiais_projeto').insert(dados);
    }

    carregarProjetos();
  }

  // ================= UI =================

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
        label: const Text("Novo Projeto"),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
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
            title: Text(p["nome"], style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              "Cliente: ${p["clientes"]?["nome"] ?? ""}",
              style: const TextStyle(color: corPrincipal),
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
