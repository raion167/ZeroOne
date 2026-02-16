import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'finalizar_projeto_page.dart';

const Color corPrincipal = Color(0xFFBBFB04);
const Color fundoEscuro = Color(0xFF0D0D0D);

final supabase = Supabase.instance.client;

class DetalhesEquipePage extends StatefulWidget {
  final String equipeId;
  final String nomeEquipe;

  const DetalhesEquipePage({
    super.key,
    required this.equipeId,
    required this.nomeEquipe,
  });

  @override
  State<DetalhesEquipePage> createState() => _DetalhesEquipePageState();
}

class _DetalhesEquipePageState extends State<DetalhesEquipePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool carregando = true;

  List<Map<String, dynamic>> operadores = [];
  List<Map<String, dynamic>> projetos = [];
  Map<String, int> status = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    carregarDados();
  }

  Future<void> carregarDados() async {
    setState(() => carregando = true);
    await Future.wait([
      carregarOperadores(),
      carregarProjetos(),
      carregarStatus(),
    ]);
    setState(() => carregando = false);
  }

  // ================= OPERADORES =================
  Future<void> carregarOperadores() async {
    final resp = await supabase
        .from('equipe_usuario')
        .select('''
      user_id,
      usuarios_operacional!equipe_usuario_user_id_fkey(
        id,
        nome,
        email
      )
    ''')
        .eq('equipe_id', widget.equipeId);

    operadores = List<Map<String, dynamic>>.from(resp)
        .map((e) => e['usuarios_operacional'])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<bool> desvincularOperador(String usuarioId) async {
    await supabase
        .from('equipe_usuario')
        .delete()
        .eq('user_id', usuarioId)
        .eq('equipe_id', widget.equipeId);
    return true;
  }

  // ================= PROJETOS =================
  Future<void> carregarProjetos() async {
    final resp = await supabase
        .from('projetos')
        .select()
        .eq('status', 'em andamento');

    projetos = List<Map<String, dynamic>>.from(resp);
  }

  // ================= STATUS =================
  Future<void> carregarStatus() async {
    final totalResp = await supabase
        .from('projetos')
        .select('id')
        .eq('equipe_id', widget.equipeId);

    final finalizadosResp = await supabase
        .from('projetos')
        .select('id')
        .eq('equipe_id', widget.equipeId)
        .eq('status', 'finalizado');

    final andamentoResp = await supabase
        .from('projetos')
        .select('id')
        .eq('equipe_id', widget.equipeId)
        .eq('status', 'em andamento');

    status = {
      'total': totalResp.length,
      'finalizados': finalizadosResp.length,
      'andamento': andamentoResp.length,
    };
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
        title: Text(widget.nomeEquipe),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: corPrincipal,
          labelColor: corPrincipal,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Operadores'),
            Tab(icon: Icon(Icons.work), text: 'Projetos'),
            Tab(icon: Icon(Icons.analytics), text: 'Status'),
          ],
        ),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildOperadores(), _buildProjetos(), _buildStatus()],
            ),
    );
  }

  Widget _buildOperadores() {
    if (operadores.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum operador vinculado',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: operadores.length,
      itemBuilder: (_, i) {
        final op = operadores[i];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: fundoEscuro,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: corPrincipal.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(color: corPrincipal.withOpacity(0.25), blurRadius: 12),
            ],
          ),
          child: ListTile(
            leading: const Icon(Icons.person, color: corPrincipal),
            title: Text(
              op['nome'] ?? '',
              style: const TextStyle(
                color: corPrincipal,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              op['email'] ?? '',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: Colors.redAccent,
              ),
              onPressed: () async {
                final ok = await desvincularOperador(op['id'].toString());
                if (ok) setState(() => operadores.removeAt(i));
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjetos() {
    if (projetos.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum projeto cadastrado',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projetos.length,
      itemBuilder: (context, index) {
        final p = projetos[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: fundoEscuro,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: corPrincipal.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(color: corPrincipal.withOpacity(0.25), blurRadius: 12),
            ],
          ),
          child: ListTile(
            leading: const Icon(Icons.assignment, color: corPrincipal),
            title: Text(
              p['nome'] ?? 'Projeto sem título',
              style: const TextStyle(
                color: corPrincipal,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: corPrincipal,
            ),
            onTap: () async {
              final bool? finalizado = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      FinalizarProjetoPage(projetoId: (p['id'].toString())),
                ),
              );

              if (finalizado == true) {
                await carregarProjetos();
                await carregarStatus();
                setState(() {});
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildStatus() {
    if (status.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _statusCard('Total OS', status['total'] ?? 0, Colors.blue),
          const SizedBox(width: 12),
          _statusCard('Finalizadas', status['finalizados'] ?? 0, Colors.green),
          const SizedBox(width: 12),
          _statusCard('Em andamento', status['andamento'] ?? 0, Colors.orange),
        ],
      ),
    );
  }

  Widget _statusCard(String titulo, int valor, Color cor) {
    return Expanded(
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: fundoEscuro,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cor.withOpacity(0.5)),
          boxShadow: [BoxShadow(color: cor.withOpacity(0.35), blurRadius: 14)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              valor.toString(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
