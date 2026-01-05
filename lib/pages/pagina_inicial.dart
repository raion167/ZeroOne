import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:zeroone/pages/financeiro_page.dart';
import 'monitoramento_clientes_page.dart';
import 'menu_lateral.dart';

const Color corPrincipal = Color(0xFFBBFB04);

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
        setState(() => _status = "Permissão permanentemente negada");
        return;
      }

      Position posicao = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _posicao = posicao;
      setState(() {});
    } catch (e) {
      setState(() => _status = "Erro ao obter localização");
    }
  }

  @override
  Widget build(BuildContext context) {
    final alturaTela = MediaQuery.of(context).size.height;

    return BaseScaffold(
      titulo: "PhaseOne",
      nomeUsuario: widget.nomeUsuario,
      emailUsuario: widget.emailUsuario,
      corpo: _posicao == null
          ? Center(child: Text(_status))
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
                            "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png",
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.zeroone.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              _posicao!.latitude,
                              _posicao!.longitude,
                            ),
                            width: 90,
                            height: 90,
                            child: const NeonMarker(),
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
                            final positivo = item["mudanca"] >= 0;
                            final cor = positivo ? Colors.green : Colors.red;

                            return Card(
                              color: Colors.grey[900],
                              child: ListTile(
                                title: Text(
                                  item["nome"],
                                  style: const TextStyle(color: Colors.white),
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
                                      ),
                                    ),
                                    Text(
                                      "${positivo ? "+" : ""}${item["mudanca"]}%",
                                      style: TextStyle(
                                        color: cor,
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

/// 🔥 MARCADOR NEON COM PULSO (MONITORAMENTO)
class NeonMarker extends StatefulWidget {
  const NeonMarker({super.key});

  @override
  State<NeonMarker> createState() => _NeonMarkerState();
}

class _NeonMarkerState extends State<NeonMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final pulse = _controller.value;

        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 50 + pulse * 20,
              height: 50 + pulse * 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: corPrincipal.withOpacity(0.2 * (1 - pulse)),
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: corPrincipal,
                boxShadow: [
                  BoxShadow(
                    color: corPrincipal.withOpacity(0.9),
                    blurRadius: 20,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),
            const Icon(Icons.bolt, color: Colors.black, size: 16),
          ],
        );
      },
    );
  }
}
