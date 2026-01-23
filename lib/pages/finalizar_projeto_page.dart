import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:signature/signature.dart';

const Color corPrincipal = Color(0xFFBBFB04);
const Color fundoEscuro = Color(0xFF0D0D0D);

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

      if (assinaturaBytes == null) {
        throw Exception("Falha ao gerar imagem da assinatura");
      }

      final uri = Uri.parse("http://localhost:8080/app/finalizar_projeto.php");

      var request = http.MultipartRequest('POST', uri);
      request.fields['projeto_id'] = widget.projetoId.toString();
      request.fields['observacoes'] = obsController.text;

      request.files.add(
        http.MultipartFile.fromBytes(
          'assinatura',
          assinaturaBytes,
          filename: 'assinatura_${widget.projetoId}.png',
        ),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);

      if (data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Projeto finalizado com sucesso!")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro: ${data["message"] ?? "Erro desconhecido"}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao finalizar: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundoEscuro,
      appBar: AppBar(
        backgroundColor: fundoEscuro,
        foregroundColor: corPrincipal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Observações sobre o serviço"),
            const SizedBox(height: 8),
            _neonContainer(
              child: TextField(
                controller: obsController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Digite observações relevantes...",
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle("Assinatura do cliente"),
            const SizedBox(height: 8),
            _neonContainer(
              child: SizedBox(
                height: 200,
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _neonButton(
                  icon: Icons.clear,
                  label: "Limpar",
                  color: Colors.redAccent,
                  onPressed: () => _signatureController.clear(),
                ),
                const Spacer(),
                _neonButton(
                  icon: Icons.send,
                  label: isLoading ? "Enviando..." : "Enviar Finalização",
                  color: corPrincipal,
                  onPressed: isLoading ? null : enviarFinalizacao,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= COMPONENTES VISUAIS =================

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: corPrincipal,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _neonContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fundoEscuro,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: corPrincipal.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(color: corPrincipal.withOpacity(0.25), blurRadius: 14),
        ],
      ),
      child: child,
    );
  }

  Widget _neonButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.black),
      label: Text(label, style: const TextStyle(color: Colors.black)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 6,
        shadowColor: color.withOpacity(0.6),
      ),
    );
  }
}
