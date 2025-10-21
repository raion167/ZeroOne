import 'package:flutter/material.dart';

class OperacionalOperadoresPage extends StatelessWidget {
  final String nomeUsuario;
  final String emailUsuario;

  const OperacionalOperadoresPage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Gerenciamento de Operadores (em desenvolvimento)",
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
