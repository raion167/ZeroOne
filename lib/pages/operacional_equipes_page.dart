import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeroone/pages/detalhes_equipe_page.dart';

const Color corPrincipal = Color(0xFFBBFB04);
const Color fundoEscuro = Color(0xFF0D0D0D);

final supabase = Supabase.instance.client;

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

  // ================= CARREGAR EQUIPES =================
  Future<void> carregarEquipes() async {
    setState(() => carregando = true);

    try {
      final response = await supabase.from('equipes').select('''
        id,
        nome,
        equipe_usuario(
          usuarios_operacional(
            id,
            nome
          )
        )
      ''');

      equipes = List<Map<String, dynamic>>.from(response).map((e) {
        final usuarios =
            (e['equipe_usuario'] as List?)
                ?.map((eu) => eu['usuarios_operacional'])
                .whereType<Map<String, dynamic>>()
                .toList() ??
            [];

        return {'id': e['id'], 'nome': e['nome'], 'usuarios': usuarios};
      }).toList();

      setState(() => carregando = false);
    } catch (e) {
      setState(() => carregando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao carregar equipes: $e")));
    }
  }

  // ================= CADASTRAR EQUIPE =================
  void abrirCadastroEquipe() {
    final nomeCtrl = TextEditingController();

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
                if (nomeCtrl.text.trim().isEmpty) return;

                await supabase.from('equipes').insert({
                  'nome': nomeCtrl.text.trim(),
                });

                Navigator.pop(context);
                carregarEquipes();
              },
              child: const Text("Salvar"),
            ),
          ],
        ),
      ),
    );
  }

  // ================= VINCULAR OPERADOR =================
  void abrirVincularOperador(Object equipeId, String equipeNome) async {
    String? usuarioSelecionado;

    final usuariosResp = await supabase
        .from('usuarios_operacional')
        .select('id, nome');

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
          items: usuariosResp
              .map<DropdownMenuItem<String>>(
                (u) => DropdownMenuItem(
                  value: u['id'].toString(),
                  child: Text(u['nome']?.toString() ?? ''),
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

              await supabase.from('equipe_usuario').insert({
                'equipe_id': equipeId.toString(),
                'usuario_id': usuarioSelecionado,
              });

              Navigator.pop(context);
              carregarEquipes();
            },
            child: const Text("Vincular"),
          ),
        ],
      ),
    );
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
                      e['nome'],
                      style: const TextStyle(
                        color: corPrincipal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Operadores: ${(e['usuarios'] as List).map((u) => u['nome']?.toString() ?? '').join(', ')}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.link, color: corPrincipal),
                      onPressed: () =>
                          abrirVincularOperador(e['id'], e['nome']),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetalhesEquipePage(
                            equipeId: e['id'],
                            nomeEquipe: e['nome'],
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
