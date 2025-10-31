import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zeroone/pages/projetos_page.dart';

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
      if (data["success"] != true) {
        throw Exception();
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao atualizar status.")),
      );
      await carregarProjetos();
    } finally {
      setState(() => salvando = false);
    }
  }

  Widget _buildKanbanColumn(String status, Color cor) {
    final lista = filtrar(status);

    return Expanded(
      child: DragTarget<Map<String, dynamic>>(
        onWillAccept: (data) => data != null && data["status"] != status,
        onAccept: (projeto) => moverProjeto(projeto, status),
        builder: (context, candidateData, rejectedData) {
          return Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cor, width: 1.5),
            ),
            child: Column(
              children: [
                Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: cor,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final projeto in lista)
                          LongPressDraggable<Map<String, dynamic>>(
                            data: projeto,
                            feedback: Material(
                              elevation: 6,
                              child: SizedBox(
                                width: 200,
                                child: _buildCard(projeto, cor, dragging: true),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.4,
                              child: _buildCard(projeto, cor),
                            ),
                            child: _buildCard(projeto, cor),
                          ),
                        if (candidateData.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Icon(Icons.arrow_downward, color: cor),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(
    Map<String, dynamic> projeto,
    Color cor, {
    bool dragging = false,
  }) {
    return Card(
      color: dragging ? Colors.grey[200] : Colors.white,
      elevation: dragging ? 8 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(projeto["titulo"] ?? "Sem título"),
        subtitle: Text(projeto["descricao"] ?? ""),
        leading: Icon(Icons.assignment, color: cor),
        trailing: Text(
          projeto["cliente_nome"]?.toString() ?? "",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        onTap: () => _abrirDetalhesProjeto(projeto),
      ),
    );
  }

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

                      // Grid de arquivos com altura definida
                      SizedBox(
                        height: 300, // evita erro de hit test
                        child: GridView.count(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          children: [
                            // Imagens existentes
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
                            // Documentos existentes
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
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ),
                            // Novas imagens
                            for (final img in novasImagens)
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      child: Image.file(File(img.path)),
                                    ),
                                  );
                                },
                                child: Image.file(
                                  File(img.path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            // Novos documentos
                            for (final doc in novosDocs)
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Arquivo: ${doc.name}"),
                                    ),
                                  );
                                },
                                child: Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Text(
                                      doc.name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
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
                            setStateDialog(() {
                              novasImagens.addAll(picked);
                            });
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
                            setStateDialog(() {
                              novosDocs.addAll(result.files);
                            });
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
                ElevatedButton(
                  onPressed: () async {
                    try {
                      var request = http.MultipartRequest(
                        'POST',
                        Uri.parse(
                          "http://localhost:8080/app/upload_projeto.php",
                        ),
                      );
                      request.fields['projeto_id'] = projeto["id"].toString();

                      for (final img in novasImagens) {
                        if (kIsWeb) {
                          final bytes = await img.readAsBytes();
                          request.files.add(
                            http.MultipartFile.fromBytes(
                              'arquivos[]',
                              bytes,
                              filename: img.name,
                            ),
                          );
                        } else {
                          request.files.add(
                            await http.MultipartFile.fromPath(
                              'arquivos[]',
                              img.path,
                            ),
                          );
                        }
                      }

                      for (final doc in novosDocs) {
                        if (doc.bytes != null) {
                          request.files.add(
                            http.MultipartFile.fromBytes(
                              'arquivos[]',
                              doc.bytes!,
                              filename: doc.name,
                            ),
                          );
                        } else if (doc.path != null && !kIsWeb) {
                          request.files.add(
                            await http.MultipartFile.fromPath(
                              'arquivos[]',
                              doc.path!,
                            ),
                          );
                        }
                      }

                      final response = await request.send();
                      final respStr = await response.stream.bytesToString();
                      final data = jsonDecode(respStr);

                      if (data["success"] == true) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Arquivos enviados com sucesso!"),
                          ),
                        );
                        carregarProjetos(); // atualiza arquivos
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Falha no envio!")),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Erro: $e")));
                    }
                  },
                  child: const Text("Salvar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Engenharia - Painel Kanban"),
        backgroundColor: Colors.white,
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                _buildKanbanColumn("A Fazer", Colors.orange),
                _buildKanbanColumn("Em Andamento", Colors.blue),
                _buildKanbanColumn("Concluído", Colors.green),
              ],
            ),
      floatingActionButton: salvando
          ? const FloatingActionButton(
              backgroundColor: Colors.grey,
              onPressed: null,
              child: CircularProgressIndicator(color: Colors.white),
            )
          : FloatingActionButton(
              backgroundColor: Colors.black,
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProjetosPage()),
                );
              },
              child: const Icon(Icons.add),
            ),
    );
  }
}
