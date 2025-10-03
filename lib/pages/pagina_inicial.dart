import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  @override
  void initState() {
    super.initState();
    _verificarLocalizacao();
  }

  Future<void> _verificarLocalizacao() async {
    bool servicoAtivo;
    LocationPermission permissao;

    // Verifica se GPS está ativo
    servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo) {
      setState(() => _status = "Ative o GPS para continuar");
      return;
    }

    // Verifica permissões
    permissao = await Geolocator.checkPermission();
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

    // Obtém posição atual
    Position posicao = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _posicao = posicao;

    // Converte para endereço
    List<Placemark> placemarks = await placemarkFromCoordinates(
      posicao.latitude,
      posicao.longitude,
    );

    if (placemarks.isNotEmpty) {
      String estado = placemarks.first.administrativeArea ?? "";

      if (estado.toLowerCase().contains("pará") ||
          estado.toLowerCase().contains("para")) {
        setState(() => _status = "✅ Você está no Pará!");
      } else {
        setState(
          () => _status =
              "❌ Acesso permitido apenas no Pará.\nLocal detectado: $estado",
        );
      }
    } else {
      setState(() => _status = "Não foi possível determinar a localização.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bem-vindo, ${widget.nomeUsuario}")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.black),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: const NetworkImage(
                      "https://via.placeholder.com/150",
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.nomeUsuario,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.emailUsuario,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Início"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Perfil"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Sair"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
      body: _posicao == null
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
                  padding: const EdgeInsets.all(12),
                  color: Colors.black87,
                  width: double.infinity,
                  child: Text(
                    _status,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
    );
  }
}
