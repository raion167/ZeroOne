import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color corPrincipal = Color(0xFFBBFB04);
final supabase = Supabase.instance.client;

class EngenhariaPage extends StatefulWidget {
  const EngenhariaPage({super.key});

  @override
  State<EngenhariaPage> createState() => _EngenhariaPageState();
}

class _EngenhariaPageState extends State<EngenhariaPage> {
  bool carregando = true;
  bool salvando = false;
  List<Map<String, dynamic>> projetos = [];

  @override
  void initState() {
    super.initState();
    carregarProjetos();
  }

  // ================= SUPABASE =================

  Future<void> carregarProjetos() async {
    setState(() => carregando = true);

    try {
      final response = await supabase
          .from('projetos')
          .select('*, clientes(nome)')
          .order('id', ascending: false);

      projetos = List<Map<String, dynamic>>.from(response).map((p) {
        p['cliente_nome'] = p['clientes']?['nome'];

        // manda automaticamente pra primeira coluna
        if (p['status'] == null || p['status'].toString().trim().isEmpty) {
          p['status'] = 'Comprar';
        }

        return p;
      }).toList();
    } catch (e) {
      projetos = [];
    } finally {
      setState(() => carregando = false);
    }
  }

  Future<void> moverProjeto(
    Map<String, dynamic> projeto,
    String novoStatus,
  ) async {
    setState(() => projeto['status'] = novoStatus);
    setState(() => salvando = true);

    try {
      await supabase
          .from('projetos')
          .update({'status': novoStatus})
          .eq('id', projeto['id'].toString());
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erro ao atualizar status')));
      await carregarProjetos();
    } finally {
      setState(() => salvando = false);
    }
  }

  // ================= FILTRO =================

  List<Map<String, dynamic>> filtrar(String status) {
    return projetos.where((p) {
      final s = (p['status'] ?? '').toString().toLowerCase();
      return s == status.toLowerCase();
    }).toList();
  }

  // ================= KANBAN =================

  Widget _buildKanbanColumn(String status, Color cor) {
    final lista = filtrar(status);

    return DragTarget<Map<String, dynamic>>(
      onAccept: (projeto) => moverProjeto(projeto, status),
      builder: (context, candidate, rejected) {
        return Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: candidate.isNotEmpty ? Colors.greenAccent : cor,
              width: 2,
            ),
            boxShadow: [BoxShadow(color: cor.withOpacity(0.4), blurRadius: 12)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cor,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: lista.length,
                  itemBuilder: (context, index) {
                    return _buildKanbanCard(lista[index], cor);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKanbanCard(Map<String, dynamic> projeto, Color cor) {
    return LongPressDraggable<Map<String, dynamic>>(
      data: projeto,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: cor, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(projeto['nome'] ?? '', style: TextStyle(color: cor)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _cardVisual(projeto, cor),
      ),
      child: _cardVisual(projeto, cor),
    );
  }

  Widget _cardVisual(Map<String, dynamic> projeto, Color cor) {
    return InkWell(
      onTap: () => _abrirDetalhesProjeto(projeto),
      child: Card(
        color: Colors.black,
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.assignment, color: cor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      projeto['nome'] ?? '',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: cor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                projeto['descricao'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Text(
                projeto['cliente_nome'] ?? '',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= STORAGE =================

  Future<void> enviarArquivosProjeto({
    required String projetoId,
    required List<XFile> imagens,
    required List<PlatformFile> documentos,
  }) async {
    for (final img in imagens) {
      final bytes = await img.readAsBytes();

      final nome =
          'projeto_$projetoId/${DateTime.now().millisecondsSinceEpoch}_${img.name}';

      await supabase.storage.from('projetos').uploadBinary(nome, bytes);
    }

    for (final doc in documentos) {
      final nome =
          'projeto_$projetoId/${DateTime.now().millisecondsSinceEpoch}_${doc.name}';

      await supabase.storage.from('projetos').uploadBinary(nome, doc.bytes!);
    }
  }

  Future<List<Map<String, dynamic>>> carregarArquivosProjeto(
    String projetoId,
  ) async {
    final arquivos = await supabase.storage
        .from('projetos')
        .list(path: 'projeto_$projetoId');

    return arquivos
        .map(
          (f) => {
            'nome': f.name,
            'url': supabase.storage
                .from('projetos')
                .getPublicUrl('projeto_$projetoId/${f.name}'),
          },
        )
        .toList();
  }

  void _abrirDetalhesProjeto(Map<String, dynamic> projeto) async {
    final projetoId = projeto['id'].toString();

    List<Map<String, dynamic>> arquivosExistentes =
        await carregarArquivosProjeto(projetoId);

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.black,
          child: Container(
            width: 500,
            height: 400,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  projeto['nome'] ?? '',
                  style: const TextStyle(
                    color: corPrincipal,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                Expanded(
                  child: GridView.builder(
                    itemCount: arquivosExistentes.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemBuilder: (_, i) {
                      final f = arquivosExistentes[i];

                      return InkWell(
                        onTap: () => launchUrl(Uri.parse(f['url'])),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Center(
                            child: Text(
                              f['nome'],
                              style: const TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _coluna('Comprar', Colors.orangeAccent),
                  _coluna('Comprados', Colors.blueAccent),
                  _coluna('Montagem', Colors.deepPurpleAccent),
                  _coluna('Protocolado', Colors.tealAccent),
                  _coluna('Homologação', Colors.amberAccent),
                  _coluna('Vistoria e Ligação', Colors.cyanAccent),
                  _coluna('Concluídos', corPrincipal),
                ],
              ),
            ),
    );
  }

  Widget _coluna(String status, Color cor) {
    return SizedBox(width: 320, child: _buildKanbanColumn(status, cor));
  }
}
