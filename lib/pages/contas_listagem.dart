import 'dart:ui'; // Necessário para o ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color corPrincipal = Color(0xFFBBFB04);

final supabase = Supabase.instance.client;

class ContasListagemPage extends StatefulWidget {
  const ContasListagemPage({super.key});

  @override
  State<ContasListagemPage> createState() => _ContasListagemPageState();
}

class _ContasListagemPageState extends State<ContasListagemPage> {
  bool loading = true;

  List<Map<String, dynamic>> contas = [];
  List<Map<String, dynamic>> contasFiltradas = [];
  List<String> listaProjetos = [];

  DateTime? dataInicial;
  DateTime? dataFinal;
  String? filtroFornecedor;
  String? filtroStatus;
  String? filtroCategoria;
  String? filtroProjeto;

  String get userId => supabase.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _carregarTudo();
  }

  Future<void> _carregarTudo() async {
    await Future.wait([_carregarProjetos(), _carregarContas()]);
  }

  // ================= PROJETOS =================
  Future<void> _carregarProjetos() async {
    final res = await supabase
        .from('projetos')
        .select('nome')
        .eq('user_id', userId);

    setState(() {
      listaProjetos = res.map<String>((p) => p['nome'].toString()).toList();
    });
  }

  // ================= CONTAS =================
  Future<void> _carregarContas() async {
    setState(() => loading = true);

    final res = await supabase
        .from('contas_pagar')
        .select()
        .eq('user_id', userId)
        .order('vencimento');

    contas = List<Map<String, dynamic>>.from(res);
    contasFiltradas = List.from(contas);

    setState(() => loading = false);
  }

  // ================= INSERT =================
  Future<void> _adicionarContas(List<Map<String, dynamic>> listaContas) async {
    final dadosParaInserir = listaContas
        .map((conta) => {...conta, 'user_id': userId})
        .toList();

    await supabase.from('contas_pagar').insert(dadosParaInserir);

    Navigator.pop(context);
    _carregarContas();
  }

  // ================= UPDATE STATUS =================
  Future<void> _alterarStatus(String id, String status) async {
    await supabase
        .from('contas_pagar')
        .update({'status': status})
        .eq('id', id)
        .eq('user_id', userId);

    _carregarContas();
  }

  // ================= PAGAMENTO =================
  Future<void> _registrarPagamento(
    String id,
    String metodo,
    DateTime dataPagamento,
    double? valorPago,
  ) async {
    try {
      await supabase
          .from('contas_pagar')
          .update({
            'status': 'Pago',
            'metodo_pagamento': metodo,
            'data_pagamento': dataPagamento.toIso8601String(),
            if (valorPago != null) 'valor_pago': valorPago,
          })
          .eq('id', id);

      _carregarContas();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pagamento registrado')));
    } catch (e) {
      print(e);
    }
  }

  // ================= UPLOAD =================
  Future<void> _uploadAnexo(String contaId) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;

    for (final f in result.files) {
      await supabase.storage
          .from('anexos-contas')
          .uploadBinary(
            '$userId/$contaId/${f.name}',
            f.bytes!,
            fileOptions: const FileOptions(upsert: true),
          );
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Anexo enviado com sucesso')));
  }

  // ================= FILTROS =================
  void aplicarFiltros() {
    contasFiltradas = contas.where((c) {
      final venc = DateTime.parse(c['vencimento']);

      if (dataInicial != null && venc.isBefore(dataInicial!)) return false;
      if (dataFinal != null && venc.isAfter(dataFinal!)) return false;
      if (filtroStatus != null && c['status'] != filtroStatus) return false;
      if (filtroProjeto != null && c['projeto'] != filtroProjeto) return false;

      return true;
    }).toList();

    setState(() {});
  }

  // ================= UI HELPERS =================
  Color _corStatus(String status) {
    switch (status) {
      case 'Pago':
        return Colors.green;
      case 'Atrasado':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _iconStatus(String status) {
    switch (status) {
      case 'Pago':
        return Icons.check_circle;
      case 'Atrasado':
        return Icons.error;
      default:
        return Icons.schedule;
    }
  }

  // ================= BUILD LISTAGEM =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Contas a Pagar'),
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _abrirFormulario),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarContas,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: corPrincipal))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: contasFiltradas.length,
              itemBuilder: (context, i) {
                final c = contasFiltradas[i];
                final status = c['status'];

                return Card(
                  color: Colors.black,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: _corStatus(status)),
                  ),
                  child: ListTile(
                    leading: Chip(
                      backgroundColor: _corStatus(status),
                      avatar: Icon(_iconStatus(status), color: Colors.white),
                      label: Text(
                        status,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      c['descricao'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Vencimento: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(c['vencimento']))}',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                    trailing: Text(
                      'R\$ ${double.tryParse(c['valor'].toString())?.toStringAsFixed(2) ?? c['valor']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => _abrirPagamento(c),
                  ),
                );
              },
            ),
    );
  }

  void _abrirPagamento(Map<String, dynamic> conta) {
    String? metodo;
    final valorPago = TextEditingController();
    final parcelas = TextEditingController(text: '1');
    DateTime dataPagamento = DateTime.now();
    PlatformFile? comprovante;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          double valor = double.tryParse(valorPago.text) ?? 0;
          int qtdParcelas = int.tryParse(parcelas.text) ?? 1;
          double valorParcela = qtdParcelas > 0 ? valor / qtdParcelas : valor;

          return AlertDialog(
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: corPrincipal),
            ),
            title: const Text(
              'Registrar Pagamento',
              style: TextStyle(color: corPrincipal),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    conta['descricao'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.black,
                    style: const TextStyle(color: Colors.white),
                    value: metodo,
                    items: const [
                      DropdownMenuItem(
                        value: 'Pix',
                        child: Row(
                          children: [
                            Icon(Icons.flash_on, color: corPrincipal),
                            SizedBox(width: 8),
                            Text('Pix'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Credito',
                        child: Row(
                          children: [
                            Icon(Icons.credit_card, color: corPrincipal),
                            SizedBox(width: 8),
                            Text('Crédito'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Debito',
                        child: Row(
                          children: [
                            Icon(Icons.credit_card, color: corPrincipal),
                            SizedBox(width: 8),
                            Text('Débito'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'A vista',
                        child: Row(
                          children: [
                            Icon(Icons.attach_money, color: corPrincipal),
                            SizedBox(width: 8),
                            Text('À vista'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (v) => setModalState(() => metodo = v),
                    decoration: InputDecoration(
                      labelText: 'Método pagamento',
                      labelStyle: const TextStyle(color: corPrincipal),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: corPrincipal),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: valorPago,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Valor pago',
                      labelStyle: TextStyle(color: corPrincipal),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),

                  if (metodo == 'Credito') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: parcelas,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Parcelas',
                        labelStyle: TextStyle(color: corPrincipal),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Valor parcela: R\$ ${valorParcela.toStringAsFixed(2)}',
                      style: const TextStyle(color: corPrincipal),
                    ),
                  ],

                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: corPrincipal,
                      side: const BorderSide(color: corPrincipal),
                    ),
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Selecionar data pagamento'),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        initialDate: DateTime.now(),
                      );
                      if (d != null) {
                        setModalState(() => dataPagamento = d);
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: corPrincipal,
                      side: const BorderSide(color: corPrincipal),
                    ),
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      comprovante == null
                          ? 'Anexar comprovante'
                          : comprovante!.name,
                    ),
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        withData: true,
                      );
                      if (result != null) {
                        setModalState(() => comprovante = result.files.first);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: corPrincipal,
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  if (metodo == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Selecione método pagamento'),
                      ),
                    );
                    return;
                  }

                  await _registrarPagamento(
                    conta['id'].toString(),
                    metodo!,
                    dataPagamento,
                    double.tryParse(valorPago.text),
                  );

                  if (comprovante != null) {
                    await supabase.storage
                        .from('anexos-contas')
                        .uploadBinary(
                          '$userId/${conta['id']}/${comprovante!.name}',
                          comprovante!.bytes!,
                          fileOptions: const FileOptions(upsert: true),
                        );
                  }

                  Navigator.pop(context);
                },
                child: const Text('Salvar pagamento'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ================= FORM NOVO MODIFICADO =================
  void _abrirFormulario() {
    final descricaoController = TextEditingController();
    final valorController = TextEditingController();
    final jurosController = TextEditingController(text: "0.0");

    String? projetoSelecionado;
    DateTime? dataVencimento;

    bool temRecorrencia = false;
    bool relacionarProjeto = false;
    int quantidadeParcelas = 2;

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          double valorBaseTotal = double.tryParse(valorController.text) ?? 0.0;
          double taxaJuros = double.tryParse(jurosController.text) ?? 0.0;

          // Valor de cada parcela dividida igualmente
          double valorBaseParcela = temRecorrencia
              ? (valorBaseTotal / quantidadeParcelas)
              : valorBaseTotal;

          // Cálculo dos juros fixos adicionados diretamente sobre a parcela (ex: R$ 100 + 5% = R$ 105 em todas)
          double valorParcelaComJuros =
              valorBaseParcela * (1 + (taxaJuros / 100));

          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
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
              child: Column(
                children: [
                  const Text(
                    "Nova Conta a Pagar",
                    style: TextStyle(
                      color: corPrincipal,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _campoData(
                            label: "Data de Vencimento",
                            data: dataVencimento,
                            onSelect: (d) =>
                                setModalState(() => dataVencimento = d),
                          ),
                          const SizedBox(height: 12),

                          _campoTexto(
                            descricaoController,
                            "Descrição",
                            false,
                            onChanged: (_) => setModalState(() {}),
                          ),

                          _campoTexto(
                            valorController,
                            "Valor Total",
                            true,
                            onChanged: (_) => setModalState(() {}),
                          ),

                          Theme(
                            data: ThemeData(
                              unselectedWidgetColor: corPrincipal,
                            ),
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                "Clique aqui para relacionar essa conta a um projeto",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              activeColor: corPrincipal,
                              activeTrackColor: corPrincipal.withOpacity(0.3),
                              value: relacionarProjeto,
                              onChanged: (bool value) {
                                setModalState(() {
                                  relacionarProjeto = value;
                                  if (!value) projetoSelecionado = null;
                                });
                              },
                            ),
                          ),

                          if (relacionarProjeto) ...[
                            _dropdown(
                              "Projeto",
                              listaProjetos,
                              projetoSelecionado,
                              (v) =>
                                  setModalState(() => projetoSelecionado = v),
                            ),
                            const SizedBox(height: 8),
                          ],

                          Theme(
                            data: ThemeData(
                              unselectedWidgetColor: corPrincipal,
                            ),
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                "Conta Recorrente / Parcelada",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              activeColor: corPrincipal,
                              activeTrackColor: corPrincipal.withOpacity(0.3),
                              value: temRecorrencia,
                              onChanged: (bool value) {
                                setModalState(() {
                                  temRecorrencia = value;
                                });
                              },
                            ),
                          ),

                          if (temRecorrencia) ...[
                            _dropdownInt(
                              "Quantidade de Meses / Parcelas",
                              List.generate(11, (index) => index + 2),
                              quantidadeParcelas,
                              (v) => setModalState(
                                () => quantidadeParcelas = v ?? 2,
                              ),
                            ),

                            _campoTexto(
                              jurosController,
                              "Juros Mensal (%)",
                              true,
                              onChanged: (_) => setModalState(() {}),
                            ),

                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: corPrincipal.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Simulação das Parcelas:",
                                    style: TextStyle(
                                      color: corPrincipal,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  ...List.generate(quantidadeParcelas, (i) {
                                    // Todas as parcelas agora utilizam o mesmo 'valorParcelaComJuros' de forma estável
                                    String dataExibicao = "Selecione a data";
                                    if (dataVencimento != null) {
                                      DateTime dataDaParcela = DateTime(
                                        dataVencimento!.year,
                                        dataVencimento!.month + i,
                                        dataVencimento!.day,
                                      );
                                      if (dataDaParcela.day !=
                                          dataVencimento!.day) {
                                        dataDaParcela = DateTime(
                                          dataVencimento!.year,
                                          dataVencimento!.month + i + 1,
                                          0,
                                        );
                                      }
                                      dataExibicao = DateFormat(
                                        "dd/MM/yyyy",
                                      ).format(dataDaParcela);
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Parcela ${i + 1}/$quantidadeParcelas:",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            "$dataExibicao  ->  R\$ ${valorParcelaComJuros.toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              color: corPrincipal,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (descricaoController.text.isEmpty ||
                            valorController.text.isEmpty ||
                            dataVencimento == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Por favor, preencha todos os campos obrigatórios.',
                              ),
                            ),
                          );
                          return;
                        }

                        List<Map<String, dynamic>> contasParaSalvar = [];

                        if (temRecorrencia) {
                          for (int i = 0; i < quantidadeParcelas; i++) {
                            DateTime dataDaParcela = DateTime(
                              dataVencimento!.year,
                              dataVencimento!.month + i,
                              dataVencimento!.day,
                            );

                            if (dataDaParcela.day != dataVencimento!.day) {
                              dataDaParcela = DateTime(
                                dataVencimento!.year,
                                dataVencimento!.month + i + 1,
                                0,
                              );
                            }

                            contasParaSalvar.add({
                              'descricao':
                                  "${descricaoController.text} (${i + 1}/$quantidadeParcelas)",
                              'valor': double.parse(
                                valorParcelaComJuros.toStringAsFixed(2),
                              ),
                              'projeto': relacionarProjeto
                                  ? projetoSelecionado
                                  : null,
                              'vencimento': dataDaParcela.toIso8601String(),
                              'status': 'Pendente',
                            });
                          }
                        } else {
                          contasParaSalvar.add({
                            'descricao': descricaoController.text,
                            'valor': valorBaseTotal,
                            'projeto': relacionarProjeto
                                ? projetoSelecionado
                                : null,
                            'vencimento': dataVencimento!.toIso8601String(),
                            'status': 'Pendente',
                          });
                        }

                        await _adicionarContas(contasParaSalvar);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: corPrincipal,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(160, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Salvar Conta",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= CAMPOS AUXILIARES PADRONIZADOS =================
  Widget _campoTexto(
    TextEditingController c,
    String label,
    bool numero, {
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        onChanged: onChanged,
        keyboardType: numero
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        cursorColor: corPrincipal,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: corPrincipal),
          floatingLabelStyle: const TextStyle(color: corPrincipal),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: corPrincipal),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: corPrincipal, width: 2),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        dropdownColor: Colors.black,
        value: value,
        hint: Text(
          label,
          style: TextStyle(color: corPrincipal.withOpacity(0.6)),
        ),
        iconEnabledColor: corPrincipal,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: corPrincipal),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: corPrincipal, width: 2),
          ),
        ),
        items: items
            .map(
              (c) => DropdownMenuItem(
                value: c,
                child: Text(c, style: const TextStyle(color: Colors.white)),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _dropdownInt(
    String label,
    List<int> items,
    int value,
    ValueChanged<int?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        dropdownColor: Colors.black,
        value: value,
        iconEnabledColor: corPrincipal,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: corPrincipal),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: corPrincipal),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: corPrincipal, width: 2),
          ),
        ),
        items: items
            .map(
              (c) => DropdownMenuItem<int>(
                value: c,
                child: Text(
                  "$c Meses (Vezes)",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _campoData({
    required String label,
    required DateTime? data,
    required Function(DateTime) onSelect,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
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
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: corPrincipal,
                  onPrimary: Colors.black,
                  surface: Colors.black,
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (d != null) onSelect(d);
      },
    );
  }
}
