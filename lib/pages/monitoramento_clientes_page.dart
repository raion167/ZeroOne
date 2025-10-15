import 'package:flutter/material.dart';
import 'menu_lateral.dart'; // Contém BaseScaffold

class Cliente {
  final String nome;
  final String cidade;
  final double consumo;
  final double geracao;
  final double economia;
  final bool online;

  Cliente({
    required this.nome,
    required this.cidade,
    required this.consumo,
    required this.geracao,
    required this.economia,
    required this.online,
  });
}

class MonitoramentoClientesPage extends StatefulWidget {
  final String nomeUsuario;
  final String emailUsuario;

  const MonitoramentoClientesPage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  State<MonitoramentoClientesPage> createState() =>
      _MonitoramentoClientesPageState();
}

class _MonitoramentoClientesPageState extends State<MonitoramentoClientesPage> {
  List<Cliente> todosClientes = [
    Cliente(
      nome: "João Silva",
      cidade: "Belém",
      consumo: 350,
      geracao: 420,
      economia: 180,
      online: true,
    ),
    Cliente(
      nome: "Maria Souza",
      cidade: "Belém",
      consumo: 400,
      geracao: 380,
      economia: 150,
      online: false,
    ),
    Cliente(
      nome: "Carlos Pereira",
      cidade: "Ananindeua",
      consumo: 300,
      geracao: 310,
      economia: 120,
      online: true,
    ),
  ];

  String filtro = "";

  @override
  Widget build(BuildContext context) {
    // Agrupa clientes por cidade e aplica filtro
    Map<String, List<Cliente>> clientesPorCidade = {};
    for (var cliente in todosClientes) {
      if (cliente.nome.toLowerCase().contains(filtro.toLowerCase())) {
        clientesPorCidade.putIfAbsent(cliente.cidade, () => []);
        clientesPorCidade[cliente.cidade]!.add(cliente);
      }
    }

    return BaseScaffold(
      titulo: "Monitoramento de Clientes",
      nomeUsuario: widget.nomeUsuario,
      emailUsuario: widget.emailUsuario,
      corpo: Column(
        children: [
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Pesquisar cliente",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  filtro = value;
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          // Lista de clientes agrupada por cidade
          Expanded(
            child: clientesPorCidade.isEmpty
                ? const Center(child: Text("Nenhum cliente encontrado."))
                : ListView(
                    children: clientesPorCidade.entries.map((entry) {
                      final cidade = entry.key;
                      final clientes = entry.value;
                      return ExpansionTile(
                        title: Text(
                          cidade,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: clientes.map((cliente) {
                          return ListTile(
                            title: Text(cliente.nome),
                            trailing: Icon(
                              cliente.online
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: cliente.online ? Colors.green : Colors.red,
                            ),
                            onTap: () {
                              // Abre detalhes do cliente
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetalhesClientePage(
                                    cliente: cliente,
                                    nomeUsuario: widget.nomeUsuario,
                                    emailUsuario: widget.emailUsuario,
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

// Tela detalhada do cliente usando BaseScaffold
class DetalhesClientePage extends StatelessWidget {
  final Cliente cliente;
  final String nomeUsuario;
  final String emailUsuario;

  const DetalhesClientePage({
    super.key,
    required this.cliente,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      titulo: "Cliente: ${cliente.nome}",
      nomeUsuario: nomeUsuario,
      emailUsuario: emailUsuario,
      corpo: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Cidade: ${cliente.cidade}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Consumo Atual: ${cliente.consumo} kWh",
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              "Geração Atual: ${cliente.geracao} kWh",
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              "Economia Mensal: ${cliente.economia} R\$",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: cliente.online ? Colors.green : Colors.red,
              ),
              child: Text(
                cliente.online ? "ONLINE" : "OFFLINE",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
