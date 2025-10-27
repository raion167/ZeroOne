import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OperacionalOperadoresPage extends StatefulWidget {
  const OperacionalOperadoresPage({super.key});

  @override
  State<OperacionalOperadoresPage> createState() =>
      _OperacionalOperadoresPageState();
}

class _OperacionalOperadoresPageState extends State<OperacionalOperadoresPage> {
  List<dynamic> operadores = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarOperadores();
  }

  Future<void> carregarOperadores() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8080/app/listar_usuarios_operacional.php"),
      );

      final data = jsonDecode(response.body);

      // Verifica se existe "success" e é true
      if (data["success"] == true) {
        setState(() {
          operadores = List<dynamic>.from(data["usuarios"] ?? []);
          carregando = false; // Atualiza o indicador de carregamento
        });
      } else {
        setState(() {
          operadores = [];
          carregando = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Erro ao carregar usuários"),
          ),
        );
      }
    } catch (e) {
      setState(() {
        carregando = false;
        operadores = [];
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao carregar usuários: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Operadores Cadastrados"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : operadores.isEmpty
          ? const Center(child: Text("Nenhum operador cadastrado."))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: operadores.length,
              itemBuilder: (context, index) {
                final op = operadores[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.black87),
                    title: Text(op["nome"]),
                    subtitle: Text(op["email"]),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        onPressed: () {
          // Aqui você pode abrir uma nova tela para cadastrar operador
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CadastrarOperadorPage(),
            ),
          ).then((_) => carregarOperadores()); // Atualiza após cadastro
        },
        icon: const Icon(Icons.add),
        label: const Text("Cadastrar Operador"),
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
      final response = await http.post(
        Uri.parse(
          'http://localhost:8080/app/cadastrar_usuario_operacional.php',
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'nome': nomeController.text,
          'email': emailController.text,
          'senha': senhaController.text,
        }),
      );
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Operador cadastrado com sucesso!")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro: ${data["message"]}")));
      }
    } catch (e) {
      print("Erro ao cadastrar operador: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cadastrar Operador"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: "Nome"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "E-mail"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: senhaController,
              decoration: const InputDecoration(labelText: "Senha"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: cadastrarOperador,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text("Salvar Operador"),
            ),
          ],
        ),
      ),
    );
  }
}
