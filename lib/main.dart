import 'package:flutter/material.dart';
import 'package:zeroone/pages/pagina_inicial.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color corPrincipal = Color(0xFFBBFB04);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vypmchzskenrlqximmjk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ5cG1jaHpza2VucmxxeGltbWprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxMDg2MzAsImV4cCI6MjA4NTY4NDYzMH0.uF3dLxEuX6uNvBW7cPMtUdx6zeEbYIt5DyqTNZj-ajg',
    authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZeroOne',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.black,
          labelStyle: const TextStyle(color: corPrincipal),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: corPrincipal),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: corPrincipal, width: 2),
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
  List<bool> isSelected = [true, false];
  bool get isLogin => isSelected[0];

  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  bool carregando = false;

  Future<void> _autenticar() async {
    if (emailController.text.isEmpty || senhaController.text.isEmpty) {
      _msg("Preencha email e senha");
      return;
    }

    if (!isLogin && nomeController.text.isEmpty) {
      _msg("Informe seu nome");
      return;
    }

    setState(() => carregando = true);

    try {
      User? user;

      if (isLogin) {
        final res = await supabase.auth.signInWithPassword(
          email: emailController.text,
          password: senhaController.text,
        );
        user = res.user;
      } else {
        final res = await supabase.auth.signUp(
          email: emailController.text,
          password: senhaController.text,
        );
        user = res.user;

        if (user != null) {
          await supabase.from('usuarios').insert({
            'id': user.id,
            'nome': nomeController.text,
            'email': emailController.text,
          });
        }
      }

      if (user == null) throw 'Falha na autenticação';

      // 🔎 Buscar ou criar perfil
      final perfil = await supabase
          .from('usuarios')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (perfil == null) {
        await supabase.from('usuarios').insert({
          'id': user.id,
          'nome': nomeController.text.isNotEmpty
              ? nomeController.text
              : 'Usuário',
          'email': emailController.text,
        });
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            nomeUsuario: perfil?['nome'] ?? 'Usuário',
            emailUsuario: perfil?['email'] ?? emailController.text,
          ),
        ),
      );
    } catch (e) {
      _msg(e.toString());
    }

    setState(() => carregando = false);
  }

  void _msg(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Image.asset('assets/images/icone.png', height: 120),
              const SizedBox(height: 20),
              const Text(
                "PhaseOne",
                style: TextStyle(
                  color: corPrincipal,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              ToggleButtons(
                isSelected: isSelected,
                onPressed: (i) => setState(() => isSelected = [i == 0, i == 1]),
                borderRadius: BorderRadius.circular(20),
                selectedColor: Colors.black,
                fillColor: corPrincipal,
                color: corPrincipal,
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Text("Entrar"),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Text("Cadastrar"),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              if (!isLogin)
                TextField(
                  controller: nomeController,
                  style: const TextStyle(color: corPrincipal),
                  decoration: const InputDecoration(labelText: "Nome"),
                ),

              const SizedBox(height: 16),

              TextField(
                controller: emailController,
                style: const TextStyle(color: corPrincipal),
                decoration: const InputDecoration(labelText: "E-mail"),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: senhaController,
                obscureText: true,
                style: const TextStyle(color: corPrincipal),
                decoration: const InputDecoration(labelText: "Senha"),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: carregando ? null : _autenticar,
                style: ElevatedButton.styleFrom(backgroundColor: corPrincipal),
                child: carregando
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        isLogin ? "Entrar" : "Cadastrar",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
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
