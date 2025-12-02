import 'package:flutter/material.dart';
import 'package:nashwaluthfiya_124230016_pam_a/controllers/auth_controller.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _auth = AuthController();
  final _u = TextEditingController();
  final _p = TextEditingController();
  final _c = TextEditingController();
  bool _loading = false;

  void _onRegister() async {
    final username = _u.text.trim();
    final password = _p.text;
    final confirm = _c.text;

    if (username.isEmpty || password.isEmpty || confirm.isEmpty) {
      _msg("Semua field wajib diisi", false);
      return;
    }
    if (password != confirm) {
      _msg("Konfirmasi password tidak sama", false);
      return;
    }

    setState(() => _loading = true);
    final ok = await _auth.register(username, password);
    setState(() => _loading = false);

    if (ok) {
      _msg("Registrasi berhasil! Silakan login", true);
      Future.delayed(const Duration(milliseconds: 600), () {
        Navigator.pop(context); // kembali ke login page
      });
    } else {
      _msg("Username sudah terdaftar", false);
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
              Text("Buat akun baru sekarang",
                  style: TextStyle(fontSize: 14, color: Colors.white)),
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
                const SizedBox(height: 16),
                _field(_c, "Konfirmasi Password", Icons.lock_outline, isPass: true),
                const SizedBox(height: 24),
                _submitBtn(),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    "Sudah punya akun? Login",
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
        prefixIcon: Icon(icon, color: Color(0xFF4CAF50)),
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
          onPressed: _loading ? null : _onRegister,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _loading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("DAFTAR", style: TextStyle(fontSize: 16)),
        ),
      );
}