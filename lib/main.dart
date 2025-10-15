import 'package:flutter/material.dart';
import 'package:zeroone/pages/pagina_inicial.dart';
import 'auth_service.dart';
import 'dart:html' as html;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZeroOne',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  List<bool> isSelected = [true, false]; // Login / Cadastro
  bool get isLogin => isSelected[0];

  // Controladores dos campos
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  bool _carregando = false;

  void _autenticar() async {
    if (!isLogin) {
      // Cadastro
      if (nomeController.text.isEmpty ||
          emailController.text.isEmpty ||
          senhaController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Preencha todos os campos")),
        );
        return;
      }
    } else {
      // Login
      if (emailController.text.isEmpty || senhaController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Preencha email e senha")));
        return;
      }
    }
    setState(() => _carregando = true);

    try {
      Map<String, dynamic> resposta;

      if (isLogin) {
        resposta = await AuthService.login(
          emailController.text,
          senhaController.text,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(resposta["message"])));

        if (resposta["success"]) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                nomeUsuario: resposta["usuario"]["nome"],
                emailUsuario: resposta["usuario"]["email"],
              ),
            ),
          );
        }
      } else {
        resposta = await AuthService.cadastrar(
          nomeController.text,
          emailController.text,
          senhaController.text,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(resposta["message"])));
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(resposta["message"])));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }

    setState(() => _carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔹 Toggle Login / Cadastro
              ToggleButtons(
                isSelected: isSelected,
                borderRadius: BorderRadius.circular(20),
                selectedColor: Colors.white,
                fillColor: Colors.black,
                color: Colors.black,
                selectedBorderColor: Colors.black,
                borderColor: Colors.black,
                onPressed: (int index) {
                  setState(() {
                    for (int i = 0; i < isSelected.length; i++) {
                      isSelected[i] = (i == index);
                    }
                  });
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    child: Text("Entrar", style: TextStyle(fontSize: 16)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    child: Text("Cadastrar", style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // 🔹 Campo Nome só aparece no Cadastro
              if (!isLogin)
                Column(
                  children: [
                    TextField(
                      controller: nomeController,
                      decoration: const InputDecoration(
                        labelText: "Nome",
                        prefixIcon: Icon(Icons.person, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // 🔹 Campo Email
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "E-mail",
                  prefixIcon: Icon(Icons.email, color: Colors.black),
                ),
              ),
              const SizedBox(height: 16),

              // 🔹 Campo Senha
              TextField(
                controller: senhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Senha",
                  prefixIcon: Icon(Icons.lock, color: Colors.black),
                ),
              ),
              const SizedBox(height: 30),

              // 🔹 Botão de ação
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _carregando ? null : _autenticar,
                  child: _carregando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isLogin ? "Entrar" : "Cadastrar",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
