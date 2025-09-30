import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = "http://localhost:8080/app";
  // 👉 se usar celular físico, troque por IP da sua máquina (ex: http://192.168.0.10/app)

  static Future<Map<String, dynamic>> login(String email, String senha) async {
    var url = Uri.parse("$baseUrl/login_one.php");
    var response = await http.post(url, body: {"email": email, "senha": senha});

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> cadastrar(
    String nome,
    String email,
    String senha,
  ) async {
    var url = Uri.parse("$baseUrl/cadastro_one.php");
    var response = await http.post(
      url,
      body: {"nome": nome, "email": email, "senha": senha},
    );
    return jsonDecode(response.body);
  }
}
