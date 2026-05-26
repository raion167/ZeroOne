import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color corPrincipal = Color(0xFFBBFB04);
final supabase = Supabase.instance.client;

class IntegracoesPage extends StatefulWidget {
  const IntegracoesPage({super.key});

  @override
  State<IntegracoesPage> createState() => _IntegracoesPageState();
}

class _IntegracoesPageState extends State<IntegracoesPage> {
  bool loading = true;
  List<Map<String, dynamic>> integracoes = [];

  String get userId => supabase.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _carregarIntegracoes();
  }

  // ================= BUSCA CONFIGURAÇÕES DO BANCO =================
  // ================= BUSCA CONFIGURAÇÕES DO BANCO =================
  Future<void> _carregarIntegracoes() async {
    setState(() => loading = true);
    try {
      final res = await supabase
          .from('api_integracoes')
          .select()
          .eq('user_id', userId);

      final dadosDoBanco = List<Map<String, dynamic>>.from(res);

      // Se a tabela existe mas está vazia para este usuário, injetamos os templates
      if (dadosDoBanco.isEmpty) {
        setState(() {
          integracoes = _gerarMocks();
          loading = false;
        });
      } else {
        // Se já houver dados salvos, mesclamos os salvos com os que faltam configurar
        List<Map<String, dynamic>> listaFinal = _gerarMocks();
        for (var i = 0; i < listaFinal.length; i++) {
          final salvo = dadosDoBanco.firstWhere(
            (element) => element['tipo_api'] == listaFinal[i]['tipo_api'],
            orElse: () => {},
          );
          if (salvo.isNotEmpty) {
            listaFinal[i] = salvo;
          }
        }
        setState(() {
          integracoes = listaFinal;
          loading = false;
        });
      }
    } catch (e) {
      print(
        "Aviso: Tabela não encontrada ou erro de conexão. Usando locais. Erro: $e",
      );
      // Força a exibição dos cards locais de forma segura se der erro
      setState(() {
        integracoes = _gerarMocks();
        loading = false;
      });
    }
  }

  // ================= LISTA PADRÃO SEGURO (MOCKS) =================
  List<Map<String, dynamic>> _gerarMocks() {
    return [
      {
        'tipo_api': 'Meta (Facebook/Instagram)',
        'status': 'Pendente',
        'credenciais': <String, String>{},
      },
      {
        'tipo_api': 'LinkedIn API',
        'status': 'Pendente',
        'credenciais': <String, String>{},
      },
      {
        'tipo_api': 'Stripe',
        'status': 'Pendente',
        'credenciais': <String, String>{},
      },
      {
        'tipo_api': 'Webhooks do Sistema',
        'status': 'Pendente',
        'credenciais': <String, String>{},
      },
    ];
  }

  // ================= SALVA OU ATUALIZA CRIDENCIAIS =================
  Future<void> _salvarConfiguracao(
    String tipo,
    Map<String, String> credenciais,
  ) async {
    try {
      await supabase.from('api_integracoes').upsert({
        'user_id': userId,
        'tipo_api': tipo,
        'credenciais': credenciais,
        'atualizado_em': DateTime.now().toIso8601String(),
        'status': 'Ativo',
      }, onConflict: 'user_id,tipo_api'); // Garante o Update se já existir

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Integração com $tipo salva com sucesso!')),
      );
      _carregarIntegracoes();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar no banco: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Integrações e APIs'),
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarIntegracoes,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: corPrincipal))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: integracoes.length,
              itemBuilder: (context, index) {
                final item = integracoes[index];
                bool ativo = item['status'] == 'Ativo';

                return Card(
                  color: Colors.black,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: ativo ? corPrincipal : Colors.white24,
                      width: ativo ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ativo
                            ? corPrincipal.withOpacity(0.1)
                            : Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIcone(item['tipo_api']),
                        color: ativo ? corPrincipal : Colors.white54,
                        size: 28,
                      ),
                    ),
                    title: Text(
                      item['tipo_api'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        ativo ? 'Status: Conectado' : 'Status: Desconectado',
                        style: TextStyle(
                          color: ativo ? corPrincipal : Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    trailing: Icon(
                      Icons.settings,
                      color: ativo ? corPrincipal : Colors.white70,
                    ),
                    onTap: () => _abrirConfigurador(item),
                  ),
                );
              },
            ),
    );
  }

  // ================= MODAL DE CONFIGURAÇÃO DE CREDENCIAIS =================
  void _abrirConfigurador(Map<String, dynamic> integracao) {
    final String tipo = integracao['tipo_api'];

    // Recupera chaves antigas se existirem
    final Map<String, dynamic> credsAntigas = integracao['credenciais'] ?? {};

    final controller1 = TextEditingController(
      text: credsAntigas['campo_principal'] ?? '',
    );
    final controller2 = TextEditingController(
      text: credsAntigas['campo_secundario'] ?? '',
    );

    // Altera os labels dependendo do tipo de serviço escolhido
    String label1 = "API Key / Token";
    String label2 = "Client ID / Endpoint URL";

    if (tipo == 'Stripe') {
      label1 = "Stripe Secret Key";
      label2 = "Webhook Secret Token";
    } else if (tipo == 'Meta (Facebook/Instagram)') {
      label1 = "Page Access Token";
      label2 = "App Secret ID";
    }

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(color: corPrincipal, width: 1.5),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Configurar $tipo",
                      style: const TextStyle(
                        color: corPrincipal,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _campoTexto(controller1, label1, false),
                    _campoTexto(controller2, label2, false),

                    const SizedBox(height: 25),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: corPrincipal,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            await _salvarConfiguracao(tipo, {
                              'campo_principal': controller1.text,
                              'campo_secundario': controller2.text,
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Salvar Credenciais',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= HELPERS DE INTERFACE =================
  Widget _campoTexto(TextEditingController c, String label, bool ocultar) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c,
        obscureText: ocultar,
        style: const TextStyle(color: Colors.white),
        cursorColor: corPrincipal,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: corPrincipal),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: corPrincipal),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: corPrincipal, width: 2),
          ),
        ),
      ),
    );
  }

  IconData _getIcone(String tipo) {
    switch (tipo) {
      case 'Stripe':
        return Icons.credit_card;
      case 'Meta (Facebook/Instagram)':
        return Icons.facebook;
      case 'LinkedIn API':
        return Icons.co_present;
      case 'Webhooks do Sistema':
        return Icons.webhook;
      default:
        return Icons.api;
    }
  }
}
