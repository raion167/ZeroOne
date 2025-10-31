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

  // Controladores
  late final TextEditingController observacaoController;
  late final SignatureController _signatureController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    // 🔧 Inicialização correta dos controladores
    observacaoController = TextEditingController();
    _signatureController = SignatureController(
      penStrokeWidth: 2,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    carregarMateriais();
  }

  @override
  void dispose() {
    observacaoController.dispose();
    _signatureController.dispose();
    _tabController.dispose();
    super.dispose();
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
        final quantidadeNecessaria = m["quantidade_necessaria"] ?? 0;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: CheckboxListTile(
            title: Text(
              nome,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Quantidade atribuída: $quantidadeNecessaria"),
            value: m["checado"] == true,
            onChanged: (v) {
              setState(() {
                m["checado"] = v;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildFinalizar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              "Observações sobre o serviço:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: observacaoController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                hintText: "Digite observações sobre o projeto...",
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 20),

            const Text(
              "Assinatura do responsável:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            // 🖊️ Campo de assinatura
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Signature(
                controller: _signatureController,
                backgroundColor: Colors.grey[100]!,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.clear),
                  label: const Text("Limpar"),
                  onPressed: () {
                    _signatureController.clear();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text("Finalizar Projeto"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: () async {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Finalizar Projeto"),
                    content: const Text(
                      "Deseja realmente finalizar este projeto?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancelar"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Confirmar"),
                      ),
                    ],
                  ),
                );

                if (confirmar == true) {
                  await finalizarProjeto();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> finalizarProjeto() async {
    try {
      Uint8List? assinaturaBytes = await _signatureController.toPngBytes();

      if (assinaturaBytes == null || assinaturaBytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor, insira a assinatura.")),
        );
        return;
      }

      final assinaturaBase64 = base64Encode(assinaturaBytes);

      final res = await http.post(
        Uri.parse("http://localhost:8080/app/finalizar_projeto.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "projeto_id": widget.projetoId,
          "observacoes": observacaoController.text,
          "assinatura": assinaturaBase64,
        }),
      );

      final data = jsonDecode(res.body);

      if (data["success"]) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Projeto finalizado com sucesso!")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro: ${data["message"]}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }
}
