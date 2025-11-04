import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:signature/signature.dart';

class DetalhesProjetoPage extends StatefulWidget {
  final int projetoId;
  final String tituloProjeto;

  const DetalhesProjetoPage({
    super.key,
    required this.projetoId,
    required this.tituloProjeto,
  });

  @override
  State<DetalhesProjetoPage> createState() => _DetalhesProjetoPageState();
}

class _DetalhesProjetoPageState extends State<DetalhesProjetoPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool carregando = true;
  List<dynamic> materiais = [];

  final TextEditingController observacoesController = TextEditingController();
  final SignatureController assinaturaController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    carregarMateriais();
  }

  Future<void> carregarMateriais() async {
    try {
      final res = await http.get(
        Uri.parse(
          "http://localhost:8080/app/listar_materiais_projeto.php?projeto_id=${widget.projetoId}",
        ),
      );
      final data = jsonDecode(res.body);
      if (data["success"]) {
        setState(() {
          materiais = data["materiais"];
          carregando = false;
        });
      } else {
        setState(() => carregando = false);
      }
    } catch (e) {
      setState(() => carregando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao carregar materiais: $e")));
    }
  }

  Future<void> atualizarMaterialProjeto({
    required int estoqueId,
    required bool checado,
    int? quantidadeUsada,
  }) async {
    final url = Uri.parse(
      "http://localhost:8080/app/atualizar_material_projeto.php",
    );
    final body = {
      "projeto_id": widget.projetoId,
      "estoque_id": estoqueId,
      "checado": checado ? 1 : 0,
      "quantidade_usada": quantidadeUsada ?? 0,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      // debug rápido: se não for 200, mostra corpo
      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro HTTP ${response.statusCode}: ${response.body}"),
          ),
        );
        return;
      }

      // tenta decodificar, mas protege contra JSON inválido
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data["success"] == true) {
          // ok
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Falha ao atualizar: ${data['message'] ?? response.body}",
              ),
            ),
          );
        }
      } catch (e) {
        // Mostra retorno bruto para ajudar debug (HTML/warnings)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Resposta inválida do servidor: ${response.body}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro de rede ao atualizar material: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Projeto: ${widget.tituloProjeto}"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.checklist), text: "Checklist de Materiais"),
            Tab(icon: Icon(Icons.done_all), text: "Finalizar Projeto"),
          ],
        ),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildChecklist(), _buildFinalizar()],
            ),
    );
  }

  // LISTA DE MATERIAIS
  Widget _buildChecklist() {
    if (materiais.isEmpty) {
      return const Center(
        child: Text("Nenhum material vinculado a este projeto"),
      );
    }

    return ListView.builder(
      itemCount: materiais.length,
      itemBuilder: (context, i) {
        final m = materiais[i];
        final nome = m["nome"] ?? "Material sem nome";
        final estoqueId = int.parse(m["estoque_id"].toString());
        final quantidadeNecessaria =
            int.tryParse(m["quantidade_necessaria"]?.toString() ?? "0") ?? 0;
        final quantidadeUsada =
            int.tryParse(m["quantidade_usada"]?.toString() ?? "0") ?? 0;
        final checado =
            m["checado"] == 1 ||
            m["checado"] == true ||
            m["checado"] == "1" ||
            m["checado"] == "true";

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Column(
            children: [
              CheckboxListTile(
                title: Text(
                  nome,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Quantidade necessária: $quantidadeNecessaria"),
                value: checado,
                onChanged: (v) {
                  setState(() {
                    m["checado"] = v == true ? 1 : 0;
                  });
                  atualizarMaterialProjeto(
                    estoqueId: estoqueId,
                    checado: v ?? false,
                    quantidadeUsada: quantidadeUsada,
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Text("Usado: "),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (m["quantidade_usada"] > 0) {
                          setState(() => m["quantidade_usada"]--);
                          atualizarMaterialProjeto(
                            estoqueId: estoqueId,
                            checado: checado,
                            quantidadeUsada: m["quantidade_usada"],
                          );
                        }
                      },
                    ),
                    Text(m["quantidade_usada"].toString()),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() => m["quantidade_usada"]++);
                        atualizarMaterialProjeto(
                          estoqueId: estoqueId,
                          checado: checado,
                          quantidadeUsada: m["quantidade_usada"],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ABA DE FINALIZAÇÃO
  Widget _buildFinalizar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: observacoesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Observações sobre o serviço",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Assinatura do cliente:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(8),
              ),
              height: 200,
              child: Signature(
                controller: assinaturaController,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text("Limpar"),
                  onPressed: () => assinaturaController.clear(),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Finalizar Projeto"),
                  onPressed: finalizarProjeto,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // FINALIZAÇÃO DO PROJETO
  Future<void> finalizarProjeto() async {
    try {
      final assinatura = await assinaturaController.toPngBytes();

      if (assinatura == null || assinatura.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Por favor, assine antes de finalizar."),
          ),
        );
        return;
      }

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("http://localhost:8080/app/finalizar_projeto.php"),
      );

      request.fields["projeto_id"] = widget.projetoId.toString();
      request.fields["observacoes"] = observacoesController.text;
      request.files.add(
        http.MultipartFile.fromBytes(
          "assinatura",
          assinatura,
          filename: "assinatura.png",
        ),
      );

      final res = await request.send();
      final body = await res.stream.bytesToString();
      final data = jsonDecode(body);

      if (data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Projeto finalizado com sucesso!")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro: ${data['message']}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao finalizar: $e")));
    }
  }
}
