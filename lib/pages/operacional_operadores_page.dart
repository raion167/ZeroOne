import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color corPrincipal = Color(0xFFBBFB04);
const Color fundoEscuro = Color(0xFF0D0D0D);

final supabase = Supabase.instance.client;

class OperacionalOperadoresPage extends StatefulWidget {
  const OperacionalOperadoresPage({super.key});

  @override
  State<OperacionalOperadoresPage> createState() =>
      _OperacionalOperadoresPageState();
}

class _OperacionalOperadoresPageState extends State<OperacionalOperadoresPage> {
  List<Map<String, dynamic>> operadores = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarOperadores();
  }

  Future<void> carregarOperadores() async {
    setState(() => carregando = true);

    try {
      final response = await supabase
          .from('usuarios_operacional')
          .select('id, nome, email')
          .order('nome');

      operadores = List<Map<String, dynamic>>.from(response);

      setState(() => carregando = false);
    } catch (e) {
      setState(() => carregando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao carregar operadores: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
        title: const Text("Operadores"),
      ),

      body: carregando
          ? const Center(child: CircularProgressIndicator(color: corPrincipal))
          : operadores.isEmpty
          ? const Center(
              child: Text(
                "Nenhum operador cadastrado",
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: operadores.length,
              itemBuilder: (_, index) {
                final op = operadores[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: fundoEscuro,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: corPrincipal.withOpacity(0.35)),
                    boxShadow: [
                      BoxShadow(
                        color: corPrincipal.withOpacity(0.25),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.person, color: corPrincipal),
                    title: Text(
                      op["nome"] ?? "-",
                      style: const TextStyle(
                        color: corPrincipal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      op["email"] ?? "-",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                );
              },
            ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: corPrincipal,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text("Cadastrar Operador"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CadastrarOperadorPage()),
          ).then((_) => carregarOperadores());
        },
      ),
    );
  }
}

class CadastrarOperadorPage extends StatefulWidget {
  const CadastrarOperadorPage({super.key});

  @override
  State<CadastrarOperadorPage> createState() => _CadastrarOperadorPageState();
}

class _CadastrarOperadorPageState extends State<CadastrarOperadorPage> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  Future<void> cadastrarOperador() async {
    try {
      await supabase.from('usuarios_operacional').insert({
        'nome': nomeController.text,
        'email': emailController.text,
        'senha': senhaController.text,
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao cadastrar operador: $e")));
    }
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: corPrincipal),
      filled: true,
      fillColor: fundoEscuro,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: corPrincipal.withOpacity(0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: corPrincipal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nomeController,
              style: const TextStyle(color: corPrincipal),
              decoration: _input("Nome"),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailController,
              style: const TextStyle(color: corPrincipal),
              decoration: _input("E-mail"),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: senhaController,
              style: const TextStyle(color: corPrincipal),
              obscureText: true,
              decoration: _input("Senha"),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: cadastrarOperador,
                icon: const Icon(Icons.save),
                label: const Text("Salvar Operador"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: corPrincipal,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
