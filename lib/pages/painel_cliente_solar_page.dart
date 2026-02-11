import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const Color corPrincipal = Color(0xFFBBFB04);
const Color fundoPreto = Colors.black;
const Color cardPreto = Color.fromARGB(255, 20, 20, 20);

final supabase = Supabase.instance.client;

class PainelSolarClientePage extends StatefulWidget {
  final String clienteId;
  final String nomeCliente;

  const PainelSolarClientePage({
    super.key,
    required this.clienteId,
    required this.nomeCliente,
  });

  @override
  State<PainelSolarClientePage> createState() => _PainelSolarClientePageState();
}

class _PainelSolarClientePageState extends State<PainelSolarClientePage>
    with SingleTickerProviderStateMixin {
  bool carregando = true;

  double gerado = 0;
  double consumido = 0;
  double economia = 0;

  List<Map<String, dynamic>> historico = [];
  List<Map<String, dynamic>> faturas = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    carregarDados();
  }

  Future<void> carregarDados() async {
    setState(() => carregando = true);

    try {
      final energia = await supabase
          .from('usinas_solares')
          .select()
          .eq('cliente_id', widget.clienteId);

      historico = List<Map<String, dynamic>>.from(energia);

      gerado = historico.fold(0, (s, e) => s + (e['energia_gerada'] ?? 0));

      consumido = historico.fold(
        0,
        (s, e) => s + (e['energia_consumida'] ?? 0),
      );

      economia = gerado * 0.92;

      final fat = await supabase
          .from('faturas_energia')
          .select()
          .eq('cliente_id', widget.clienteId)
          .order('mes', ascending: false);

      faturas = List<Map<String, dynamic>>.from(fat);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }

    setState(() => carregando = false);
  }

  // ================= PDF =================

  Future<void> exportarPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Relatório Solar", style: pw.TextStyle(fontSize: 22)),
            pw.SizedBox(height: 10),
            pw.Text("Cliente: ${widget.nomeCliente}"),
            pw.Text("Energia gerada: ${gerado.toStringAsFixed(1)} kWh"),
            pw.Text("Energia consumida: ${consumido.toStringAsFixed(1)} kWh"),
            pw.Text("Economia estimada: R\$ ${economia.toStringAsFixed(2)}"),

            pw.SizedBox(height: 20),
            pw.Text("Histórico mensal:"),

            ...historico.map(
              (e) => pw.Text(
                "${e['mes']} - Gerado: ${e['energia_gerada']} kWh | "
                "Consumido: ${e['energia_consumida']} kWh",
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundoPreto,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
        title: Text(widget.nomeCliente),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: exportarPDF,
          ),
        ],
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [_cardsResumo(), _tabsHistorico()]),
    );
  }

  // ================= CARDS =================

  Widget _cardsResumo() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _card("Gerado", "$gerado kWh"),
          _card("Consumido", "$consumido kWh"),
          _card("Economia", "R\$ ${economia.toStringAsFixed(0)}"),
        ],
      ),
    );
  }

  Widget _card(String titulo, String valor) {
    return Expanded(
      child: Card(
        color: cardPreto,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                valor,
                style: const TextStyle(color: corPrincipal, fontSize: 18),
              ),
              Text(titulo, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  // ================= TABS =================

  Widget _tabsHistorico() {
    return Expanded(
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: corPrincipal,
            labelColor: corPrincipal,
            tabs: const [
              Tab(text: "Histórico"),
              Tab(text: "Faturas"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_historicoGeracao(), _faturasEnergia()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _historicoGeracao() {
    return ListView.builder(
      itemCount: historico.length,
      itemBuilder: (_, i) {
        final h = historico[i];

        return ListTile(
          title: Text(h['mes'], style: const TextStyle(color: corPrincipal)),
          subtitle: Text(
            "Gerado: ${h['energia_gerada']} kWh | "
            "Consumido: ${h['energia_consumida']} kWh",
            style: const TextStyle(color: Colors.white70),
          ),
        );
      },
    );
  }

  Widget _faturasEnergia() {
    return ListView.builder(
      itemCount: faturas.length,
      itemBuilder: (_, i) {
        final f = faturas[i];

        return ListTile(
          title: Text(f['mes'], style: const TextStyle(color: corPrincipal)),
          subtitle: Text(
            "Valor: R\$ ${f['valor']} | Consumo: ${f['consumo']} kWh",
            style: const TextStyle(color: Colors.white70),
          ),
        );
      },
    );
  }
}
