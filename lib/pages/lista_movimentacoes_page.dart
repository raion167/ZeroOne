import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

final supabase = Supabase.instance.client;
const Color corPrincipal = Color(0xFFBBFB04);

class EstoqueMovimentacoesListPage extends StatefulWidget {
  final String nomeUsuario;
  final String emailUsuario;

  const EstoqueMovimentacoesListPage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  State<EstoqueMovimentacoesListPage> createState() =>
      _EstoqueMovimentacoesListPageState();
}

class _EstoqueMovimentacoesListPageState
    extends State<EstoqueMovimentacoesListPage> {
  bool carregando = true;

  List<Map<String, dynamic>> entradas = [];
  List<Map<String, dynamic>> saidas = [];

  DateTimeRange? filtroData;
  String? filtroUsuario; // UUID do usuário
  List<Map<String, dynamic>> listaUsuarios = [];

  // ================== CARREGAR MOVIMENTAÇÕES ==================
  Future<void> carregarMovimentacoes() async {
    setState(() => carregando = true);

    try {
      var query = supabase.from('movimentacoes_estoque').select('''
        id,
        tipo,
        quantidade,
        data_movimentacao,
        estoque:produto_id ( nome ),
        usuario:user_id ( nome, email )
      ''');

      // 🔹 filtro por usuário (UUID)
      if (filtroUsuario != null && filtroUsuario!.isNotEmpty) {
        query = query.eq('user_id', filtroUsuario!);
      }

      // 🔹 filtro por período
      if (filtroData != null) {
        query = query
            .gte('data_movimentacao', filtroData!.start.toIso8601String())
            .lte('data_movimentacao', filtroData!.end.toIso8601String());
      }

      final response = await query.order('data_movimentacao', ascending: false);

      final dados = (response as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      entradas = [];
      saidas = [];

      for (final item in dados) {
        final produto =
            (item['estoque'] != null && item['estoque']['nome'] != null)
            ? item['estoque']['nome'].toString()
            : '-';

        final usuario =
            (item['usuario'] != null && item['usuario']['nome'] != null)
            ? item['usuario']['nome'].toString()
            : 'Sem usuário';

        final quantidade = item['quantidade'] ?? 0;
        String dataFormatada = '-';
        if (item['data_movimentacao'] != null) {
          final dt = DateTime.parse(item['data_movimentacao']);
          dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(dt);
        }

        final registro = {
          'produto': produto,
          'usuario': usuario,
          'quantidade': quantidade,
          'data': dataFormatada,
        };

        if ((item['tipo'] ?? '') == 'entrada') {
          entradas.add(registro);
        } else {
          saidas.add(registro);
        }
      }

      // 🔹 usuários para filtro (auth.users)
      final usuariosResp = await supabase
          .from('usuarios')
          .select('id, nome, email');

      listaUsuarios = List<Map<String, dynamic>>.from(usuariosResp);

      setState(() => carregando = false);
    } catch (e) {
      setState(() => carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar movimentações: $e')),
      );
    }
  }

  // ================== DATE PICKER ==================
  Future<void> selecionarPeriodo() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: filtroData,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: corPrincipal,
              surface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => filtroData = picked);
      carregarMovimentacoes();
    }
  }

  @override
  void initState() {
    super.initState();
    carregarMovimentacoes();
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimentações'),
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔹 FILTROS
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: _neonBox(),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          dropdownColor: Colors.black,
                          value: filtroUsuario,
                          hint: const Text(
                            'Filtrar por usuário',
                            style: TextStyle(color: Colors.white70),
                          ),
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputNeon(),
                          items: listaUsuarios
                              .map(
                                (u) => DropdownMenuItem<String>(
                                  value: u['id'],
                                  child: Text(
                                    u['nome'] ?? u['email'] ?? 'Usuário',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() => filtroUsuario = v);
                            carregarMovimentacoes();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          side: BorderSide(color: corPrincipal),
                        ),
                        icon: Icon(Icons.date_range, color: corPrincipal),
                        label: const Text(
                          'Data',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: selecionarPeriodo,
                      ),
                    ],
                  ),
                ),

                // 🔹 LISTAS
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _MovimentacaoLista(
                          titulo: 'Entradas',
                          cor: Colors.greenAccent,
                          movimentacoes: entradas,
                        ),
                      ),
                      Expanded(
                        child: _MovimentacaoLista(
                          titulo: 'Saídas',
                          cor: Colors.redAccent,
                          movimentacoes: saidas,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ================== CARD ==================
class _MovimentacaoLista extends StatelessWidget {
  final String titulo;
  final Color cor;
  final List<Map<String, dynamic>> movimentacoes;

  const _MovimentacaoLista({
    required this.titulo,
    required this.cor,
    required this.movimentacoes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(titulo, style: TextStyle(color: cor, fontSize: 18)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: movimentacoes.length,
              itemBuilder: (_, i) {
                final item = movimentacoes[i];
                return ListTile(
                  title: Text(
                    item['produto'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Qtd: ${item['quantidade']}\nUsuário: ${item['usuario']}\nData: ${item['data']}',
                    style: const TextStyle(color: Colors.white70),
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

// ================== DECORAÇÕES ==================
BoxDecoration _neonBox() => BoxDecoration(
  color: Colors.black,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: corPrincipal),
);

InputDecoration _inputNeon() => InputDecoration(
  filled: true,
  fillColor: Colors.black,
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: corPrincipal),
    borderRadius: BorderRadius.circular(12),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: corPrincipal, width: 2),
    borderRadius: BorderRadius.circular(12),
  ),
);
