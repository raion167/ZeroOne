import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const Color corPrincipal = Color(0xFFBBFB04);

class ContasVisaoGeralPage extends StatefulWidget {
  const ContasVisaoGeralPage({super.key});

  @override
  State<ContasVisaoGeralPage> createState() => _ContasVisaoGeralPageState();
}

class _ContasVisaoGeralPageState extends State<ContasVisaoGeralPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<dynamic> contas = [];
  bool carregando = true;

  String periodoSelecionado = "atual"; // anteriores, atual, proximos
  String filtroAnteriores = "7"; // 7, 15, 30, personalizado
  DateTimeRange? periodoPersonalizado;
  Future<Map<String, dynamic>>? _futureFluxo;

  final String baseUrl = "http://localhost:8080/app"; // Altere se necessário

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    carregarDadosFinanceiros();
    _futureFluxo = _carregarFluxoCaixa();
  }

  // CARREGANDO OS DADOS DAS CONTAS A PAGAR
  Future<void> carregarDadosFinanceiros() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/contas_pagar_listagem.php"),
      );
      //debugPrint("Resposta do backend: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (data is List) {
            contas = data;
          } else if (data is Map && data["contas"] is List) {
            contas = data["contas"];
          } else {
            contas = [];
          }
          carregando = false;
        });
      } else {
        throw Exception("Erro ao carregar contas");
      }
    } catch (e) {
      debugPrint("Erro: $e");
      setState(() => carregando = false);
    }
  }

  // FLUXO DE CAIXA
  Future<Map<String, dynamic>> _carregarFluxoCaixa() async {
    try {
      final body = {
        "periodo": periodoSelecionado, // ANTERIOR, ATUAL, PROXIMOS
        "filtro_anteriores": filtroAnteriores, // 7, 15, 30 DIAS / PERSONALIZADO
      };

      // SE FOR PERIODO PERSONALIZADO
      if (filtroAnteriores == "personalizado" && periodoPersonalizado != null) {
        body.addAll({
          "data_inicio": periodoPersonalizado!.start.toIso8601String(),
          "data_fim": periodoPersonalizado!.end.toIso8601String(),
        });
      }

      final response = await http.post(
        Uri.parse("$baseUrl/fluxo_caixa.php"),
        body: body,
      );

      if (response.statusCode == 200) {
        final dados = json.decode(response.body);

        return {
          "entradas": (double.tryParse(dados["entradas"].toString()) ?? 0),
          "saidas": (double.tryParse(dados["saidas"].toString()) ?? 0),
        };
      } else {
        return {"entradas": 0, "saidas": 0};
      }
    } catch (e) {
      debugPrint("Erro no fluxo de caixa: $e");
      return {"entradas": 0, "saidas": 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Visão Geral"),
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
        elevation: 0,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: corPrincipal,
          labelColor: corPrincipal,
          unselectedLabelColor: corPrincipal.withOpacity(0.5),
          tabs: const [
            Tab(text: "Resumo Financeiro", icon: Icon(Icons.pie_chart_outline)),
            Tab(text: "Vencimentos", icon: Icon(Icons.event_outlined)),
            Tab(text: "Fluxo de Caixa", icon: Icon(Icons.bar_chart_outlined)),
          ],
        ),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _buildResumoFinanceiro(),
                _buildVencimentos(),
                _buildFluxoCaixaPrevisto(),
              ],
            ),
    );
  }

  // ✅ Aba 1 - Resumo Financeiro
  Widget _buildResumoFinanceiro() {
    double pagos = 0, pendentes = 0, atrasados = 0;

    final hoje = DateTime.now();
    final dataHoje = DateTime(hoje.year, hoje.month, hoje.day);

    for (var c in contas) {
      double valor = double.tryParse(c["valor"].toString()) ?? 0;
      String status = c["status"].toString();

      // Normalizar data do vencimento
      DateTime vencimentoBruto =
          DateTime.tryParse(c["data_vencimento"].toString()) ?? hoje;

      DateTime vencimento = DateTime(
        vencimentoBruto.year,
        vencimentoBruto.month,
        vencimentoBruto.day,
      );

      if (status == "Pago") {
        pagos += valor;
      } else if (status == "Atrasado") {
        atrasados += valor;
      } else if (status == "Pendente") {
        if (vencimento.isBefore(dataHoje)) {
          atrasados += valor;
        } else {
          pendentes += valor;
        }
      }
    }

    double total = pendentes + atrasados;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Resumo Financeiro",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: corPrincipal,
            ),
          ),
          const SizedBox(height: 20),
          _cardResumo(
            "Pagos",
            "R\$ ${pagos.toStringAsFixed(2)}",
            Colors.blueAccent,
          ),
          _cardResumo(
            "Pendentes",
            "R\$ ${pendentes.toStringAsFixed(2)}",
            Colors.amberAccent,
          ),
          _cardResumo(
            "Atrasados",
            "R\$ ${atrasados.toStringAsFixed(2)}",
            Colors.red,
          ),
          _cardResumo(
            "Total a pagar",
            "R\$ ${total.toStringAsFixed(2)}",
            corPrincipal,
          ),
        ],
      ),
    );
  }

  // ✅ Aba 2 - Vencimentos
  Widget _buildVencimentos() {
    final hoje = DateTime.now();

    final contasPendentesEAtrasadas = contas.where((c) {
      String status = c["status"].toString();
      if (status == "Pendente") return true;

      if (status == "Atrasado") {
        DateTime venc = DateTime.tryParse(c["vencimento"].toString()) ?? hoje;
        return venc.isBefore(hoje);
      }
      return false;
    }).toList();

    if (contasPendentesEAtrasadas.isEmpty) {
      return const Center(child: Text("Nenhuma conta pendente ou atrasada."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: contasPendentesEAtrasadas.length,
      itemBuilder: (context, index) {
        final conta = contasPendentesEAtrasadas[index];
        DateTime venc =
            DateTime.tryParse(conta["vencimento"].toString()) ?? hoje;
        bool atrasada = venc.isBefore(DateTime.now());
        return Card(
          color: Colors.black,
          elevation: 6,
          shadowColor: corPrincipal.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: corPrincipal, width: 1.2),
          ),
          child: ListTile(
            leading: Icon(
              atrasada ? Icons.warning_amber_rounded : Icons.info_outline,
              color: corPrincipal,
            ),
            title: Text(
              conta["descricao"].toString(),
              style: TextStyle(color: corPrincipal),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Fornecedor: ${conta["fornecedor"] ?? "Não Informado"}",
                  style: TextStyle(color: corPrincipal.withOpacity(0.7)),
                ),
                Text(
                  "Vencimento: ${venc.day}/${venc.month}/${venc.year}",
                  style: TextStyle(color: corPrincipal.withOpacity(0.7)),
                ),
              ],
            ),
            trailing: Text(
              "R\$ ${conta["valor"]}",
              style: TextStyle(
                color: corPrincipal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ Aba 3 - Fluxo de Caixa
  Widget _buildFluxoCaixaPrevisto() {
    return Column(
      children: [
        _buildMenuFluxo(),
        if (periodoSelecionado == "anteriores") _buildSubmenuAnteriores(),
        Expanded(
          child: FutureBuilder(
            future: _futureFluxo,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData) {
                return const Center(child: Text("Sem dados disponíveis."));
              }

              final dados = snapshot.data!;
              double entradas = dados["entradas"];
              double saidas = dados["saidas"];
              double saldo = entradas - saidas;

              final List<Map<String, dynamic>> itens = [
                {
                  "icone": Icons.arrow_downward,
                  "titulo": "Entradas",
                  "valor": entradas,
                  "cor": corPrincipal,
                  "descricao": "Valores recebidos no período",
                },
                {
                  "icone": Icons.arrow_upward,
                  "titulo": "Saídas",
                  "valor": saidas,
                  "cor": Colors.redAccent,
                  "descricao": "Despesas registradas no período",
                },
                {
                  "icone": Icons.account_balance_wallet,
                  "titulo": "Saldo Previsto",
                  "valor": saldo,
                  "cor": saldo >= 0 ? Colors.blue : Colors.redAccent,
                  "descricao": "Resultado financeiro do período",
                },
              ];

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: itens.length,
                itemBuilder: (context, index) {
                  final item = itens[index];
                  return Card(
                    color: Colors.black,
                    elevation: 8,
                    shadowColor: item["cor"].withOpacity(0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: item["cor"], width: 1.6),
                    ),
                    child: ListTile(
                      leading: Icon(
                        item["icone"],
                        color: item["cor"],
                        size: 30,
                      ),
                      title: Text(
                        item["titulo"],
                        style: TextStyle(
                          color: item["cor"],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        item["descricao"],
                        style: TextStyle(color: item["cor"].withOpacity(0.6)),
                      ),
                      trailing: Text(
                        "R\$ ${item["valor"].toStringAsFixed(2)}",
                        style: TextStyle(
                          color: item["cor"],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ✅ Menu superior: Anteriores / Atual / Próximos
  Widget _buildMenuFluxo() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _menuBotao("Anteriores", "anteriores"),
          _menuBotao("Atual", "atual"),
          _menuBotao("Próximos", "proximos"),
        ],
      ),
    );
  }

  // ✅ Submenu: Últimos 7, 15, 30 dias ou personalizado
  Widget _buildSubmenuAnteriores() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 8),
            _submenuBotao("Últimos 7 dias", "7"),
            const SizedBox(width: 8),
            _submenuBotao("15 dias", "15"),
            const SizedBox(width: 8),
            _submenuBotao("30 dias", "30"),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (range != null) {
                  setState(() {
                    periodoPersonalizado = range;
                    filtroAnteriores = "personalizado";
                    _futureFluxo = _carregarFluxoCaixa();
                  });
                }
              },

              icon: const Icon(Icons.calendar_today, size: 16),
              label: const Text("Personalizado"),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _menuBotao(String titulo, String nome) {
    bool ativo = periodoSelecionado == nome;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: ativo ? corPrincipal.withOpacity(0.15) : Colors.black,
        foregroundColor: corPrincipal,
        side: BorderSide(color: corPrincipal, width: 1.2),
      ),
      onPressed: () {
        setState(() {
          periodoSelecionado = nome;
          _futureFluxo = _carregarFluxoCaixa();
        });
      },
      child: Text(titulo),
    );
  }

  Widget _submenuBotao(String titulo, String filtro) {
    bool ativo = filtroAnteriores == filtro;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: ativo ? corPrincipal.withOpacity(0.15) : Colors.black,
        foregroundColor: ativo ? corPrincipal : corPrincipal.withOpacity(0.6),
        side: BorderSide(color: corPrincipal, width: 1.2),
      ),
      onPressed: () {
        setState(() {
          filtroAnteriores = filtro;
          _futureFluxo = _carregarFluxoCaixa();
        });
      },
      child: Text(titulo),
    );
  }

  Widget _cardResumo(String titulo, String valor, Color cor) {
    return Card(
      color: Colors.black,
      elevation: 8,
      shadowColor: corPrincipal.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cor, width: 1.6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              titulo,
              style: TextStyle(
                fontSize: 16,
                color: cor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              valor,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
