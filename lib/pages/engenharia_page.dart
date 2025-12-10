import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> carregarProjetos() async {
    setState(() => carregando = true);
    try {
      final res = await http.get(
        Uri.parse("http://localhost:8080/app/listar_projetos_engenharia.php"),
      );

      final data = jsonDecode(res.body);
      if (data["success"] == true) {
        projetos = (data["projetos"] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else {
        projetos = [];
      }
    } catch (e) {
      projetos = [];
    } finally {
      setState(() => carregando = false);
    }
  }

  List<Map<String, dynamic>> filtrar(String status) {
    return projetos.where((p) {
      final s = (p["status"] ?? "").toString().trim().toLowerCase();
      return s == status.toLowerCase();
    }).toList();
  }

  Future<void> moverProjeto(
    Map<String, dynamic> projeto,
    String novoStatus,
  ) async {
    setState(() {
      projeto["status"] = novoStatus;
    });

    setState(() => salvando = true);
    try {
      final res = await http.post(
        Uri.parse("http://localhost:8080/app/atualizar_status_projeto.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": projeto["id"], "status": novoStatus}),
      );

      final data = jsonDecode(res.body);
      if (data["success"] != true) throw Exception();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao atualizar status.")),
      );
      await carregarProjetos();
    } finally {
      setState(() => salvando = false);
    }
  }

  // ================================================
  // 🔥 COLUNA KANBAN COM DRAGTARGET
  // ================================================
  Widget _buildKanbanColumn(String status, Color cor) {
    final lista = filtrar(status);

    return SizedBox(
      width: 350,
      child: DragTarget<Map<String, dynamic>>(
        onAccept: (projeto) => moverProjeto(projeto, status),
        builder: (context, candidate, rejected) {
          return Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: candidate.isNotEmpty ? Colors.green : cor,
                width: 3,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cor,
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return ListView.builder(
                        itemCount: lista.length,
                        itemBuilder: (context, index) {
                          final item = lista[index];
                          return _buildKanbanCard(item, cor);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================================================
  // 🔥 CARD ARRASTÁVEL (DRAGGABLE)
  // ================================================
  Widget _buildKanbanCard(Map<String, dynamic> projeto, Color cor) {
    return LongPressDraggable<Map<String, dynamic>>(
      data: projeto,
      feedback: Material(
        elevation: 4,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: cor, width: 2),
          ),
          child: Text(
            projeto["titulo"] ?? "",
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),

      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _cardClickable(projeto, cor),
      ),

      child: _cardClickable(projeto, cor),
    );
  }

  Widget _cardClickable(Map<String, dynamic> projeto, Color cor) {
    return InkWell(
      onTap: () => _abrirDetalhesProjeto(projeto), // 👉 abre popup ao clicar
      child: _cardVisual(projeto, cor),
    );
  }

  Widget _cardVisual(Map<String, dynamic> projeto, Color cor) {
    return Card(
      elevation: 3,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: cor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    projeto["titulo"] ?? "Sem título",
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            Text(
              projeto["descricao"] ?? "",
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            Text(
              projeto["cliente_nome"] ?? "",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================
  // 🔥 DETALHES DO PROJETO (MANTIVE SEU CÓDIGO)
  // ====================================================
  Future<List<Map<String, dynamic>>> carregarArquivosProjeto(
    int projetoId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse(
          "http://localhost:8080/app/listar_arquivos_projeto.php?projeto_id=$projetoId",
        ),
      );
      final data = jsonDecode(res.body);
      if (data["success"] == true) {
        return (data["arquivos"] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (_) {}

    return [];
  }

  void _abrirDetalhesProjeto(Map<String, dynamic> projeto) async {
    final ImagePicker picker = ImagePicker();
    List<XFile> novasImagens = [];
    List<PlatformFile> novosDocs = [];

    List<Map<String, dynamic>> arquivosExistentes =
        await carregarArquivosProjeto(int.parse(projeto["id"].toString()));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(projeto["titulo"] ?? "Detalhes do Projeto"),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Cliente: ${projeto["cliente_nome"] ?? '—'}"),
                      const SizedBox(height: 8),
                      Text("Descrição: ${projeto["descricao"] ?? '—'}"),
                      const SizedBox(height: 12),
                      const Text(
                        "Arquivos:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 8),
                      SizedBox(
                        height: 300,
                        child: GridView.count(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          children: [
                            for (final f in arquivosExistentes)
                              if (f["tipo_arquivo"] == "imagem")
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        child: Image.network(
                                          "http://localhost:8080/app/${f["caminho"]}",
                                        ),
                                      ),
                                    );
                                  },
                                  child: Image.network(
                                    "http://localhost:8080/app/${f["caminho"]}",
                                    fit: BoxFit.cover,
                                  ),
                                ),

                            for (final f in arquivosExistentes)
                              if (f["tipo_arquivo"] == "documento")
                                GestureDetector(
                                  onTap: () {
                                    launchUrl(
                                      Uri.parse(
                                        "http://localhost:8080/app/${f["caminho"]}",
                                      ),
                                    );
                                  },
                                  child: Container(
                                    color: Colors.grey[300],
                                    child: Center(
                                      child: Text(
                                        f["nome_arquivo"],
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),

                            for (final img in novasImagens)
                              Image.file(File(img.path), fit: BoxFit.cover),

                            for (final doc in novosDocs)
                              Container(
                                color: Colors.grey[200],
                                child: Center(child: Text(doc.name)),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final picked = await picker.pickMultiImage(
                            imageQuality: 70,
                          );
                          if (picked != null) {
                            setStateDialog(() => novasImagens.addAll(picked));
                          }
                        },
                        icon: const Icon(Icons.image),
                        label: const Text("Adicionar Imagens"),
                      ),

                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            allowMultiple: true,
                            type: FileType.any,
                          );
                          if (result != null) {
                            setStateDialog(
                              () => novosDocs.addAll(result.files),
                            );
                          }
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text("Adicionar Documentos"),
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Fechar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ====================================================
  // 🔥 TELA PRINCIPAL
  // ====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Engenharia - Painel Kanban"),
        backgroundColor: Colors.white,
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildKanbanColumn("A Fazer", Colors.orange),
                  _buildKanbanColumn("Em Andamento", Colors.blue),
                  _buildKanbanColumn("Concluído", Colors.green),
                ],
              ),
            ),
    );
  }
}
