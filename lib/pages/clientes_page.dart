import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
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

  // ================= GEOCODIFICAÇÃO ULTRA PRECISA (OSM) ================
  Future<LatLng?> _obterCoordenadas(
    String rua,
    String numero,
    String bairro,
    String cidade,
    String estado,
  ) async {
    String query = "$rua, $numero - $bairro, $cidade - $estado, Brasil";

    final urlUri = Uri.parse(
      "https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1",
    );

    try {
      final response = await http
          .get(
            urlUri,
            headers: {'User-Agent': 'MeuAppSolar/1.0 (seuemail@provedor.com)'},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List dados = json.decode(response.body);
        if (dados.isNotEmpty) {
          double lat = double.parse(dados[0]['lat']);
          double lon = double.parse(dados[0]['lon']);
          return LatLng(lat, lon);
        }
      }
    } catch (e) {
      print("Erro no geocoding principal: $e");
    }

    // --- FALLBACK (PLANO B) ---
    print("Rua não encontrada no OSM, tentando apenas pela cidade...");
    String queryCidade = "$cidade - $estado, Brasil";

    final urlCidadeUri = Uri.parse(
      "https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(queryCidade)}&format=json&limit=1",
    );

    try {
      final response = await http
          .get(urlCidadeUri, headers: {'User-Agent': 'MeuAppSolar/1.0'})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List dados = json.decode(response.body);
        if (dados.isNotEmpty) {
          return LatLng(
            double.parse(dados[0]['lat']),
            double.parse(dados[0]['lon']),
          );
        }
      }
    } catch (_) {}

    return null;
  }

  // ================= CADASTRO CLIENTE COM PREVIEW =================
  void abrirCadastroCliente() {
    final nomeCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telefoneCtrl = TextEditingController();

    final ruaCtrl = TextEditingController();
    final numeroCtrl = TextEditingController();
    final bairroCtrl = TextEditingController();
    final cidadeCtrl = TextEditingController();
    final estadoCtrl = TextEditingController();
    final cepCtrl = TextEditingController();

    bool salvandoNoDialog = false;
    bool buscandoCoordenadas = false;
    LatLng? coordenadasPreview;
    final MapController miniMapController = MapController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void buscarPreviewLocalizacao() async {
              if (cidadeCtrl.text.isEmpty ||
                  ruaCtrl.text.isEmpty ||
                  estadoCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preencha Rua, Cidade e UF para verificar.'),
                  ),
                );
                return;
              }

              setDialogState(() => buscandoCoordenadas = true);

              LatLng? local = await _obterCoordenadas(
                ruaCtrl.text.trim(),
                numeroCtrl.text.trim(),
                bairroCtrl.text.trim(),
                cidadeCtrl.text.trim(),
                estadoCtrl.text.trim(),
              );

              if (local != null) {
                setDialogState(() {
                  buscandoCoordenadas = false;
                  coordenadasPreview = local;
                });

                // CORREÇÃO AQUI: Aguarda o próximo frame para garantir que o FlutterMap
                // processou a existência das novas coordenadas antes de mover a câmara.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (miniMapController.mapEventStream != null) {
                    // Garante que o mapa está pronto
                    miniMapController.move(local, 15);
                  }
                });
              } else {
                setDialogState(() => buscandoCoordenadas = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Endereço não localizado. Verifique a ortografia.',
                    ),
                  ),
                );
              }
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
                                  const LatLng(-23.55052, -46.633308),
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

                            coordenadasPreview ??= await _obterCoordenadas(
                              ruaCtrl.text.trim(),
                              numeroCtrl.text.trim(),
                              bairroCtrl.text.trim(),
                              cidadeCtrl.text.trim(),
                              estadoCtrl.text.trim(),
                            );

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
                            });

                            // CORREÇÃO AQUI:
                            // 1. Fecha apenas o Dialog de cadastro
                            Navigator.pop(context);

                            // 2. Atualiza a lista da tela principal de clientes
                            carregarClientes();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Cliente cadastrado com sucesso!',
                                ),
                              ),
                            );
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
