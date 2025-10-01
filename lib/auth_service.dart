import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = "http://localhost:8080/app";

  // 🔹 Cadastro
  static Future<Map<String, dynamic>> cadastrar(
    String nome,
    String email,
    String senha,
  ) async {
    final url = Uri.parse("$baseUrl/cadastro_one.php");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"}, // envia como JSON
      body: jsonEncode({"nome": nome, "email": email, "senha": senha}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Erro no servidor: ${response.statusCode}");
    }
  }

  // 🔹 Login
  static Future<Map<String, dynamic>> login(String email, String senha) async {
    final url = Uri.parse("$baseUrl/login_one.php");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"}, // envia como JSON
      body: jsonEncode({"email": email, "senha": senha}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Erro no servidor: ${response.statusCode}");
    }
  }
}
