import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:zeroone/pages/clientes_page.dart';
import 'package:zeroone/pages/configuracoes_page.dart';
import 'package:zeroone/pages/controle_estoque_page.dart';
import 'package:zeroone/pages/engenharia_page.dart';
import 'package:zeroone/pages/financeiro_page.dart';
import 'package:zeroone/pages/projetos_page.dart';
import 'monitoramento_clientes_page.dart';
import 'pagina_inicial.dart';
import 'operacional_page.dart';
import 'nova_venda_page.dart';

const Color corPrincipal = Color(0xFFBBFB04);

class BaseScaffold extends StatefulWidget {
  final String titulo;
  final Widget corpo;
  final String nomeUsuario;
  final String emailUsuario;

  const BaseScaffold({
    super.key,
    required this.titulo,
    required this.corpo,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  State<BaseScaffold> createState() => _BaseScaffoldState();
}

class _BaseScaffoldState extends State<BaseScaffold> {
  bool drawerAberto = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo, style: const TextStyle(color: corPrincipal)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: corPrincipal),
      ),

      drawer: AnimatedDrawer(
        child: Drawer(
          backgroundColor: Colors.black,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Colors.black),
                child: Image.asset(
                  'assets/images/icone.png',
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
              _menuItem(Icons.home, "Início", () {
                _navigate(
                  () => HomePage(
                    nomeUsuario: widget.nomeUsuario,
                    emailUsuario: widget.emailUsuario,
                  ),
                );
              }),
              _menuItem(Icons.home, "Clientes", () {
                _navigate(() => ClientesPage());
              }),

              _menuItem(Icons.wallet, "Financeiro", () {
                _navigate(
                  () => FinanceiroPage(
                    nomeUsuario: widget.nomeUsuario,
                    emailUsuario: widget.emailUsuario,
                  ),
                );
              }),

              /*_menuItem(Icons.money, "Vendas", () {
                _navigate(() => NovaVendaPage());
              }),*/
              _menuItem(Icons.inventory_2, "Controle de Estoque", () {
                _navigate(
                  () => ControleEstoquePage(
                    nomeUsuario: widget.nomeUsuario,
                    emailUsuario: widget.emailUsuario,
                  ),
                );
              }),

              _menuItem(Icons.bolt, "Monitoramento", () {
                _navigate(
                  () => MonitoramentoClientesPage(
                    nomeUsuario: widget.nomeUsuario,
                    emailUsuario: widget.emailUsuario,
                  ),
                );
              }),

              _menuItem(Icons.build, "Operacional", () {
                _navigate(
                  () => OperacionalPage(
                    nomeUsuario: widget.nomeUsuario,
                    emailUsuario: widget.emailUsuario,
                  ),
                );
              }),

              _menuItem(Icons.assignment, "Projetos", () {
                _navigate(() => ProjetosPage());
              }),

              _menuItem(Icons.engineering, "Engenharia", () {
                _navigate(() => EngenhariaPage());
              }),

              _menuItem(Icons.settings, "Configurações", () {
                _navigate(() => ConfiguracoesPage());
              }),

              const Divider(color: corPrincipal),

              _menuItem(Icons.logout, "Sair", () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/');
              }),
            ],
          ),
        ),
      ),

      onDrawerChanged: (isOpen) {
        setState(() => drawerAberto = isOpen);
      },

      body: Stack(
        children: [
          widget.corpo,

          // 🔥 BLUR AO ABRIR O DRAWER
          if (drawerAberto)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(color: Colors.black.withOpacity(0.4)),
                ),
              ),
            ),
        ],
      ),

      backgroundColor: Colors.black,
    );
  }

  void _navigate(Widget Function() page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page()));
  }

  Widget _menuItem(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: corPrincipal),
      title: Text(
        text,
        style: const TextStyle(
          color: corPrincipal,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      hoverColor: corPrincipal.withOpacity(0.1),
    );
  }
}

/// 🔥 Drawer animado (slide + fade)
class AnimatedDrawer extends StatelessWidget {
  final Widget child;

  const AnimatedDrawer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -1, end: 0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(value * 260, 0),
          child: Opacity(opacity: 1 + value, child: child),
        );
      },
    );
  }
}
