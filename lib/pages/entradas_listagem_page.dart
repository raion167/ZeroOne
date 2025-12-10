import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

const String apiBase = "http://localhost:8080/app/"; // ALTERAR AQUI

class EntradasListagemPage extends StatefulWidget {
  const EntradasListagemPage({super.key});

  @override
  State<EntradasListagemPage> createState() => _EntradasListagemPageState();
}

class _EntradasListagemPageState extends State<EntradasListagemPage> {
  List entradas = [];
  bool loading = true;

  // Controllers do formulário
  final TextEditingController valorController = TextEditingController();
  final TextEditingController identificadorController = TextEditingController();

  DateTime? dataRecebimento;
  DateTime? dataCompetencia;

  String? categoriaSelecionada;
  String? formaPagamentoSelecionada;
  String? contaDestinoSelecionada;
  String? statusSelecionado;

  final List<String> categorias = [
    "Serviços",
    "Vendas",
    "Assinaturas",
    "Outros",
  ];

  final List<String> formasPagamento = [
    "Pix",
    "Crédito",
    "Débito",
    "Dinheiro",
    "Boleto",
  ];

  final List<String> contasBancarias = ["Bradesco", "Caixa", "Nubank", "Itaú"];

  final List<String> statusList = ["Recebido", "Pendente"];

  @override
  void initState() {
    super.initState();
    carregarEntradas();
  }

  // 🔥 Buscar do banco
  Future<void> carregarEntradas() async {
    setState(() => loading = true);

    final url = Uri.parse("${apiBase}listar_entradas.php");
    final response = await http.get(url);

    final data = jsonDecode(response.body);

    if (data["success"]) {
      setState(() {
        entradas = data["entradas"];
        loading = false;
      });
    }
  }

  // 🔥 Enviar dados para o PHP
  Future<void> salvarEntrada() async {
    if (valorController.text.isEmpty ||
        identificadorController.text.isEmpty ||
        dataRecebimento == null ||
        dataCompetencia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos obrigatórios!")),
      );
      return;
    }

    final url = Uri.parse("${apiBase}adicionar_entrada.php");

    final Map<String, dynamic> dados = {
      "data_recebimento": DateFormat("yyyy-MM-dd").format(dataRecebimento!),
      "data_competencia": DateFormat("yyyy-MM-dd").format(dataCompetencia!),
      "valor_recebido": double.parse(valorController.text),
      "identificador": identificadorController.text,
      "categoria": categoriaSelecionada,
      "forma_pagamento": formaPagamentoSelecionada,
      "conta_destino": contaDestinoSelecionada,
      "status": statusSelecionado,
    };

    final response = await http.post(
      url,
      body: jsonEncode(dados),
      headers: {"Content-Type": "application/json"},
    );

    final data = jsonDecode(response.body);

    if (data["success"]) {
      Navigator.pop(context);
      await carregarEntradas();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Erro ao salvar")));
    }
  }

  // 🔥 Abrir Formulário
  void abrirFormulario() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                "Adicionar Entrada",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Data Recebimento
              ListTile(
                title: Text(
                  dataRecebimento == null
                      ? "Data de Recebimento"
                      : DateFormat("dd/MM/yyyy").format(dataRecebimento!),
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  var d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2022),
                    lastDate: DateTime(2035),
                  );
                  if (d != null) {
                    setState(() => dataRecebimento = d);
                  }
                },
              ),

              // Data Competencia
              ListTile(
                title: Text(
                  dataCompetencia == null
                      ? "Data de Competência"
                      : DateFormat("dd/MM/yyyy").format(dataCompetencia!),
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  var d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2022),
                    lastDate: DateTime(2035),
                  );
                  if (d != null) {
                    setState(() => dataCompetencia = d);
                  }
                },
              ),

              // Valor
              TextField(
                controller: valorController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Valor Recebido"),
              ),
              const SizedBox(height: 10),

              // Identificador
              TextField(
                controller: identificadorController,
                decoration: const InputDecoration(labelText: "Identificador"),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField(
                value: categoriaSelecionada,
                hint: const Text("Categoria"),
                items: categorias
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => categoriaSelecionada = v),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField(
                value: formaPagamentoSelecionada,
                hint: const Text("Forma de Pagamento"),
                items: formasPagamento
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => formaPagamentoSelecionada = v),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField(
                value: contaDestinoSelecionada,
                hint: const Text("Conta Bancária"),
                items: contasBancarias
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => contaDestinoSelecionada = v),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField(
                value: statusSelecionado,
                hint: const Text("Status"),
                items: statusList
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => statusSelecionado = v),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: salvarEntrada,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Salvar", style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Interface
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Entradas Financeiras")),

      floatingActionButton: FloatingActionButton(
        onPressed: abrirFormulario,
        child: const Icon(Icons.add),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : entradas.isEmpty
          ? const Center(child: Text("Nenhuma entrada encontrada"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entradas.length,
              itemBuilder: (_, i) {
                final item = entradas[i];

                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.attach_money,
                      color: Colors.green,
                    ),
                    title: Text(item["identificador"] ?? "-"),
                    subtitle: Text(
                      "Recebido: ${item["data_recebimento"] ?? "-"}\n"
                      "Competência: ${item["data_competencia"] ?? "-"}\n"
                      "Categoria: ${item["categoria"] ?? "-"}\n"
                      "Forma de Pagamento: ${item["forma_pagamento"] ?? "-"}\n"
                      "Conta de Destino: ${item["conta_destino"] ?? "-"}\n"
                      "Status: ${item["status"] ?? "-"}",
                    ),
                    trailing: Text(
                      "R\$ ${(item["valor_recebido"] ?? item["valor_recebido"] ?? 0).toString()}",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
