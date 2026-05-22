import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart'; // Importante para o mini mapa
import 'painel_cliente_solar_page.dart';

const Color corPrincipal = Color(0xFFBBFB04);
const Color fundoPreto = Colors.black;
const Color cardPreto = Color.fromARGB(255, 20, 20, 20);

final supabase = Supabase.instance.client;

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  bool carregando = true;
  List<Map<String, dynamic>> clientes = [];
  final String apiKey = "1a791ec909e266fe642547a621b5123f";

  @override
  void initState() {
    super.initState();
    carregarClientes();
  }

  Future<void> carregarClientes() async {
    setState(() => carregando = true);
    try {
      final response = await supabase
          .from('clientes')
          .select()
          .order('id', ascending: false);

      clientes = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar clientes: $e')));
    }
    setState(() => carregando = false);
  }

  // ================= GEOCODIFICAÇÃO (STR ➔ LAT/LNG) =================
  Future<LatLng?> _obterCoordenadas(
    String rua,
    String numero,
    String bairro,
    String cidade,
    String estado,
  ) async {
    final Map<String, String> headersApi = {
      'User-Agent': 'MeuAppSolar/1.0 (joaopedrodevweb@gmail.com)',
      'Accept-Language': 'pt-BR,pt;q=0.9',
    };

    //1 TENTATIVA
    String queryCompleta = "$rua, $numero - $bairro, $cidade - $estado, Brasil";
    final urlCompleta = Uri.parse(
      "https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(queryCompleta)}&format=json&limit=1",
    );
    try {
      print("Tentando geocodificação completa: $queryCompleta");
      final response = await http
          .get(urlCompleta, headers: headersApi)
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final List dados = json.decode(response.body);
        if (dados.isNotEmpty) {
          return LatLng(
            double.parse(dados[0]['lat']),
            double.parse(dados[0]['lon']),
          );
        }
      }
    } catch (e) {
      print("Erro na tentativa 1: $e");
    }
    //2 TENTATIVA
    String querySemNumero = "$rua, $cidade - $estado, Brasil";
    final urlSemNumero = Uri.parse(
      "https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(querySemNumero)}&format=json&limit=1",
    );
    try {
      print("Tentativa 2 (Sem número): $querySemNumero");
      final response = await http
          .get(urlSemNumero, headers: headersApi)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List dados = json.decode(response.body);
        if (dados.isEmpty) {
          print("Endereço encontrado aproximado");
          return LatLng(
            double.parse(dados[0]['lat']),
            double.parse(dados[0]['lon']),
          );
        }
      }
    } catch (e) {
      print("Erro na tentativa 2: $e");
    }

    //3 TENTATIVA
    String queryCidade = "$cidade - $estado, Brasil";
    final urlCidade = Uri.parse(
      "https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(queryCidade)}&format=json&limit=1",
    );

    try {
      print("Tentativa 3: $queryCidade");
      final response = await http
          .get(urlCidade, headers: headersApi)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List dados = json.decode(response.body);
        if (dados.isNotEmpty) {
          print("Endereço encontado aproximado pela cidade");
          return LatLng(
            double.parse(dados[0]['lat']),
            double.parse(dados[0]['lon']),
          );
        }
      }
    } catch (e) {
      print("Erro na tentativa 3: $e");
    }
    return null;
  }

  // ================= CADASTRO CLIENTE COM PREVIEW =================
  void abrirCadastroCliente() {
    final nomeCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telefoneCtrl = TextEditingController();

    // Controllers destrinchados do Endereço
    final ruaCtrl = TextEditingController();
    final numeroCtrl = TextEditingController();
    final bairroCtrl = TextEditingController();
    final cidadeCtrl = TextEditingController();
    final estadoCtrl = TextEditingController();
    final cepCtrl = TextEditingController();

    // Estados locais do Dialog
    bool salvandoNoDialog = false;
    bool buscandoCoordenadas = false;
    LatLng? coordenadasPreview;
    final MapController miniMapController = MapController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Função interna para disparar a busca do preview
            void buscarPreviewLocalizacao() async {
              if (cidadeCtrl.text.isEmpty || ruaCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Digite ao menos a Rua e a Cidade para o preview.',
                    ),
                  ),
                );
                return;
              }

              setDialogState(() => buscandoCoordenadas = true);

              // Junta as partes para enviar à API de mapas
              String enderecoCompleto =
                  "${ruaCtrl.text.trim()}, ${numeroCtrl.text.trim()} - ${bairroCtrl.text.trim()}, ${cidadeCtrl.text.trim()} - ${estadoCtrl.text.trim()}, Brasil";
              LatLng? local = await _obterCoordenadas(
                ruaCtrl.text.trim(),
                numeroCtrl.text.trim(),
                bairroCtrl.text.trim(),
                cidadeCtrl.text.trim(),
                estadoCtrl.text.trim(),
              );

              setDialogState(() {
                buscandoCoordenadas = false;
                if (local != null) {
                  coordenadasPreview = local;
                  // Move a câmera do mini mapa para o ponto encontrado
                  miniMapController.move(local, 15);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Não foi possível gerar o preview deste endereço.',
                      ),
                    ),
                  );
                }
              });
            }

            return AlertDialog(
              backgroundColor: cardPreto,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Novo Cliente',
                style: TextStyle(color: corPrincipal),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _campo(nomeCtrl, 'Nome'),
                      _campo(emailCtrl, 'Email'),
                      _campo(telefoneCtrl, 'Telefone'),
                      const Divider(color: Colors.white24, height: 20),

                      // Grid / Linhas do Endereço Destrinchado
                      Row(
                        children: [
                          Expanded(flex: 3, child: _campo(ruaCtrl, 'Rua')),
                          const SizedBox(width: 8),
                          Expanded(flex: 1, child: _campo(numeroCtrl, 'Nº')),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: _campo(bairroCtrl, 'Bairro')),
                          const SizedBox(width: 8),
                          Expanded(child: _campo(cepCtrl, 'CEP')),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _campo(cidadeCtrl, 'Cidade'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(flex: 1, child: _campo(estadoCtrl, 'UF')),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Botão de Preview do Mapa
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: corPrincipal),
                          foregroundColor: corPrincipal,
                        ),
                        onPressed: buscandoCoordenadas
                            ? null
                            : buscarPreviewLocalizacao,
                        icon: buscandoCoordenadas
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: corPrincipal,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.map_outlined, size: 18),
                        label: const Text('Verificar no Mapa'),
                      ),

                      const SizedBox(height: 12),

                      // WIDGET DO MINI MAPA (PREVIEW)
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: coordenadasPreview != null
                                ? corPrincipal
                                : Colors.white24,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: FlutterMap(
                            mapController: miniMapController,
                            options: MapOptions(
                              initialCenter:
                                  coordenadasPreview ??
                                  const LatLng(
                                    -23.55052,
                                    -46.633308,
                                  ), // Padrão SP caso nulo
                              initialZoom: coordenadasPreview != null ? 15 : 4,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png",
                                subdomains: const ['a', 'b', 'c', 'd'],
                              ),
                              if (coordenadasPreview != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: coordenadasPreview!,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.redAccent,
                                        size: 30,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: corPrincipal,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: salvandoNoDialog
                      ? null
                      : () async {
                          if (nomeCtrl.text.trim().isEmpty ||
                              cidadeCtrl.text.trim().isEmpty ||
                              ruaCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Nome, Rua e Cidade são obrigatórios.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => salvandoNoDialog = true);

                          try {
                            String enderecoFormatado =
                                "${ruaCtrl.text.trim()}, ${numeroCtrl.text.trim()} - ${cidadeCtrl.text.trim()}";

                            // 1. Se o usuário ainda não clicou em verificar, busca a coordenada antes de salvar
                            coordenadasPreview ??= await _obterCoordenadas(
                              ruaCtrl.text.trim(),
                              numeroCtrl.text.trim(),
                              bairroCtrl.text.trim(),
                              cidadeCtrl.text.trim(),
                              estadoCtrl.text.trim(),
                            );

                            // 2. Salva no banco (Campos Destrinchados)
                            await supabase.from('clientes').insert({
                              'nome': nomeCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                              'telefone': telefoneCtrl.text.trim(),
                              'rua': ruaCtrl.text.trim(),
                              'numero': numeroCtrl.text.trim(),
                              'bairro': bairroCtrl.text.trim(),
                              'cidade': cidadeCtrl.text.trim(),
                              'estado': estadoCtrl.text.trim().toUpperCase(),
                              'cep': cepCtrl.text.trim(),
                              'endereco': enderecoFormatado,
                              'latitude': coordenadasPreview?.latitude,
                              'longitude': coordenadasPreview
                                  ?.longitude, // Mantido para compatibilidade de listagem
                            });

                            Navigator.pop(context); // Fecha Dialog

                            if (coordenadasPreview != null) {
                              Navigator.pop(context, {
                                "nome": nomeCtrl.text.trim(),
                                "coordenadas": coordenadasPreview,
                              });
                            } else {
                              carregarClientes();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Cliente salvo sem marcador geográfico.',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => salvandoNoDialog = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao salvar: $e')),
                            );
                          }
                        },
                  child: salvandoNoDialog
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================= UI LISTAGEM DE CLIENTES =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundoPreto,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: corPrincipal,
        title: const Text('Clientes'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: corPrincipal,
        foregroundColor: Colors.black,
        onPressed: abrirCadastroCliente,
        icon: const Icon(Icons.add),
        label: const Text('Novo Cliente'),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator(color: corPrincipal))
          : clientes.isEmpty
          ? const Center(
              child: Text(
                'Nenhum cliente cadastrado',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: clientes.length,
              itemBuilder: (_, i) {
                final c = clientes[i];

                // Constrói exibição amigável do endereço para o card
                String exibeEndereco = "";
                if (c['rua'] != null) {
                  exibeEndereco =
                      "${c['rua']}, ${c['numero'] ?? 'S/N'} - ${c['bairro'] ?? ''} (${c['cidade'] ?? ''}/${c['estado'] ?? ''})";
                } else {
                  exibeEndereco = c['endereco'] ?? '';
                }

                return Card(
                  color: cardPreto,
                  child: ListTile(
                    leading: const Icon(Icons.person, color: corPrincipal),
                    title: Text(
                      c['nome'] ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${c['email'] ?? ''} • ${c['telefone'] ?? ''}',
                          style: const TextStyle(
                            color: corPrincipal,
                            fontSize: 12,
                          ),
                        ),
                        if (exibeEndereco.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              exibeEndereco,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 11,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PainelSolarClientePage(
                            clienteId: c['id'].toString(),
                            nomeCliente: c['nome'] ?? '',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  // ================= CAMPO INPUT REUTILIZÁVEL =================
  Widget _campo(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: corPrincipal, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          filled: true,
          fillColor: fundoPreto,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: corPrincipal),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: corPrincipal, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
