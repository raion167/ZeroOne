import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:ui';

const String apiBase = "http://localhost:8080/app/";
const Color corPrincipal = Color(0xFFBBFB04);
const Color corPendente = Colors.redAccent;

class EntradasListagemPage extends StatefulWidget {
  const EntradasListagemPage({super.key});

  @override
  State<EntradasListagemPage> createState() => _EntradasListagemPageState();
}

class _EntradasListagemPageState extends State<EntradasListagemPage> {
  List entradas = [];
  bool loading = true;

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
    }
  }

  void abrirFormulario() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: corPrincipal, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: corPrincipal.withOpacity(0.6),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
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
                  style: TextStyle(
                    color: corPrincipal,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                _campoData(
                  label: "Data de Recebimento",
                  data: dataRecebimento,
                  onSelect: (d) => setState(() => dataRecebimento = d),
                ),
                _campoData(
                  label: "Data de Competência",
                  data: dataCompetencia,
                  onSelect: (d) => setState(() => dataCompetencia = d),
                ),

                _campoTexto(valorController, "Valor Recebido", true),
                _campoTexto(identificadorController, "Identificador", false),

                _dropdown(
                  "Categoria",
                  categorias,
                  categoriaSelecionada,
                  (v) => setState(() => categoriaSelecionada = v),
                ),

                _dropdown(
                  "Forma de Pagamento",
                  formasPagamento,
                  formaPagamentoSelecionada,
                  (v) => setState(() => formaPagamentoSelecionada = v),
                ),

                _dropdown(
                  "Conta de Destino",
                  contasBancarias,
                  contaDestinoSelecionada,
                  (v) => setState(() => contaDestinoSelecionada = v),
                ),

                _dropdown(
                  "Status",
                  statusList,
                  statusSelecionado,
                  (v) => setState(() => statusSelecionado = v),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: salvarEntrada,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: corPrincipal,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("Salvar"),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Entradas Financeiras"),
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: corPrincipal,
        foregroundColor: Colors.black,
        onPressed: abrirFormulario,
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: corPrincipal))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entradas.length,
              itemBuilder: (_, i) {
                final item = entradas[i];
                final bool pendente = item["status"] == "Pendente";

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: pendente ? corPendente : corPrincipal,
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (pendente ? corPendente : corPrincipal)
                            .withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.attach_money,
                      color: pendente ? corPendente : corPrincipal,
                    ),
                    title: Text(
                      item["identificador"] ?? "-",
                      style: TextStyle(
                        color: pendente ? corPendente : corPrincipal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Recebimento: ${item["data_recebimento"]}\n"
                      "Competência: ${item["data_competencia"]}\n"
                      "Categoria: ${item["categoria"]}\n"
                      "Forma: ${item["forma_pagamento"]}\n"
                      "Conta: ${item["conta_destino"]}\n"
                      "Status: ${item["status"]}",
                      style: TextStyle(color: Colors.white.withOpacity(0.75)),
                    ),
                    trailing: Text(
                      "R\$ ${item["valor_recebido"]}",
                      style: TextStyle(
                        color: pendente ? corPendente : corPrincipal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _campoTexto(TextEditingController c, String label, bool numero) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: numero ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: corPrincipal),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: corPrincipal),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: corPrincipal),
          ),
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField(
      dropdownColor: Colors.black,
      value: value,
      hint: Text(label, style: const TextStyle(color: corPrincipal)),
      items: items
          .map(
            (c) => DropdownMenuItem(
              value: c,
              child: Text(c, style: const TextStyle(color: corPrincipal)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _campoData({
    required String label,
    required DateTime? data,
    required Function(DateTime) onSelect,
  }) {
    return ListTile(
      title: Text(
        data == null ? label : DateFormat("dd/MM/yyyy").format(data),
        style: const TextStyle(color: corPrincipal),
      ),
      trailing: const Icon(Icons.calendar_month, color: corPrincipal),
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2022),
          lastDate: DateTime(2035),
        );
        if (d != null) onSelect(d);
      },
    );
  }
}
