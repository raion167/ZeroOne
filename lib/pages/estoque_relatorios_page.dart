import 'package:flutter/material.dart';
import 'menu_lateral.dart';

class EstoqueRelatoriosPage extends StatelessWidget {
  final String nomeUsuario;
  final String emailUsuario;

  const EstoqueRelatoriosPage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      titulo: "Relatórios de Estoque",
      nomeUsuario: nomeUsuario,
      emailUsuario: emailUsuario,
      corpo: const Center(
        child: Text(
          "📊 Relatórios de estoque aparecerão aqui",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
