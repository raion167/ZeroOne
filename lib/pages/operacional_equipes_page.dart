import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zeroone/pages/detalhes_equipe_page.dart';
import 'package:zeroone/pages/detalhes_projeto_page.dart';

const Color corPrincipal = Color(0xFFBBFB04);
const Color fundoEscuro = Color(0xFF0D0D0D);

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

  // ================= CADASTRO DE EQUIPE =================
  void abrirCadastroEquipe() {
    final TextEditingController nomeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: fundoEscuro,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: corPrincipal.withOpacity(0.6)),
          ),
          title: const Text(
            "Nova Equipe",
            style: TextStyle(color: corPrincipal),
          ),
          content: TextField(
            controller: nomeCtrl,
            style: const TextStyle(color: corPrincipal),
            decoration: InputDecoration(
              labelText: "Nome da equipe",
              labelStyle: const TextStyle(color: corPrincipal),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: corPrincipal.withOpacity(0.4)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: corPrincipal),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: corPrincipal,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                if (nomeCtrl.text.isEmpty) return;
                await cadastrarEquipe(nomeCtrl.text);
                Navigator.pop(context);
              },
              child: const Text("Salvar"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> cadastrarEquipe(String nome) async {
    final res = await http.post(
      Uri.parse("http://localhost:8080/app/cadastrar_equipes.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"nome": nome}),
    );
    final data = jsonDecode(res.body);
    if (data["success"] == true) carregarEquipes();
  }

  // ================= VINCULAR OPERADOR (MANTIDO) =================
  void abrirVincularOperador(int equipeId, String equipeNome) async {
    List<Map<String, dynamic>> usuarios = [];
    String? usuarioSelecionado;

    final res = await http.get(
      Uri.parse("http://localhost:8080/app/listar_usuarios_operacional.php"),
    );
    final data = jsonDecode(res.body);
    usuarios =
        (data["usuarios"] as List?)
            ?.map((u) => Map<String, dynamic>.from(u))
            .toList() ??
        [];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: fundoEscuro,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: corPrincipal.withOpacity(0.6)),
        ),
        title: Text(
          "Vincular operador à equipe $equipeNome",
          style: const TextStyle(color: corPrincipal),
        ),
        content: DropdownButtonFormField<String>(
          dropdownColor: fundoEscuro,
          style: const TextStyle(color: corPrincipal),
          items: usuarios
              .map(
                (u) => DropdownMenuItem(
                  value: u["id"].toString(),
                  child: Text(u["nome"]),
                ),
              )
              .toList(),
          onChanged: (v) => usuarioSelecionado = v,
          decoration: InputDecoration(
            labelText: "Operador",
            labelStyle: const TextStyle(color: corPrincipal),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: corPrincipal.withOpacity(0.4)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: corPrincipal,
              foregroundColor: Colors.black,
            ),
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
    await http.post(
      Uri.parse("http://localhost:8080/app/vincular_usuario_equipe.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"usuario_id": usuarioId, "equipe_id": equipeId}),
    );
    carregarEquipes();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Equipes Operacionais"),
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: corPrincipal,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text("Nova Equipe"),
        onPressed: abrirCadastroEquipe,
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: equipes.length,
              itemBuilder: (_, i) {
                final e = equipes[i];

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: fundoEscuro,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: corPrincipal.withOpacity(0.35)),
                    boxShadow: [
                      BoxShadow(
                        color: corPrincipal.withOpacity(0.25),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: Text(
                      e["nome"],
                      style: const TextStyle(
                        color: corPrincipal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Operadores: ${(e["usuarios"] ?? []).map((u) => u["nome"]).join(', ')}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.link, color: corPrincipal),
                      onPressed: () => abrirVincularOperador(
                        int.parse(e["id"].toString()),
                        e["nome"],
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetalhesEquipePage(
                            equipeId: int.parse(e["id"].toString()),
                            nomeEquipe: e["nome"],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
