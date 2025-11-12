import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class ContasListagemPage extends StatefulWidget {
  const ContasListagemPage({super.key});

  @override
  State<ContasListagemPage> createState() => _ContasListagemPageState();
}

class _ContasListagemPageState extends State<ContasListagemPage> {
  bool loading = true;

  // ===== Ajuste as URLs conforme seu servidor =====
  final String urlListar =
      "http://localhost:8080/app/contas_pagar_listagem.php";
  final String urlAdd = "http://localhost:8080/app/contas_pagar_adicionar.php";
  final String urlAlterarStatus =
      "http://localhost:8080/app/alterar_status.php";
  final String urlRegistrarPagamento =
      "http://localhost:8080/app/registrar_pagamento.php";
  final String urlUploadAnexo = "http://localhost:8080/app/upload_anexo.php";
  // ================================================

  // filtros
  DateTime? dataInicial;
  DateTime? dataFinal;
  String? filtroFornecedor;
  String? filtroStatus;
  String? filtroCategoria;
  String? filtroProjeto;

  List<Map<String, dynamic>> contas = [];
  List<Map<String, dynamic>> contasFiltradas = [];

  @override
  void initState() {
    super.initState();
    _carregarContas();
  }

  // =================== LISTAR =====================
  Future<void> _carregarContas() async {
    setState(() => loading = true);
    try {
      final res = await http.get(Uri.parse(urlListar));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["success"] == true && data["contas"] != null) {
          contas = List<Map<String, dynamic>>.from(
            data["contas"].map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e),
            ),
          );
          contasFiltradas = List.from(contas);
        } else {
          contas = [];
          contasFiltradas = [];
        }
      } else {
        contas = [];
        contasFiltradas = [];
        debugPrint("HTTP ${res.statusCode} ao listar contas");
      }
    } catch (e) {
      debugPrint("Erro ao carregar contas: $e");
      contas = [];
      contasFiltradas = [];
    } finally {
      setState(() => loading = false);
    }
  }

  // =================== ADICIONAR ==================
  Future<void> _adicionarConta(Map<String, dynamic> conta) async {
    try {
      final res = await http.post(
        Uri.parse(urlAdd),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(conta),
      );
      final data = jsonDecode(res.body);
      if (data["success"] == true) {
        Navigator.pop(context); // fecha o dialog de adicionar
        await _carregarContas();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Conta adicionada com sucesso!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao adicionar: ${data['message'] ?? 'erro'}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao adicionar: $e")));
    }
  }

  // ================== ALTERAR STATUS ==============
  Future<void> _alterarStatus(String id, String novoStatus) async {
    try {
      final res = await http.post(
        Uri.parse(urlAlterarStatus),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": id, "status": novoStatus}),
      );
      final data = jsonDecode(res.body);
      if (data["success"] == true) {
        await _carregarContas();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Status alterado para $novoStatus")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: ${data['message'] ?? 'erro'}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao alterar status: $e")));
    }
  }

  // ================ REGISTRAR PAGAMENTO ===========
  Future<void> _registrarPagamento(
    String id,
    String metodo,
    DateTime dataPagamento, {
    double? valorPago,
  }) async {
    try {
      final payload = {
        "id": id,
        "metodo": metodo,
        "data_pagamento": DateFormat("dd-MM-yyyy").format(dataPagamento),
        if (valorPago != null) "valor_pago": valorPago,
      };
      final res = await http.post(
        Uri.parse(urlRegistrarPagamento),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
      final data = jsonDecode(res.body);
      if (data["success"] == true) {
        // assume backend já marca como Pago. Se não, também chamamos alterar status.
        if (data["updated"] != true) {
          await _alterarStatus(id, "Pago");
        } else {
          await _carregarContas();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pagamento registrado com sucesso")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: ${data['message'] ?? 'erro'}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao registrar pagamento: $e")),
      );
    }
  }

  // ================= UPLOAD ANEXO =================
  Future<void> _uploadAnexo(String contaId) async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result == null || result.files.isEmpty) return;

      final uri = Uri.parse(urlUploadAnexo);
      var request = http.MultipartRequest('POST', uri);
      request.fields['id'] = contaId;

      for (final f in result.files) {
        final path = f.path;
        if (path == null) continue; // no web support here
        request.files.add(
          await http.MultipartFile.fromPath('arquivos[]', path),
        );
      }

      final streamed = await request.send();
      final respStr = await streamed.stream.bytesToString();
      final data = jsonDecode(respStr);
      if (data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Anexo(s) enviado(s) com sucesso")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao enviar anexo: ${data['message'] ?? 'erro'}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro no upload: $e")));
    }
  }

  // ================= FILTROS LOCAIS ==============
  void aplicarFiltros() {
    setState(() {
      contasFiltradas = contas.where((c) {
        DateTime dt =
            DateTime.tryParse(c["vencimento"]?.toString() ?? "") ??
            DateTime.now();

        if (dataInicial != null && dt.isBefore(dataInicial!)) return false;
        if (dataFinal != null && dt.isAfter(dataFinal!)) return false;
        if (filtroFornecedor != null && filtroFornecedor != c["fornecedor"])
          return false;
        if (filtroStatus != null && filtroStatus != c["status"]) return false;
        if (filtroCategoria != null && filtroCategoria != c["categoria"])
          return false;
        if (filtroProjeto != null && filtroProjeto != c["projeto"])
          return false;

        return true;
      }).toList();
    });
  }

  // =============== UI HELPERS ====================
  Color _corStatus(String status) {
    switch (status) {
      case "Pago":
        return Colors.green;
      case "Atrasado":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _iconStatus(String status) {
    switch (status) {
      case "Pago":
        return Icons.check_circle;
      case "Atrasado":
        return Icons.error;
      default:
        return Icons.schedule;
    }
  }

  // =============== DIALOGS / POPUPS ==============
  // Modal de seleção rápida de novo status (mantém comportamento anterior)
  void _abrirAlterarStatus(String idConta, String statusAtual) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Alterar Status"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("Pendente"),
                onTap: () {
                  Navigator.pop(context);
                  _alterarStatus(idConta, "Pendente");
                },
              ),
              ListTile(
                title: const Text("Pago"),
                onTap: () {
                  Navigator.pop(context);
                  _alterarStatus(idConta, "Pago");
                },
              ),
              ListTile(
                title: const Text("Atrasado"),
                onTap: () {
                  Navigator.pop(context);
                  _alterarStatus(idConta, "Atrasado");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Formulário para adicionar conta (com recorrencia e parcelas)
  void _abrirFormularioAdicionar() {
    final descricaoCtrl = TextEditingController();
    final fornecedorCtrl = TextEditingController();
    final valorCtrl = TextEditingController();
    final categoriaCtrl = TextEditingController();
    final projetoCtrl = TextEditingController();
    String recorrencia = "nenhuma";
    int parcelas = 1;
    DateTime? vencimento;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: const Text("Adicionar Conta"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: descricaoCtrl,
                    decoration: const InputDecoration(labelText: "Descrição"),
                  ),
                  TextField(
                    controller: fornecedorCtrl,
                    decoration: const InputDecoration(labelText: "Fornecedor"),
                  ),
                  TextField(
                    controller: categoriaCtrl,
                    decoration: const InputDecoration(labelText: "Categoria"),
                  ),
                  TextField(
                    controller: projetoCtrl,
                    decoration: const InputDecoration(
                      labelText: "Projeto/Centro de Custo",
                    ),
                  ),
                  TextField(
                    controller: valorCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Valor (ex: 350.75)",
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: recorrencia,
                    items: const [
                      DropdownMenuItem(
                        value: "nenhuma",
                        child: Text("Não recorrente"),
                      ),
                      DropdownMenuItem(value: "mensal", child: Text("Mensal")),
                      DropdownMenuItem(
                        value: "semanal",
                        child: Text("Semanal"),
                      ),
                      DropdownMenuItem(value: "anual", child: Text("Anual")),
                    ],
                    onChanged: (v) =>
                        setStateDialog(() => recorrencia = v ?? "nenhuma"),
                    decoration: const InputDecoration(labelText: "Recorrência"),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text("Parcelas: "),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: parcelas.toString(),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final val = int.tryParse(v) ?? 1;
                            setStateDialog(() => parcelas = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final dt = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (dt != null) setStateDialog(() => vencimento = dt);
                    },
                    child: Text(
                      vencimento == null
                          ? "Selecionar Vencimento"
                          : DateFormat("dd/MM/yyyy").format(vencimento!),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (vencimento == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Selecione a data de vencimento"),
                      ),
                    );
                    return;
                  }
                  final conta = {
                    "descricao": descricaoCtrl.text,
                    "fornecedor": fornecedorCtrl.text,
                    "categoria": categoriaCtrl.text,
                    "projeto": projetoCtrl.text,
                    "valor": double.tryParse(valorCtrl.text) ?? 0,
                    "status": "Pendente",
                    "vencimento": DateFormat("dd-MM-yyyy").format(vencimento!),
                    "recorrencia": recorrencia,
                    "parcelas": parcelas,
                  };
                  _adicionarConta(conta);
                },
                child: const Text("Salvar"),
              ),
            ],
          );
        },
      ),
    );
  }

  // Popup centralizado médio com abas: Detalhes / Anexos / Registrar Pagamento
  void _abrirDetalhesConta(Map<String, dynamic> conta) {
    final id = conta["id"].toString();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 80,
          ),
          child: SizedBox(
            width: 700,
            height: 520,
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  Container(
                    color: Theme.of(context).primaryColor,
                    child: TabBar(
                      indicatorColor: Colors.white,
                      tabs: const [
                        Tab(text: "Anexos"),
                        Tab(text: "Registrar Pagamento"),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // -------- ANEXOS ----------
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Anexos",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Clique em 'Enviar Anexo' para carregar arquivos relacionados a esta conta.",
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => _uploadAnexo(id),
                                icon: const Icon(Icons.upload_file),
                                label: const Text("Enviar Anexo(s)"),
                              ),
                              const SizedBox(height: 12),
                              // Aqui, se desejar, você pode fazer fetch dos anexos do servidor e listar.
                            ],
                          ),
                        ),

                        // -------- REGISTRAR PAGAMENTO ----------
                        RegistrarPagamentoTab(
                          contaId: id,
                          onPagamentoRegistrado:
                              (metodo, dataPagamento, valorPago) async {
                                // chama registrar pagamento e fecha dialog
                                await _registrarPagamento(
                                  id,
                                  metodo,
                                  dataPagamento,
                                  valorPago: valorPago,
                                );
                                Navigator.pop(context);
                              },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ================ Build principal =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contas a Pagar"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _abrirFormularioAdicionar,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarContas,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ExpansionTile(
                  title: const Text("Filtros"),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final dt = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          dataInicial ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (dt != null)
                                      setState(() => dataInicial = dt);
                                  },
                                  child: Text(
                                    dataInicial == null
                                        ? "Data Inicial"
                                        : DateFormat(
                                            "dd/MM/yyyy",
                                          ).format(dataInicial!),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final dt = await showDatePicker(
                                      context: context,
                                      initialDate: dataFinal ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (dt != null)
                                      setState(() => dataFinal = dt);
                                  },
                                  child: Text(
                                    dataFinal == null
                                        ? "Data Final"
                                        : DateFormat(
                                            "dd/MM/yyyy",
                                          ).format(dataFinal!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: "Fornecedor",
                                  ),
                                  onChanged: (v) => setState(
                                    () =>
                                        filtroFornecedor = v.isEmpty ? null : v,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: "Categoria",
                                  ),
                                  onChanged: (v) => setState(
                                    () =>
                                        filtroCategoria = v.isEmpty ? null : v,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: "Status",
                                  ),
                                  onChanged: (v) => setState(
                                    () => filtroStatus = v.isEmpty ? null : v,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: "Projeto",
                                  ),
                                  onChanged: (v) => setState(
                                    () => filtroProjeto = v.isEmpty ? null : v,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: aplicarFiltros,
                            icon: const Icon(Icons.filter_alt),
                            label: const Text("Aplicar Filtros"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: contasFiltradas.isEmpty
                      ? const Center(child: Text("Nenhuma conta encontrada."))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: contasFiltradas.length,
                          itemBuilder: (context, i) {
                            final c = contasFiltradas[i];
                            final status =
                                c["status"]?.toString() ?? "Pendente";
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 3,
                              child: ListTile(
                                onTap: () => _abrirDetalhesConta(c),
                                leading: GestureDetector(
                                  onTap: () => _abrirAlterarStatus(
                                    c["id"].toString(),
                                    status,
                                  ),
                                  child: Chip(
                                    avatar: Icon(
                                      _iconStatus(status),
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    backgroundColor: _corStatus(status),
                                    label: Text(
                                      status,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(c["descricao"] ?? "-"),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Fornecedor: ${c["fornecedor"] ?? '-'}",
                                    ),
                                    Text(
                                      "Vencimento: ${c["vencimento"] ?? '-'} • Projeto: ${c["projeto"] ?? '-'}",
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  "R\$ ${c["valor"]?.toString() ?? '-'}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// ==================== WIDGET: RegistrarPagamentoTab ====================
class RegistrarPagamentoTab extends StatefulWidget {
  final String contaId;
  final Future<void> Function(
    String metodo,
    DateTime dataPagamento,
    double? valorPago,
  )
  onPagamentoRegistrado;

  const RegistrarPagamentoTab({
    super.key,
    required this.contaId,
    required this.onPagamentoRegistrado,
  });

  @override
  State<RegistrarPagamentoTab> createState() => _RegistrarPagamentoTabState();
}

class _RegistrarPagamentoTabState extends State<RegistrarPagamentoTab> {
  String metodo = "pix";
  DateTime? dataPagamento;
  final valorCtrl = TextEditingController();

  @override
  void dispose() {
    valorCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarDataPagamento() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: dataPagamento ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (dt != null) setState(() => dataPagamento = dt);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: metodo,
            items: const [
              DropdownMenuItem(value: "pix", child: Text("PIX")),
              DropdownMenuItem(value: "credito", child: Text("Crédito")),
              DropdownMenuItem(value: "debito", child: Text("Débito")),
              DropdownMenuItem(value: "avista", child: Text("À vista")),
              DropdownMenuItem(value: "boleto", child: Text("Boleto")),
            ],
            onChanged: (v) => setState(() => metodo = v ?? "pix"),
            decoration: const InputDecoration(labelText: "Método de pagamento"),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: valorCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Valor pago (opcional)",
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _selecionarDataPagamento,
            child: Text(
              dataPagamento == null
                  ? "Selecionar data de pagamento"
                  : DateFormat("dd/MM/yyyy").format(dataPagamento!),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (dataPagamento == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Selecione a data de pagamento"),
                      ),
                    );
                    return;
                  }
                  final valor = double.tryParse(valorCtrl.text);
                  widget.onPagamentoRegistrado(metodo, dataPagamento!, valor);
                },
                child: const Text("Registrar pagamento"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
