import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zeroone/pages/financeiro_page.dart';

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
    } catch (_) {
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
    setState(() => projeto["status"] = novoStatus);
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

  // =====================================================
  // 🔹 COLUNA KANBAN RESPONSIVA
  // =====================================================
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

  // =====================================================
  // 🔹 CARD ARRASTÁVEL
  // =====================================================
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
          child: Text(projeto["titulo"] ?? "", style: TextStyle(color: cor)),
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
      onTap: () => _abrirDetalhesProjeto(projeto),
      child: _cardVisual(projeto, cor),
    );
  }

  Widget _cardVisual(Map<String, dynamic> projeto, Color cor) {
    return Card(
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
                    projeto["titulo"] ?? "",
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
              projeto["descricao"] ?? "",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Text(
              projeto["cliente_nome"] ?? "",
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> enviarArquivosProjeto({
    required int projetoId,
    required List<XFile> imagens,
    required List<PlatformFile> documentos,
  }) async {
    final uri = Uri.parse("http://localhost:8080/app/upload_anexo.php");

    final request = http.MultipartRequest("POST", uri);
    request.fields["projeto_id"] = projetoId.toString();

    // IMAGENS
    for (final img in imagens) {
      if (kIsWeb) {
        final bytes = await img.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes("imagens[]", bytes, filename: img.name),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath("imagens[]", img.path),
        );
      }
    }

    // DOCUMENTOS
    for (final doc in documentos) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "documentos[]",
          doc.bytes!,
          filename: doc.name,
        ),
      );
    }

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception("Erro ao salvar arquivos");
    }
  }

  // =====================================================
  // 🔹 DETALHES DO PROJETO (INALTERADO)
  // =====================================================
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
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: corPrincipal, width: 2),
              ),
              titlePadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      projeto["titulo"] ?? "Detalhes do Projeto",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: corPrincipal),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: corPrincipal),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 300,
                      child: GridView.count(
                        crossAxisCount: 3,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        children: [
                          for (final f in arquivosExistentes)
                            _miniaturaArquivo(f),

                          for (final img in novasImagens)
                            kIsWeb
                                ? Image.network(img.path, fit: BoxFit.cover)
                                : Image.file(File(img.path), fit: BoxFit.cover),
                          for (final doc in novosDocs)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                border: Border.all(color: Colors.white24),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Center(
                                child: Text(
                                  doc.name,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: corPrincipal,
                        foregroundColor: Colors.black,
                      ),
                      icon: const Icon(Icons.image),
                      label: const Text("Adicionar Imagens"),
                      onPressed: () async {
                        final picked = await picker.pickMultiImage(
                          imageQuality: 70,
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            novasImagens.addAll(picked);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: corPrincipal,
                        foregroundColor: Colors.black,
                      ),
                      icon: const Icon(Icons.upload_file),
                      label: const Text("Adicionar Documentos"),
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          allowMultiple: true,
                        );
                        if (result != null) {
                          setStateDialog(() {
                            novosDocs.addAll(result.files);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBBFB04),
                    foregroundColor: Colors.black,
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text("Salvar"),
                  onPressed: () async {
                    try {
                      await enviarArquivosProjeto(
                        projetoId: int.parse(projeto["id"].toString()),
                        imagens: novasImagens,
                        documentos: novosDocs,
                      );

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Arquivos salvos com sucesso"),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Erro ao salvar arquivos"),
                        ),
                      );
                    }
                  },
                ),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =====================================================
  // 🔹 BUILD PRINCIPAL RESPONSIVO
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildKanbanColumn("A Fazer", Colors.orangeAccent),
                    ),
                    Expanded(
                      child: _buildKanbanColumn(
                        "Em Andamento",
                        Colors.blueAccent,
                      ),
                    ),
                    Expanded(
                      child: _buildKanbanColumn("Concluído", corPrincipal),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _miniaturaArquivo(Map<String, dynamic> f) {
    final url = "http://localhost:8080/app/uploads/${f["caminho"]}";

    if (f["tipo_arquivo"] == "imagem") {
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => Dialog(child: Image.network(url)),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(url, fit: BoxFit.cover),
        ),
      );
    }

    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.insert_drive_file, color: Colors.white, size: 32),
            const SizedBox(height: 6),
            Text(
              f["nome_arquivo"] ?? "",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
