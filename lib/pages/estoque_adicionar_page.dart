import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'menu_lateral.dart';

final supabase = Supabase.instance.client;

class EstoqueAdicionarPage extends StatefulWidget {
  final String nomeUsuario;
  final String emailUsuario;

  const EstoqueAdicionarPage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  State<EstoqueAdicionarPage> createState() => _EstoqueAdicionarPageState();
}

class _EstoqueAdicionarPageState extends State<EstoqueAdicionarPage> {
  final TextEditingController nomeCtrl = TextEditingController();
  final TextEditingController qtdCtrl = TextEditingController();
  final TextEditingController precoCtrl = TextEditingController();

  bool carregando = false;

  Future<void> adicionarProduto() async {
    final nome = nomeCtrl.text.trim();
    final qtdText = qtdCtrl.text.trim();
    final precoText = precoCtrl.text.trim();

    if (nome.isEmpty || qtdText.isEmpty || precoText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos.")),
      );
      return;
    }

    int quantidade;
    double preco;

    try {
      quantidade = int.parse(qtdText);
      preco = double.parse(precoText.replaceAll(',', '.'));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quantidade ou preço inválido.")),
      );
      return;
    }

    setState(() => carregando = true);

    try {
      await supabase.from('estoque').insert({
        'nome': nome,
        'quantidade': quantidade,
        'preco': preco,
        'data_cadastro': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Produto adicionado com sucesso")),
      );

      nomeCtrl.clear();
      qtdCtrl.clear();
      precoCtrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao adicionar produto: $e")));
    } finally {
      setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
        title: const Text("Itens em Estoque"),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nomeCtrl,
              style: const TextStyle(color: corPrincipal),
              cursorColor: corPrincipal,
              decoration: _decoracaoCampo("Nome do Produto"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: qtdCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: corPrincipal),
              cursorColor: corPrincipal,
              decoration: _decoracaoCampo("Quantidade"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: precoCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: corPrincipal),
              cursorColor: corPrincipal,
              decoration: _decoracaoCampo("Preço Unitário (R\$)"),
            ),
            const SizedBox(height: 20),
            carregando
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: adicionarProduto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: corPrincipal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.check, color: Colors.black),
                    label: const Text(
                      "Salvar",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoracaoCampo(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: corPrincipal),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: corPrincipal),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: corPrincipal, width: 2),
      ),
    );
  }
}
