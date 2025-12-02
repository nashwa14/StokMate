import 'package:flutter/material.dart';
import 'package:nashwaluthfiya_124230016_pam_a/controllers/auth_controller.dart';
import 'package:nashwaluthfiya_124230016_pam_a/menu/register_page.dart';
import 'package:nashwaluthfiya_124230016_pam_a/menu/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthController();
  final _u = TextEditingController();
  final _p = TextEditingController();
  bool _loading = false;

  void _onLogin() async {
    final username = _u.text.trim();
    final password = _p.text;

    if (username.isEmpty || password.isEmpty) {
      _msg("Isi username & password!", false);
      return;
    }

    setState(() => _loading = true);
    final ok = await _auth.login(username, password);
    setState(() => _loading = false);

    if (ok) {
      _msg("Login berhasil", true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      _msg("Username atau password salah", false);
    }
  }

  void _msg(String text, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: success ? Colors.green : Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(),
            _formCard(),
          ],
        ),
      ),
    );
  }

  Widget _header() => Container(
        width: double.infinity,
        height: 160,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.only(top: 50),
          child: Column(
            children: [
              Text("StokMate",
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 6),
            ],
          ),
        ),
      );

  Widget _formCard() => Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _field(_u, "Username", Icons.person),
                const SizedBox(height: 16),
                _field(_p, "Password", Icons.lock, isPass: true),
                const SizedBox(height: 24),
                _submitBtn(),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: const Text(
                    "Belum punya akun? Daftar",
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      );

  Widget _field(TextEditingController c, String label, IconData icon,
      {bool isPass = false}) {
    return TextField(
      controller: c,
      obscureText: isPass,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4CAF50)),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: _border(),
        focusedBorder: _border(focused: true),
      ),
    );
  }

  OutlineInputBorder _border({bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: focused ? const Color(0xFF4CAF50) : const Color(0xFFC8E6C9),
        width: focused ? 2 : 1,
      ),
    );
  }

  Widget _submitBtn() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : _onLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _loading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("LOGIN", style: TextStyle(fontSize: 16)),
        ),
      );
}