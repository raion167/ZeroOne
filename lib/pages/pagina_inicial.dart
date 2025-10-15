import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:zeroone/pages/financeiro_page.dart';
import 'monitoramento_clientes_page.dart';
import 'menu_lateral.dart';

class HomePage extends StatefulWidget {
  final String nomeUsuario;
  final String emailUsuario;

  const HomePage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = "Verificando localização...";
  Position? _posicao;

  // Dados simulados estilo "bolsa de valores"
  List<Map<String, dynamic>> painelSolar = [
    {"nome": "Consumo Atual", "valor": 350, "unidade": "kWh", "mudanca": 2.5},
    {"nome": "Geração Atual", "valor": 420, "unidade": "kWh", "mudanca": -1.2},
    {"nome": "Economia Mensal", "valor": 180, "unidade": "R\$", "mudanca": 3.1},
    {"nome": "Sistema", "valor": "Online", "unidade": "", "mudanca": 0},
  ];

  @override
  void initState() {
    super.initState();
    _verificarLocalizacao();
  }

  Future<void> _verificarLocalizacao() async {
    try {
      bool servicoAtivo = await Geolocator.isLocationServiceEnabled();
      if (!servicoAtivo) {
        setState(() => _status = "Ative o GPS para continuar");
        return;
      }

      LocationPermission permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
        if (permissao == LocationPermission.denied) {
          setState(() => _status = "Permissão de localização negada");
          return;
        }
      }

      if (permissao == LocationPermission.deniedForever) {
        setState(
          () => _status = "Permissão de localização permanentemente negada",
        );
        return;
      }

      Position posicao = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _posicao = posicao;

      List<Placemark> placemarks = await placemarkFromCoordinates(
        posicao.latitude,
        posicao.longitude,
      );

      if (placemarks.isNotEmpty) {
        String estado = placemarks.first.administrativeArea ?? "";
        setState(() {
          if (estado.toLowerCase().contains("pará") ||
              estado.toLowerCase().contains("para")) {
            _status = "✅ Você está no Pará!";
          } else {
            _status =
                "❌ Acesso permitido apenas no Pará.\nLocal detectado: $estado";
          }
        });
      } else {
        setState(() => _status = "Não foi possível determinar o endereço.");
      }
    } catch (e) {
      setState(() => _status = "Erro ao obter localização: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final alturaTela = MediaQuery.of(context).size.height;

    return BaseScaffold(
      titulo: "Bem-vindo, ${widget.nomeUsuario}",
      nomeUsuario: widget.nomeUsuario,
      emailUsuario: widget.emailUsuario,
      corpo: _posicao == null
          ? Center(
              child: Text(
                _status,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        _posicao!.latitude,
                        _posicao!.longitude,
                      ),
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              _posicao!.latitude,
                              _posicao!.longitude,
                            ),
                            width: 80,
                            height: 80,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.all(12),
                  height: alturaTela * 0.3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Monitoramento Solar",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: painelSolar.length,
                          itemBuilder: (context, index) {
                            final item = painelSolar[index];

                            if (item["nome"] == "Sistema") {
                              final bool online = item["valor"] == "Online";
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: online
                                        ? Colors.green
                                        : Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    online ? "ONLINE" : "OFFLINE",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final bool positivo = item["mudanca"] >= 0;
                            final cor = positivo ? Colors.green : Colors.red;
                            final String sinal = positivo ? "+" : "";
                            return Card(
                              color: Colors.grey[900],
                              elevation: 2,
                              child: ListTile(
                                title: Text(
                                  item["nome"],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${item["valor"]} ${item["unidade"]}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (item["mudanca"] != 0)
                                      Text(
                                        "$sinal${item["mudanca"]}%",
                                        style: TextStyle(
                                          color: cor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
