import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color corPrincipal = Color(0xFFBBFB04);

class ContasVisaoGeralPage extends StatefulWidget {
  const ContasVisaoGeralPage({super.key});

  @override
  State<ContasVisaoGeralPage> createState() => _ContasVisaoGeralPageState();
}

class _ContasVisaoGeralPageState extends State<ContasVisaoGeralPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  late TabController _tab;
  List<Map<String, dynamic>> contas = [];
  bool carregando = true;

  String periodoSelecionado = "atual"; // anteriores | atual | proximos
  String filtroAnteriores = "7"; // 7 | 15 | 30
  DateTimeRange? periodoPersonalizado;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _carregarContas();
  }

  // ===================== BUSCA SUPABASE =====================
  Future<void> _carregarContas() async {
    setState(() => carregando = true);

    try {
      final res = await supabase
          .from('contas_pagar')
          .select()
          .order('vencimento');

      contas = List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint("Erro ao buscar contas: $e");
      contas = [];
    }

    setState(() => carregando = false);
  }

  // ===================== FLUXO DE CAIXA =====================
  Map<String, double> _calcularFluxo() {
    final hoje = DateTime.now();
    double entradas = 0;
    double saidas = 0;

    for (final c in contas) {
      final valor = (c['valor'] as num?)?.toDouble() ?? 0;
      final status = c['status'];
      final vencimento = DateTime.tryParse(c['vencimento'].toString());

      if (periodoSelecionado == "anteriores" &&
          vencimento != null &&
          vencimento.isBefore(hoje)) {
        saidas += valor;
      }

      if (periodoSelecionado == "atual" &&
          vencimento != null &&
          vencimento.month == hoje.month &&
          vencimento.year == hoje.year) {
        saidas += valor;
      }

      if (periodoSelecionado == "proximos" &&
          vencimento != null &&
          vencimento.isAfter(hoje)) {
        saidas += valor;
      }

      if (status == "Pago") {
        entradas += valor;
      }
    }

    return {"entradas": entradas, "saidas": saidas};
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Visão Geral"),
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: corPrincipal,
          labelColor: corPrincipal,
          tabs: const [
            Tab(text: "Resumo"),
            Tab(text: "Vencimentos"),
            Tab(text: "Fluxo de Caixa"),
          ],
        ),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [_buildResumo(), _buildVencimentos(), _buildFluxo()],
            ),
    );
  }

  // ===================== RESUMO =====================
  Widget _buildResumo() {
    double pagos = 0, pendentes = 0, atrasados = 0;
    final hoje = DateTime.now();

    for (final c in contas) {
      final valor = (c['valor'] as num?)?.toDouble() ?? 0;
      final status = c['status'];
      final venc = DateTime.tryParse(c['vencimento'].toString());

      if (status == "Pago") {
        pagos += valor;
      } else if (venc != null && venc.isBefore(hoje)) {
        atrasados += valor;
      } else {
        pendentes += valor;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _card("Pagos", pagos, Colors.green),
          _card("Pendentes", pendentes, Colors.orange),
          _card("Atrasados", atrasados, Colors.red),
        ],
      ),
    );
  }

  // ===================== VENCIMENTOS =====================
  Widget _buildVencimentos() {
    final hoje = DateTime.now();

    final pendentes = contas.where((c) {
      final venc = DateTime.tryParse(c['vencimento'].toString());
      return c['status'] != "Pago" && venc != null && venc.isBefore(hoje);
    }).toList();

    if (pendentes.isEmpty) {
      return const Center(
        child: Text(
          "Nenhuma conta pendente",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendentes.length,
      itemBuilder: (_, i) {
        final c = pendentes[i];
        return Card(
          color: Colors.black,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: corPrincipal),
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            title: Text(
              c['descricao'],
              style: const TextStyle(color: corPrincipal),
            ),
            subtitle: Text(
              "Vencimento: ${c['vencimento']}",
              style: TextStyle(color: corPrincipal.withOpacity(0.7)),
            ),
            trailing: Text(
              "R\$ ${c['valor']}",
              style: const TextStyle(
                color: corPrincipal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  // ===================== FLUXO =====================
  Widget _buildFluxo() {
    final fluxo = _calcularFluxo();
    final saldo = fluxo['entradas']! - fluxo['saidas']!;

    return Column(
      children: [
        _menuFluxo(),
        _card("Entradas", fluxo['entradas']!, corPrincipal),
        _card("Saídas", fluxo['saidas']!, Colors.red),
        _card("Saldo", saldo, saldo >= 0 ? Colors.green : Colors.red),
      ],
    );
  }

  Widget _menuFluxo() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _botaoPeriodo("Anteriores", "anteriores"),
          _botaoPeriodo("Atual", "atual"),
          _botaoPeriodo("Próximos", "proximos"),
        ],
      ),
    );
  }

  Widget _botaoPeriodo(String titulo, String valor) {
    final ativo = periodoSelecionado == valor;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: ativo ? corPrincipal.withOpacity(0.15) : Colors.black,
        foregroundColor: corPrincipal,
        side: BorderSide(color: corPrincipal),
      ),
      onPressed: () => setState(() => periodoSelecionado = valor),
      child: Text(titulo),
    );
  }

  Widget _card(String titulo, double valor, Color cor) {
    return Card(
      color: Colors.black,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        title: Text(titulo, style: TextStyle(color: cor)),
        trailing: Text(
          "R\$ ${valor.toStringAsFixed(2)}",
          style: TextStyle(
            color: cor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
