import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Color corPrincipal = Color(0xFFBBFB04);

class GestaoProjetosPage extends StatefulWidget {
  const GestaoProjetosPage({super.key});

  @override
  State<GestaoProjetosPage> createState() => _GestaoProjetosPageState();
}

class _GestaoProjetosPageState extends State<GestaoProjetosPage> {
  final potenciaCtrl = TextEditingController();
  final valorProjetoCtrl = TextEditingController();
  final valorKitCtrl = TextEditingController();
  final infraCtrl = TextEditingController();
  final instalacaoCtrl = TextEditingController();

  String clienteSelecionado = "Nenhum";
  DateTime? dataProjeto;

  List<String> listaClientes = [
    "Nenhum",
    "Cliente 1",
    "Cliente 2",
    "Cliente 3",
  ];

  double nf = 0;
  double comissaoVendedor = 0;
  double comissaoSupervisor = 0;
  double comissaoGerencia = 0;

  final double custoProjetoFixo = 150.00;
  final double financiamentoFixo = 50.00;
  final double trtFixo = 69.70;
  final double pedidoLigacaoFixo = 200.00;

  List<Map<String, dynamic>> outrosCustos = [];

  @override
  void initState() {
    super.initState();
    valorProjetoCtrl.addListener(_calcularCustos);
    valorKitCtrl.addListener(_calcularCustos);
  }

  void _calcularCustos() {
    double projeto = double.tryParse(valorProjetoCtrl.text) ?? 0;
    double kit = double.tryParse(valorKitCtrl.text) ?? 0;

    setState(() {
      nf = kit * 0.07;
      comissaoVendedor = projeto * 0.04;
      comissaoSupervisor = projeto * 0.015;
      comissaoGerencia = projeto * 0.005;
    });
  }

  InputDecoration _decoracaoCampo(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: corPrincipal),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: corPrincipal),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: corPrincipal, width: 2),
      ),
    );
  }

  ButtonStyle _botaoPadrao() {
    return ElevatedButton.styleFrom(
      backgroundColor: corPrincipal,
      foregroundColor: Colors.black,
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    );
  }

  void _abrirPopupOutrosCustos() {
    final descricaoCtrl = TextEditingController();
    final valorCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "Adicionar Outro Custo",
          style: TextStyle(color: corPrincipal),
        ),

        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(18),
          side: BorderSide(color: corPrincipal, width: 1.2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descricaoCtrl,
              decoration: _decoracaoCampo("Descrição"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valorCtrl,
              keyboardType: TextInputType.number,
              decoration: _decoracaoCampo("Valor (R\$)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: corPrincipal),
            ),
          ),
          ElevatedButton(
            style: _botaoPadrao(),
            onPressed: () {
              double valor = double.tryParse(valorCtrl.text) ?? 0;
              setState(() {
                outrosCustos.add({
                  "descricao": descricaoCtrl.text,
                  "valor": valor,
                });
              });
              Navigator.pop(context);
            },
            child: const Text("Adicionar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestão de Projetos"),
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: _decoracaoCampo("Cliente"),
              value: clienteSelecionado,
              items: listaClientes
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => clienteSelecionado = v!),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              style: _botaoPadrao(),
              onPressed: () async {
                final dt = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (dt != null) setState(() => dataProjeto = dt);
              },
              child: Text(
                dataProjeto == null
                    ? "Selecionar Data do Projeto"
                    : DateFormat('dd/MM/yyyy').format(dataProjeto!),
              ),
            ),

            const SizedBox(height: 16),

            _campo("Potência do Kit", potenciaCtrl),
            _campo("Valor do Projeto (R\$)", valorProjetoCtrl, numero: true),
            _campo("Valor do Kit (R\$)", valorKitCtrl, numero: true),
            _campo("Infra (R\$)", infraCtrl, numero: true),
            _campo("Instalação (R\$)", instalacaoCtrl, numero: true),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              style: _botaoPadrao(),
              onPressed: _abrirPopupOutrosCustos,
              icon: const Icon(Icons.add),
              label: const Text("Adicionar Outros Custos"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: _botaoPadrao(),
              onPressed: _mostrarResumoProjeto,
              child: const Text("Salvar Projeto"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(
    String label,
    TextEditingController ctrl, {
    bool numero = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: numero ? TextInputType.number : TextInputType.text,
        decoration: _decoracaoCampo(label),
      ),
    );
  }

  // =============================================================
  // POPUP DE RESUMO FINANCEIRO
  // =============================================================
  void _mostrarResumoProjeto() {
    if (dataProjeto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Escolha a data do projeto")),
      );
      return;
    }

    // Valores inseridos
    double valorProjeto = double.tryParse(valorProjetoCtrl.text) ?? 0;
    double valorKit = double.tryParse(valorKitCtrl.text) ?? 0;
    double infra = double.tryParse(infraCtrl.text) ?? 0;
    double instalacao = double.tryParse(instalacaoCtrl.text) ?? 0;

    // Soma dos outros custos
    double totalOutrosCustos = outrosCustos.fold(
      0,
      (soma, item) => soma + item["valor"],
    );

    // Soma de custos totais
    double custosTotais =
        nf +
        valorKit +
        comissaoVendedor +
        comissaoSupervisor +
        comissaoGerencia +
        custoProjetoFixo +
        financiamentoFixo +
        trtFixo +
        pedidoLigacaoFixo +
        infra +
        instalacao +
        totalOutrosCustos;

    double lucro = valorProjeto - custosTotais;
    double margem = valorProjeto > 0 ? (lucro / valorProjeto) * 100 : 0;

    Color corResumo = margem < 30 ? Colors.red.shade100 : Colors.green.shade100;
    Color corBorda = margem < 30 ? Colors.red : Colors.green;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ============================================================
                // CARD PROFISSIONAL – RESUMO FINANCEIRO
                // ============================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: corResumo,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: corBorda, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Resumo Financeiro",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: corBorda,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _linhaResumo("Valor do Projeto", valorProjeto),
                      _linhaResumo("Custos Totais", custosTotais),
                      _linhaResumo("Lucro", lucro),
                      Text(
                        "Margem: ${margem.toStringAsFixed(2)}%",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: corBorda,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  "Detalhamento dos Custos",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                _linhaCusto("NF (7%)", nf),
                _linhaCusto("Comissão Vendedor (4%)", comissaoVendedor),
                _linhaCusto("Comissão Supervisor (1,5%)", comissaoSupervisor),
                _linhaCusto("Comissão Gerência (0,5%)", comissaoGerencia),
                _linhaCusto("Projeto (fixo)", custoProjetoFixo),
                _linhaCusto("Financiamento (fixo)", financiamentoFixo),
                _linhaCusto("TRT (fixo)", trtFixo),
                _linhaCusto("Pedido de Ligação (fixo)", pedidoLigacaoFixo),
                _linhaCusto("Infraestrutura", infra),
                _linhaCusto("Instalação", instalacao),

                // Outros custos
                if (outrosCustos.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    "Outros Custos:",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  ...outrosCustos.map(
                    (c) => _linhaCusto(c["descricao"], c["valor"]),
                  ),
                ],

                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Fechar"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _linhaResumo(String nome, double valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        "$nome: R\$ ${valor.toStringAsFixed(2)}",
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _linhaCusto(String nome, double valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(nome), Text("R\$ ${valor.toStringAsFixed(2)}")],
      ),
    );
  }
}
