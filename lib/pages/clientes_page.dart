import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'painel_cliente_solar_page.dart';

const Color corPrincipal = Color(0xFFBBFB04);
const Color fundoPreto = Colors.black;
const Color cardPreto = Color.fromARGB(255, 20, 20, 20);

final supabase = Supabase.instance.client;

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  bool carregando = true;
  List<Map<String, dynamic>> clientes = [];

  @override
  void initState() {
    super.initState();
    carregarClientes();
  }

  // ================= CARREGAR CLIENTES =================

  Future<void> carregarClientes() async {
    setState(() => carregando = true);

    try {
      final response = await supabase
          .from('clientes')
          .select()
          .order('id', ascending: false);

      clientes = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar clientes: $e')));
    }

    setState(() => carregando = false);
  }

  // ================= CADASTRO CLIENTE =================

  void abrirCadastroCliente() {
    final nomeCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telefoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardPreto,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Novo Cliente',
          style: TextStyle(color: corPrincipal),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _campo(nomeCtrl, 'Nome'),
              _campo(emailCtrl, 'Email'),
              _campo(telefoneCtrl, 'Telefone'),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: corPrincipal,
              foregroundColor: Colors.black,
            ),
            child: const Text('Salvar'),
            onPressed: () async {
              try {
                await supabase.from('clientes').insert({
                  'nome': nomeCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'telefone': telefoneCtrl.text.trim(),
                });

                Navigator.pop(context);
                carregarClientes();
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
              }
            },
          ),
        ],
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundoPreto,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
        title: const Text('Clientes'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: corPrincipal,
        foregroundColor: Colors.black,
        onPressed: abrirCadastroCliente,
        icon: const Icon(Icons.add),
        label: const Text('Novo Cliente'),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator(color: corPrincipal))
          : clientes.isEmpty
          ? const Center(
              child: Text(
                'Nenhum cliente cadastrado',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: clientes.length,
              itemBuilder: (_, i) {
                final c = clientes[i];

                return Card(
                  color: cardPreto,
                  child: ListTile(
                    leading: const Icon(Icons.person, color: corPrincipal),
                    title: Text(
                      c['nome'] ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${c['email'] ?? ''} • ${c['telefone'] ?? ''}',
                      style: const TextStyle(color: corPrincipal),
                    ),

                    // 👉 ABRIR PAINEL SOLAR
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PainelSolarClientePage(
                            clienteId: c['id'].toString(),
                            nomeCliente: c['nome'] ?? '',
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

  // ================= CAMPO INPUT =================

  Widget _campo(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: corPrincipal),
          filled: true,
          fillColor: fundoPreto,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: corPrincipal),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
