import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  bool modoNoturno = false;
  double tamanhoFonte = 1.0;
  String versaoApp = "Carregando...";

  @override
  void initState() {
    super.initState();
    carregarPreferencias();
    carregarVersao();
  }

  Future<void> carregarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      modoNoturno = prefs.getBool("modoNoturno") ?? false;
      tamanhoFonte = prefs.getDouble("tamanhoFonte") ?? 1.0;
    });
  }

  Future<void> carregarVersao() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      versaoApp = info.version;
    });
  }

  Future<void> salvarModoNoturno(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool("modoNoturno", value);
    setState(() => modoNoturno = value);
  }

  Future<void> salvarTamanhoFonte(double value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble("tamanhoFonte", value);
    setState(() => tamanhoFonte = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configurações")),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          /// TEMA NOTURNO
          SwitchListTile(
            title: Text(
              "Modo Noturno",
              style: TextStyle(fontSize: 16 * tamanhoFonte),
            ),
            value: modoNoturno,
            onChanged: salvarModoNoturno,
            secondary: const Icon(Icons.dark_mode),
          ),

          const Divider(),

          /// TAMANHO DA FONTE
          ListTile(
            leading: const Icon(Icons.format_size),
            title: Text(
              "Tamanho da Fonte",
              style: TextStyle(fontSize: 16 * tamanhoFonte),
            ),
            subtitle: Slider(
              value: tamanhoFonte,
              min: 0.8,
              max: 1.6,
              divisions: 8,
              label: "${(tamanhoFonte * 100).round()}%",
              onChanged: salvarTamanhoFonte,
            ),
          ),

          const Divider(),

          /// VERSÃO DO APP
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(
              "Versão do Aplicativo",
              style: TextStyle(fontSize: 16 * tamanhoFonte),
            ),
            subtitle: Text(
              versaoApp,
              style: TextStyle(fontSize: 14 * tamanhoFonte),
            ),
          ),
        ],
      ),
    );
  }
}
