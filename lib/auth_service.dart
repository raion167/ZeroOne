import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;

  // 🔐 LOGIN
  static Future<Map<String, dynamic>> login(String email, String senha) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: senha,
      );

      final user = response.user;
      if (user == null) {
        return {"success": false, "message": "Usuário ou senha inválidos"};
      }

      // Buscar perfil
      final perfil = await _supabase
          .from('usuarios')
          .select()
          .eq('id', user.id)
          .single();

      return {
        "success": true,
        "message": "Login realizado com sucesso",
        "usuario": perfil,
      };
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // 📝 CADASTRO
  static Future<Map<String, dynamic>> cadastrar(
    String nome,
    String email,
    String senha,
  ) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: senha,
      );

      final user = response.user;
      if (user == null) {
        return {"success": false, "message": "Erro ao criar usuário"};
      }

      // Criar perfil
      await _supabase.from('usuarios').insert({
        'id': user.id, // UUID do auth.users
        'nome': nome,
        'email': email,
      });

      return {"success": true, "message": "Usuário cadastrado com sucesso"};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // 🚪 LOGOUT
  static Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}
