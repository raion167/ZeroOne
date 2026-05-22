import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeroone/pages/clientes_page.dart';
import 'package:zeroone/pages/controle_estoque_page.dart';
import 'package:zeroone/pages/engenharia_page.dart';
import 'package:zeroone/pages/financeiro_page.dart';
import 'package:zeroone/pages/operacional_page.dart';
import 'package:zeroone/pages/projetos_page.dart';

const Color corPrincipal = Color(0xFFBBFB04);
final supabase = Supabase.instance.client;

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
  bool _loadingClima = true;
  List<Map<String, dynamic>> _clientesMapeados = [];

  String _temp = "--";
  String _climaDesc = "Carregando...";
  String _irradiacao = "---";

  final String apiKey = "1a791ec909e266fe642547a621b5123f";

  @override
  void initState() {
    super.initState();
    _inicializarDados();
  }

  // --- LÓGICA DE ÍCONES ---

  Widget _getIconeIrradiacao(String valorStr) {
    double valor = double.tryParse(valorStr) ?? 0;
    if (valor > 800) {
      return const Icon(Icons.trending_up, color: corPrincipal, size: 18);
    } else if (valor < 400) {
      return const Icon(Icons.trending_down, color: Colors.redAccent, size: 18);
    } else {
      return const Icon(Icons.trending_flat, color: Colors.amber, size: 18);
    }
  }

  IconData _getIconeClima(String descricao) {
    descricao = descricao.toLowerCase();
    if (descricao.contains("nublado") || descricao.contains("nuvens")) {
      return Icons.cloud_queue_rounded;
    } else if (descricao.contains("chuva") ||
        descricao.contains("garoa") ||
        descricao.contains("tempestade")) {
      return Icons.umbrella_rounded;
    } else if (descricao.contains("limpo") ||
        descricao.contains("sol") ||
        descricao.contains("claro")) {
      return Icons.wb_sunny_rounded;
    } else {
      return Icons.wb_cloudy_outlined;
    }
  }

  // --- MÉTODOS DE DADOS ---

  Future<void> _inicializarDados() async {
    await _verificarLocalizacao();
    await _buscarClientesDoBanco();
    if (_posicao != null) {
      _buscarClimaReal();
    }
  }

  // Nova função corrigida e blindada contra erros de iteração no Flutter Web
  Future<void> _buscarClientesDoBanco() async {
    try {
      final response = await supabase.from('clientes').select();

      // Criamos uma lista fortemente tipada vazia
      final List<Map<String, dynamic>> listaTemporaria = [];

      if (response != null && response is List) {
        for (var item in response) {
          // Converte com segurança cada linha vinda do banco
          final dadosCliente = Map<String, dynamic>.from(item);

          // Verifica se as coordenadas existem
          if (dadosCliente['latitude'] != null &&
              dadosCliente['longitude'] != null) {
            listaTemporaria.add(dadosCliente);
          }
        }
      }

      setState(() {
        _clientesMapeados =
            listaTemporaria; // Atribui a lista já filtrada e purificada
      });
    } catch (e) {
      print("Erro ao carregar marcadores dos clientes no mapa inicial: $e");
    }
  }

  Future<void> _verificarLocalizacao() async {
    try {
      LocationPermission permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      Position posicao = await Geolocator.getCurrentPosition();
      setState(() {
        _posicao = posicao;
      });
    } catch (e) {
      setState(() => _status = "Erro ao obter localização");
    }
  }

  Future<void> _buscarClimaReal() async {
    try {
      final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?lat=${_posicao!.latitude}&lon=${_posicao!.longitude}&appid=$apiKey&units=metric&lang=pt_br",
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _temp = "${data['main']['temp'].toStringAsFixed(0)}°C";
          _climaDesc = data['weather'][0]['description'].toUpperCase();
          int nuvens = data['clouds']['all'];
          double fatorNuvens = (1 - (nuvens / 100) * 0.75);
          _irradiacao = (1000 * fatorNuvens).toStringAsFixed(0);
          _loadingClima = false;
        });
      } else {
        _finalizarComErro("ERRO API");
      }
    } catch (e) {
      _finalizarComErro("OFFLINE");
    }
  }

  void _finalizarComErro(String mensagem) {
    setState(() {
      _climaDesc = mensagem;
      _temp = "--";
      _irradiacao = "0";
      _loadingClima = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    //CONSTRUÇÃO DINAMICA DA LISTA DE MARCADORES
    final List<Marker> todosOsMarcadores = [];
    //1. ADICIONA O PINO DO USUARIO LOGADO
    if (_posicao != null) {
      todosOsMarcadores.add(
        Marker(
          point: LatLng(_posicao!.latitude, _posicao!.longitude),
          width: 80,
          height: 80,
          child: const NeonMarker(),
        ),
      );
    }
    // 2. Loop para varrer e injetar os pins de cada cliente mapeado
    // 2. Loop para varrer e injetar os pins de cada cliente mapeado
    for (var cliente in _clientesMapeados) {
      // Força a conversão para String antes do parse para evitar erros caso venha como double ou String do banco
      final String? latStr = cliente['latitude']?.toString();
      final String? lonStr = cliente['longitude']?.toString();

      if (latStr != null && lonStr != null) {
        final double? lat = double.tryParse(latStr);
        final double? lon = double.tryParse(lonStr);

        if (lat != null && lon != null) {
          print(
            "Desenhando marcador para: ${cliente['nome']} em ($lat, $lon)",
          ); // <-- Para ver no console se passou aqui
          todosOsMarcadores.add(
            Marker(
              point: LatLng(lat, lon),
              width: 45,
              height: 45,
              child: Tooltip(
                message: cliente['nome'] ?? 'Cliente Sem Nome',
                triggerMode: TooltipTriggerMode.tap,
                child: const Icon(
                  Icons.location_on,
                  color: corPrincipal, // Cor Neon do seu app
                  size: 38,
                ),
              ),
            ),
          );
        }
      }
    }
    final List<Map<String, dynamic>> painelSolar = [
      {
        "nome": "Irradiação Solar",
        "valor": _irradiacao,
        "unidade": "W/m²",
        "tipo": "solar",
        "loading": _loadingClima,
      },
      {
        "nome": "Previsão",
        "valor": _temp,
        "unidade": _climaDesc,
        "tipo": "clima",
        "loading": _loadingClima,
      },
      {
        "nome": "Geração Hoje",
        "valor": "420",
        "unidade": "kWh",
        "tipo": "geracao",
        "loading": false,
      },
      {
        "nome": "Sistema",
        "valor": "Online",
        "unidade": "STATUS",
        "tipo": "status",
        "loading": false,
      },
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      body: _posicao == null
          ? Center(
              child: Text(_status, style: const TextStyle(color: Colors.white)),
            )
          : Stack(
              children: [
                FlutterMap(
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
                    ),
                    MarkerLayer(markers: todosOsMarcadores),
                  ],
                ),

                // MENU FLUTUANTE
                Positioned(
                  top: MediaQuery.of(context).padding.top + 15,
                  left: 15,
                  right: 15,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212).withOpacity(0.95),
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(
                          color: corPrincipal.withOpacity(0.4),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(35),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _BotaoMenuFlutuante(
                                icon: Icons.home_filled,
                                label: "Início",
                                isSelected: true,
                                onTap: () {},
                              ),
                              _BotaoMenuFlutuante(
                                icon: Icons.people_alt,
                                label: "Clientes",
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ClientesPage(),
                                  ),
                                ),
                              ),
                              _BotaoMenuFlutuante(
                                icon: Icons.inventory_2,
                                label: "Estoque",
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ControleEstoquePage(
                                      nomeUsuario: widget.nomeUsuario,
                                      emailUsuario: widget.emailUsuario,
                                    ),
                                  ),
                                ),
                              ),
                              _BotaoMenuFlutuante(
                                icon: Icons.account_balance_wallet,
                                label: "Financeiro",
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FinanceiroPage(
                                      nomeUsuario: widget.nomeUsuario,
                                      emailUsuario: widget.emailUsuario,
                                    ),
                                  ),
                                ),
                              ),
                              _BotaoMenuFlutuante(
                                icon: Icons.handyman,
                                label: "Operacional",
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OperacionalPage(
                                      nomeUsuario: widget.nomeUsuario,
                                      emailUsuario: widget.emailUsuario,
                                    ),
                                  ),
                                ),
                              ),
                              _BotaoMenuFlutuante(
                                icon: Icons.assignment,
                                label: "Projetos",
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProjetosPage(),
                                  ),
                                ),
                              ),
                              _BotaoMenuFlutuante(
                                icon: Icons.engineering,
                                label: "Engenharia",
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const EngenhariaPage(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // CARDS DE MONITORAMENTO INTEGRADOS
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: painelSolar.length,
                          itemBuilder: (context, index) {
                            final item = painelSolar[index];
                            return Container(
                              width: 175,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A).withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                              child: (item["loading"] ?? false)
                                  ? const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: corPrincipal,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              item["nome"],
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            // ÍCONE DINÂMICO AQUI
                                            if (item["tipo"] == "solar")
                                              _getIconeIrradiacao(
                                                item["valor"],
                                              ),
                                            if (item["tipo"] == "clima")
                                              IconeAnimadoClima(
                                                // <-- Usando o novo widget animado
                                                icon: _getIconeClima(
                                                  item["unidade"],
                                                ),
                                                color: corPrincipal,
                                                size: 20,
                                              ),
                                            if (item["tipo"] == "geracao")
                                              const Icon(
                                                Icons.flash_on,
                                                color: Colors.amber,
                                                size: 18,
                                              ),
                                            if (item["tipo"] == "status")
                                              const Icon(
                                                Icons.check_circle_outline,
                                                color: corPrincipal,
                                                size: 18,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item["valor"],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        Text(
                                          item["unidade"],
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: corPrincipal,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Row(
                          children: [
                            Icon(
                              Icons.api_rounded,
                              size: 12,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Dados climáticos via OpenWeatherMap",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 9,
                              ),
                            ),
                          ],
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

class _BotaoMenuFlutuante extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const _BotaoMenuFlutuante({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? corPrincipal : Colors.white70,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NeonMarker extends StatelessWidget {
  const NeonMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: corPrincipal.withOpacity(0.2),
            boxShadow: [
              BoxShadow(
                color: corPrincipal.withOpacity(0.6),
                blurRadius: 12,
                spreadRadius: 4,
              ),
            ],
          ),
        ),
        const Icon(Icons.bolt, color: Colors.black, size: 16),
      ],
    );
  }
}

class IconeAnimadoClima extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IconeAnimadoClima({
    super.key,
    required this.icon,
    required this.color,
    this.size = 18,
  });

  @override
  State<IconeAnimadoClima> createState() => _IconeAnimadoClimaState();
}

class _IconeAnimadoClimaState extends State<IconeAnimadoClima>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10), // Velocidade da rotação
      vsync: this,
    )..repeat(); // Faz girar infinitamente
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Se for sol, ele gira. Se for outra coisa, ele apenas pulsa ou fica estático.
    if (widget.icon == Icons.wb_sunny_rounded) {
      return RotationTransition(
        turns: _controller,
        child: Icon(widget.icon, color: widget.color, size: widget.size),
      );
    }

    // Para nuvens e outros, uma animação de "pulso" suave na escala
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.95, end: 1.05),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Icon(widget.icon, color: widget.color, size: widget.size),
        );
      },
      onEnd: () {}, // O TweenAnimationBuilder não repete nativamente fácil,
      // mas para ícones de clima, a rotação do sol é o principal.
    );
  }
}
