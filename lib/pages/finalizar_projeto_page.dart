import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:signature/signature.dart';

class FinalizarProjetoPage extends StatefulWidget {
  final int projetoId;

  const FinalizarProjetoPage({super.key, required this.projetoId});

  @override
  State<FinalizarProjetoPage> createState() => _FinalizarProjetoPageState();
}

class _FinalizarProjetoPageState extends State<FinalizarProjetoPage> {
  final TextEditingController obsController = TextEditingController();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  bool isLoading = false;

  Future<void> enviarFinalizacao() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, faça a assinatura")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final Uint8List? assinaturaBytes = await _signatureController
          .toPngBytes();
      if (assinaturaBytes == null) return;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse("http://localhost:8080/app/finalizar_projeto.php"),
      );

      request.fields['projeto_id'] = widget.projetoId.toString();
      request.fields['observacoes'] = obsController.text;

      request.files.add(
        http.MultipartFile.fromBytes(
          'assinatura',
          assinaturaBytes,
          filename: "assinatura_${widget.projetoId}.png",
        ),
      );

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      final data = jsonDecode(respStr);

      if (data["success"] == true) {
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
      ).showSnackBar(SnackBar(content: Text("Erro ao enviar: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Finalizar Projeto")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Observações sobre o serviço:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: obsController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Digite observações relevantes...",
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Assinatura do cliente:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Signature(
                controller: _signatureController,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _signatureController.clear(),
                  icon: const Icon(Icons.clear),
                  label: const Text("Limpar"),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : enviarFinalizacao,
                  icon: const Icon(Icons.send),
                  label: const Text("Enviar Finalização"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
