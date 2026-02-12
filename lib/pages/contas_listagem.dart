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
  Future<void> _adicionarConta(Map<String, dynamic> conta) async {
    await supabase.from('contas_pagar').insert({...conta, 'user_id': userId});

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

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          ? const Center(child: CircularProgressIndicator())
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
                      'R\$ ${c['valor']}',
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

                  // ===== MÉTODO PAGAMENTO COM ÍCONE =====
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

                  // ===== VALOR =====
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

                  // ===== PARCELAMENTO AUTOMÁTICO =====
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

                  // ===== DATA PAGAMENTO =====
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

                  // ===== ANEXAR COMPROVANTE =====
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
                      final result = await FilePicker.platform.pickFiles();
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

                  // ===== UPLOAD COMPROVANTE =====
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
                          double valorParcela = qtdParcelas > 0
                              ? valor / qtdParcelas
                              : valor;

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

                                  // ===== MÉTODO PAGAMENTO COM ÍCONE =====
                                  DropdownButtonFormField<String>(
                                    dropdownColor: Colors.black,
                                    style: const TextStyle(color: Colors.white),
                                    value: metodo,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Pix',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.flash_on,
                                              color: corPrincipal,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Pix'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Credito',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.credit_card,
                                              color: corPrincipal,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Crédito'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Debito',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.credit_card,
                                              color: corPrincipal,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Débito'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'A vista',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.attach_money,
                                              color: corPrincipal,
                                            ),
                                            SizedBox(width: 8),
                                            Text('À vista'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setModalState(() => metodo = v),
                                    decoration: InputDecoration(
                                      labelText: 'Método pagamento',
                                      labelStyle: const TextStyle(
                                        color: corPrincipal,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: corPrincipal,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // ===== VALOR =====
                                  TextField(
                                    controller: valorPago,
                                    style: const TextStyle(color: Colors.white),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Valor pago',
                                      labelStyle: TextStyle(
                                        color: corPrincipal,
                                      ),
                                    ),
                                    onChanged: (_) => setModalState(() {}),
                                  ),

                                  // ===== PARCELAMENTO AUTOMÁTICO =====
                                  if (metodo == 'Credito') ...[
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: parcelas,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: 'Parcelas',
                                        labelStyle: TextStyle(
                                          color: corPrincipal,
                                        ),
                                      ),
                                      onChanged: (_) => setModalState(() {}),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Valor parcela: R\$ ${valorParcela.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: corPrincipal,
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 16),

                                  // ===== DATA PAGAMENTO =====
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: corPrincipal,
                                      side: const BorderSide(
                                        color: corPrincipal,
                                      ),
                                    ),
                                    icon: const Icon(Icons.calendar_month),
                                    label: const Text(
                                      'Selecionar data pagamento',
                                    ),
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

                                  // ===== ANEXAR COMPROVANTE =====
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: corPrincipal,
                                      side: const BorderSide(
                                        color: corPrincipal,
                                      ),
                                    ),
                                    icon: const Icon(Icons.attach_file),
                                    label: Text(
                                      comprovante == null
                                          ? 'Anexar comprovante'
                                          : comprovante!.name,
                                    ),
                                    onPressed: () async {
                                      final result = await FilePicker.platform
                                          .pickFiles(withData: true);
                                      if (result != null) {
                                        setModalState(
                                          () =>
                                              comprovante = result.files.first,
                                        );
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
                                        content: Text(
                                          'Selecione método pagamento',
                                        ),
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

                                  // ===== UPLOAD COMPROVANTE =====
                                  if (comprovante != null) {
                                    await supabase.storage
                                        .from('anexos-contas')
                                        .uploadBinary(
                                          '$userId/${conta['id']}/${comprovante!.name}',
                                          comprovante!.bytes!,
                                          fileOptions: const FileOptions(
                                            upsert: true,
                                          ),
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

  // ================= FORM =================
  void _abrirFormulario() {
    final descricao = TextEditingController();
    final valor = TextEditingController();
    String? projeto;
    DateTime? vencimento;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: corPrincipal, width: 1.5),
        ),
        title: const Text(
          'Nova Conta',
          style: TextStyle(color: corPrincipal, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descricao,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Descrição',
                labelStyle: const TextStyle(color: corPrincipal),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: corPrincipal),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: corPrincipal, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valor,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Valor',
                labelStyle: const TextStyle(color: corPrincipal),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: corPrincipal),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: corPrincipal, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              items: listaProjetos
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => projeto = v,
              decoration: InputDecoration(
                labelText: 'Projeto',
                labelStyle: const TextStyle(color: corPrincipal),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: corPrincipal),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // BOTÃO VENCIMENTO NEON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: corPrincipal,
                  side: const BorderSide(color: corPrincipal),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  vencimento == null
                      ? 'Selecionar vencimento'
                      : DateFormat('dd/MM/yyyy').format(vencimento!),
                ),
                onPressed: () async {
                  vencimento = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDate: DateTime.now(),
                  );
                  setState(() {});
                },
              ),
            ),
          ],
        ),

        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),

        actions: [
          // CANCELAR
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),

          // SALVAR NEON
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: corPrincipal,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              if (vencimento == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Selecione o vencimento')),
                );
                return;
              }

              _adicionarConta({
                'descricao': descricao.text,
                'valor': double.tryParse(valor.text) ?? 0,
                'projeto': projeto,
                'status': 'Pendente',
                'vencimento': vencimento!.toIso8601String(),
              });
            },
            child: const Text(
              'Salvar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
