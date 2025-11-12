import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  Future<Map<String, dynamic>> _carregarFluxoCaixa() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/fluxo_caixa.php"),
        body: {
          "periodo": periodoSelecionado,
          "filtro_anteriores": filtroAnteriores,
          if (periodoPersonalizado != null) ...{
            "data_inicio": periodoPersonalizado!.start.toIso8601String(),
            "data_fim": periodoPersonalizado!.end.toIso8601String(),
          },
        },
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
      appBar: AppBar(
        title: const Text("Visão Geral"),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: "Resumo Financeiro", icon: Icon(Icons.pie_chart)),
            Tab(text: "Vencimentos", icon: Icon(Icons.event)),
            Tab(text: "Fluxo de Caixa", icon: Icon(Icons.bar_chart)),
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

    for (var c in contas) {
      double valor = double.tryParse(c["valor"].toString()) ?? 0;
      String status = c["status"].toString();
      DateTime vencimento =
          DateTime.tryParse(c["data_vencimento"].toString()) ?? hoje;

      if (status == "Pago") pagos += valor;
      if (status == "Pendente") {
        if (vencimento.isBefore(hoje)) {
          atrasados += valor;
        } else {
          pendentes += valor;
        }
      }
    }

    double total = pagos + pendentes + atrasados;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Resumo Financeiro",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _cardResumo("Pagos", "R\$ ${pagos.toStringAsFixed(2)}", Colors.green),
          _cardResumo(
            "Pendentes",
            "R\$ ${pendentes.toStringAsFixed(2)}",
            Colors.orange,
          ),
          _cardResumo(
            "Atrasados",
            "R\$ ${atrasados.toStringAsFixed(2)}",
            Colors.red,
          ),
          _cardResumo(
            "Total a pagar",
            "R\$ ${total.toStringAsFixed(2)}",
            Colors.blue,
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
      if (status != "Pendente") return false;
      DateTime venc =
          DateTime.tryParse(c["data_vencimento"].toString()) ?? hoje;
      return !venc.isAfter(hoje);
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
            DateTime.tryParse(conta["data_vencimento"].toString()) ?? hoje;
        bool atrasada = venc.isBefore(DateTime.now());
        return Card(
          child: ListTile(
            leading: Icon(
              atrasada ? Icons.warning : Icons.info,
              color: atrasada ? Colors.red : Colors.orange,
            ),
            title: Text(conta["descricao"].toString()),
            subtitle: Text(
              "Vencimento: ${venc.day}/${venc.month}/${venc.year}",
            ),
            trailing: Text("R\$ ${conta["valor"]}"),
          ),
        );
      },
    );
  }

  // ✅ Aba 3 - Fluxo de Caixa (agora estilizada como Vencimentos)
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
                  "cor": Colors.green,
                  "descricao": "Valores recebidos no período",
                },
                {
                  "icone": Icons.arrow_upward,
                  "titulo": "Saídas",
                  "valor": saidas,
                  "cor": Colors.red,
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
                    elevation: 3,
                    child: ListTile(
                      leading: Icon(
                        item["icone"],
                        color: item["cor"],
                        size: 28,
                      ),
                      title: Text(
                        item["titulo"],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(item["descricao"]),
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
      color: Colors.grey[200],
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
      color: Colors.grey[100],
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
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: ativo ? Colors.blue : Colors.grey[300],
        foregroundColor: ativo ? Colors.white : Colors.black,
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
        backgroundColor: ativo ? Colors.blue : Colors.grey[300],
        foregroundColor: ativo ? Colors.white : Colors.black,
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
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 16)),
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
