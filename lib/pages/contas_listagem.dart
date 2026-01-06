import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

const Color corPrincipal = Color(0xFFBBFB04);

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
  List<String> listaProjetos = [];
  List<String> listaCategorias = [];
  List<String> listaFornecedores = [];

  @override
  void initState() {
    super.initState();
    _carregarContas();
    _carregarProjetos();
    _carregarCategorias();
    _carregarFornecedores();
  }

  Future<void> _carregarFornecedores() async {
    final res = await http.get(
      Uri.parse("http://localhost:8080/app/listar_projetos.php"),
    );
    final data = jsonDecode(res.body);

    setState(() {
      listaFornecedores = List<String>.from(
        data.map((f) => f["nome"].toString()),
      );
    });
  }

  Future<void> _carregarCategorias() async {
    final res = await http.get(
      Uri.parse("http://localhost:8080/app/listar_projetos.php"),
    );
    final data = jsonDecode(res.body);

    setState(() {
      listaFornecedores = List<String>.from(
        data.map((f) => f["nome"].toString()),
      );
    });
  }

  Future<void> _carregarProjetos() async {
    try {
      final res = await http.get(
        Uri.parse("http://localhost:8080/app/listar_projetos.php"),
      );
      if (res.statusCode != 200) {
        debugPrint('Erro ao buscar projetos: ${res.statusCode}');
        return;
      }

      final body = res.body;
      final parsed = jsonDecode(body);

      // parsed pode ser:
      // 1) uma lista direta: [ { "descricao": "..."} , ... ]
      // 2) um objeto com chave "dados" ou "projetos": { "dados": [...]} ou {"projetos":[...]}
      List<dynamic> listaRaw = [];

      if (parsed is List) {
        listaRaw = parsed;
      } else if (parsed is Map) {
        if (parsed.containsKey('dados') && parsed['dados'] is List) {
          listaRaw = parsed['dados'];
        } else if (parsed.containsKey('projetos') &&
            parsed['projetos'] is List) {
          listaRaw = parsed['projetos'];
        } else {
          // tenta extrair o primeiro item que seja lista
          final firstList = parsed.values.firstWhere(
            (v) => v is List,
            orElse: () => null,
          );
          if (firstList is List) listaRaw = firstList;
        }
      }

      final novos = listaRaw
          .map<String>((p) {
            try {
              if (p is Map && p.containsKey('descricao'))
                return p['descricao'].toString();
              if (p is Map && p.containsKey('nome'))
                return p['nome'].toString();
              // se p for string já retorna ela
              if (p is String) return p;
              // fallback: stringify
              return p.toString();
            } catch (e) {
              return '';
            }
          })
          .where((s) => s.isNotEmpty)
          .toList();

      if (!mounted) return; // evitar setState se o widget não existe mais
      setState(() {
        listaProjetos = novos;
      });
    } catch (e, st) {
      debugPrint('Erro _carregarProjetos: $e\n$st');
      // manter lista vazia em caso de falha
      if (mounted) {
        setState(() {
          listaProjetos = [];
        });
      }
    }
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
    final valorCtrl = TextEditingController();
    String? fornecedorSel;
    String? categoriaSel;
    String? projetoSel;

    String recorrencia = "nenhuma";
    int parcelas = 1;
    DateTime? vencimento;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusGeometry.circular(18),
              side: BorderSide(color: corPrincipal, width: 1.2),
            ),
            title: const Text(
              "Adicionar Conta",
              style: TextStyle(color: corPrincipal),
            ),
            contentPadding: const EdgeInsets.all(20),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 30,
            ),
            content: SizedBox(
              width: 450, // 🔥 POPUP MAIOR
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: descricaoCtrl,
                      style: TextStyle(color: corPrincipal),
                      decoration: InputDecoration(
                        labelText: "Descrição",
                        labelStyle: TextStyle(color: corPrincipal),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: corPrincipal.withOpacity(0.6),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: corPrincipal),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 🔥 FORNECEDORES (DROPDOWN)
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.black,
                      style: TextStyle(color: corPrincipal),
                      decoration: InputDecoration(
                        labelText: "Fornecedor",
                        labelStyle: TextStyle(color: corPrincipal),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: corPrincipal.withOpacity(0.6),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: corPrincipal),
                        ),
                      ),
                      value: fornecedorSel,
                      items: listaFornecedores
                          .map(
                            (f) => DropdownMenuItem(value: f, child: Text(f)),
                          )
                          .toList(),
                      onChanged: (v) => setStateDialog(() => fornecedorSel = v),
                    ),

                    const SizedBox(height: 12),

                    // 🔥 CATEGORIAS FIXAS
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.black,
                      style: TextStyle(color: corPrincipal),
                      decoration: InputDecoration(
                        labelText: "Categoria",
                        labelStyle: TextStyle(color: corPrincipal),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: corPrincipal.withOpacity(0.6),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: corPrincipal),
                        ),
                      ),
                      value: categoriaSel,
                      items: listaCategorias
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setStateDialog(() => categoriaSel = v),
                    ),

                    const SizedBox(height: 12),

                    // 🔥 PROJETOS — PEGO DO BANCO
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.black,
                      style: TextStyle(color: corPrincipal),
                      decoration: InputDecoration(
                        labelText: "Projetos/Centro de Custo",
                        labelStyle: TextStyle(color: corPrincipal),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: corPrincipal.withOpacity(0.6),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: corPrincipal),
                        ),
                      ),
                      value: projetoSel,
                      items: listaProjetos
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                      onChanged: (v) => setStateDialog(() => projetoSel = v),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: valorCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: corPrincipal),
                      decoration: InputDecoration(
                        labelText: "Valor",
                        labelStyle: TextStyle(color: corPrincipal),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: corPrincipal.withOpacity(0.6),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: corPrincipal),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🔥 RECORRÊNCIA
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.black,
                      style: TextStyle(color: corPrincipal),
                      decoration: InputDecoration(
                        labelText: "Recorrência",
                        labelStyle: TextStyle(color: corPrincipal),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: corPrincipal.withOpacity(0.6),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: corPrincipal),
                        ),
                      ),
                      value: recorrencia,
                      items: const [
                        DropdownMenuItem(
                          value: "nenhuma",
                          child: Text("Não recorrente"),
                        ),
                        DropdownMenuItem(
                          value: "mensal",
                          child: Text("Mensal"),
                        ),
                        DropdownMenuItem(
                          value: "semanal",
                          child: Text("Semanal"),
                        ),
                        DropdownMenuItem(value: "anual", child: Text("Anual")),
                      ],
                      onChanged: (v) =>
                          setStateDialog(() => recorrencia = v ?? "nenhuma"),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Text(
                          "Parcelas:",
                          style: TextStyle(
                            color: corPrincipal,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: parcelas,
                            dropdownColor: Colors.black,
                            iconEnabledColor: Colors.black,
                            style: TextStyle(color: corPrincipal),
                            decoration: InputDecoration(
                              labelText: "Quantidade de Parcelas",
                              labelStyle: TextStyle(color: corPrincipal),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: corPrincipal.withOpacity(0.6),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: corPrincipal),
                              ),
                            ),
                            items: List.generate(
                              24,
                              (i) => DropdownMenuItem<int>(
                                value: i + 1,
                                child: Text(
                                  "${i + 1}x",
                                  style: TextStyle(color: corPrincipal),
                                ),
                              ),
                            ),
                            onChanged: (v) {
                              if (v != null) {
                                setStateDialog(() => parcelas = v);
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: corPrincipal.withOpacity(0.15),
                        foregroundColor: corPrincipal,
                        side: BorderSide(color: corPrincipal),
                      ),
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
                            : DateFormat("yyyy/MM/dd").format(vencimento!),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: corPrincipal.withOpacity(0.7),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: corPrincipal.withOpacity(0.15),
                  foregroundColor: corPrincipal,
                  side: BorderSide(color: corPrincipal),
                ),
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
                    "fornecedor": fornecedorSel ?? "",
                    "categoria": categoriaSel ?? "",
                    "projeto": projetoSel ?? "",
                    "valor": double.tryParse(valorCtrl.text) ?? 0,
                    "status": "Pendente",
                    "vencimento": DateFormat("yyyy-MM-dd").format(vencimento!),
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
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 80,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(18),
            side: BorderSide(color: corPrincipal, width: 1.2),
          ),
          child: SizedBox(
            width: 700,
            height: 520,
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Container(
                    color: Colors.black,
                    child: TabBar(
                      indicatorColor: corPrincipal,
                      labelColor: corPrincipal,
                      unselectedLabelColor: corPrincipal.withOpacity(0.5),
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
                                  color: corPrincipal,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Clique em 'Enviar Anexo' para carregar arquivos.",
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: corPrincipal.withOpacity(
                                    0.15,
                                  ),
                                  foregroundColor: corPrincipal,
                                  side: BorderSide(color: corPrincipal),
                                ),
                                onPressed: () => _uploadAnexo(id),
                                icon: const Icon(Icons.upload_file),
                                label: const Text("Enviar Anexo"),
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
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            color: corPrincipal,
            onPressed: _abrirFormularioAdicionar,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            color: corPrincipal,
            onPressed: _carregarContas,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ExpansionTile(
                  backgroundColor: Colors.black,
                  collapsedBackgroundColor: Colors.black,
                  iconColor: corPrincipal,
                  collapsedIconColor: corPrincipal,
                  title: Text(
                    "Filtros",
                    style: TextStyle(
                      color: corPrincipal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                                            "yyyy/MM/dd",
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
                                            "yyyy/MM/dd",
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
                                  decoration: InputDecoration(
                                    labelText: "Fornecedor",
                                    labelStyle: TextStyle(color: corPrincipal),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: corPrincipal.withOpacity(0.6),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: corPrincipal,
                                      ),
                                    ),
                                  ),
                                  style: TextStyle(color: corPrincipal),
                                  onChanged: (v) => setState(
                                    () =>
                                        filtroFornecedor = v.isEmpty ? null : v,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: "Categoria",
                                    labelStyle: TextStyle(color: corPrincipal),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: corPrincipal.withOpacity(0.6),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: corPrincipal,
                                      ),
                                    ),
                                  ),
                                  style: TextStyle(color: corPrincipal),
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
                                  decoration: InputDecoration(
                                    labelText: "Status",
                                    labelStyle: TextStyle(color: corPrincipal),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: corPrincipal.withOpacity(0.6),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: corPrincipal,
                                      ),
                                    ),
                                  ),
                                  style: TextStyle(color: corPrincipal),
                                  onChanged: (v) => setState(
                                    () => filtroStatus = v.isEmpty ? null : v,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: "Projeto",
                                    labelStyle: TextStyle(color: corPrincipal),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: corPrincipal.withOpacity(0.6),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: corPrincipal,
                                      ),
                                    ),
                                  ),
                                  style: TextStyle(color: corPrincipal),
                                  onChanged: (v) => setState(
                                    () => filtroProjeto = v.isEmpty ? null : v,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: corPrincipal.withOpacity(0.15),
                              foregroundColor: corPrincipal,
                              side: BorderSide(color: corPrincipal),
                            ),
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
                              color: Colors.black,
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 8,
                              shadowColor: _corStatus(status).withOpacity(0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadiusGeometry.circular(14),
                                side: BorderSide(
                                  color: _corStatus(status),
                                  width: 1.2,
                                ),
                              ),
                              child: ListTile(
                                onTap: () => _abrirDetalhesConta(c),
                                leading: GestureDetector(
                                  onTap: () => _abrirAlterarStatus(
                                    c["id"].toString(),
                                    status,
                                  ),
                                  child: Chip(
                                    elevation: 4,
                                    shadowColor: _corStatus(
                                      status,
                                    ).withOpacity(0.7),
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
                                title: Text(
                                  c["descricao"] ?? "-",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Fornecedor: ${c["fornecedor"] ?? '-'}",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    Text(
                                      "Vencimento: ${c["vencimento"] ?? '-'} • Projeto: ${c["projeto"] ?? '-'}",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  "R\$ ${c["valor"]?.toString() ?? '-'}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
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
            dropdownColor: Colors.black,
            style: TextStyle(color: corPrincipal),
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
            style: TextStyle(color: corPrincipal),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Valor Pago (Opcional)",
              labelStyle: TextStyle(color: corPrincipal),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: corPrincipal.withOpacity(0.6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: corPrincipal),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: corPrincipal.withOpacity(0.15),
              foregroundColor: corPrincipal,
              side: BorderSide(color: corPrincipal),
            ),
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
                style: TextButton.styleFrom(
                  foregroundColor: corPrincipal.withOpacity(0.7),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: corPrincipal.withOpacity(0.15),
                  foregroundColor: corPrincipal,
                  side: BorderSide(color: corPrincipal),
                ),
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
