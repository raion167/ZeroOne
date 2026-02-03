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
    await supabase
        .from('contas_pagar')
        .update({
          'status': 'Pago',
          'metodo_pagamento': metodo,
          'data_pagamento': dataPagamento.toIso8601String(),
          if (valorPago != null) 'valor_pago': valorPago,
        })
        .eq('id', id)
        .eq('user_id', userId);

    _carregarContas();
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
                    onTap: () => _uploadAnexo(c['id']),
                  ),
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
        title: const Text('Nova Conta', style: TextStyle(color: corPrincipal)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descricao,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            TextField(
              controller: valor,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Valor'),
            ),
            DropdownButtonFormField(
              items: listaProjetos
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => projeto = v,
              decoration: const InputDecoration(labelText: 'Projeto'),
            ),
            ElevatedButton(
              onPressed: () async {
                vencimento = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  initialDate: DateTime.now(),
                );
              },
              child: const Text('Selecionar Vencimento'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
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
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
