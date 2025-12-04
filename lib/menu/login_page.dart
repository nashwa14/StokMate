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
  bool _obscurePassword = true;

  @override
  void dispose() {
    _u.dispose();
    _p.dispose();
    super.dispose();
  }

  void _onLogin() async {
    final usernameOrEmail = _u.text.trim();
    final password = _p.text;
    if (usernameOrEmail.isEmpty || password.isEmpty) {
      _showSnackbar("Isi username/email & password!", SnackbarType.error);
      return;
    }

    setState(() => _loading = true);
    final ok = await _auth.login(usernameOrEmail, password);
    setState(() => _loading = false);

    if (ok) {
      final username = _auth.getSession();
      _showSnackbar("Berhasil Login! Selamat Datang ${username ?? 'User'}", SnackbarType.success);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } else {
      _showSnackbar("Username/Email atau password salah", SnackbarType.error);
    }
  }

  void _showSnackbar(String text, SnackbarType type) {
    Color backgroundColor;
    IconData icon;
    
    switch (type) {
      case SnackbarType.success:
        backgroundColor = const Color(0xFF26A69A);
        icon = Icons.check_circle_outline;
        break;
      case SnackbarType.error:
        backgroundColor = const Color(0xFFFF6B6B);
        icon = Icons.error_outline;
        break;
      case SnackbarType.warning:
        backgroundColor = const Color(0xFFFFB74D);
        icon = Icons.warning_amber_rounded;
        break;
      case SnackbarType.info:
        backgroundColor = const Color(0xFF4FC3F7);
        icon = Icons.info_outline;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF26A69A),
              const Color(0xFF4DB6AC),
              const Color(0xFF80CBC4),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 40),
                  _buildLoginCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.inventory_2_rounded,
            size: 60,
            color: Color(0xFF26A69A),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'StokMate',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF7F0EA),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Kelola stok dengan mudah',
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFFF7F0EA).withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Selamat Datang',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00695C),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Silakan login untuk melanjutkan',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF00796B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildTextField(
            controller: _u,
            label: 'Username atau Email',
            icon: Icons.person_outline,
            hint: 'Masukkan username atau email',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _p,
            label: 'Password',
            icon: Icons.lock_outline,
            hint: 'Masukkan password',
            isPassword: true,
          ),
          const SizedBox(height: 28),
          _buildLoginButton(),
          const SizedBox(height: 20),
          _buildRegisterLink(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF00695C),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: const Color(0xFF80CBC4)),
            prefixIcon: Icon(icon, color: const Color(0xFF26A69A)),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF80CBC4),
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFE0F7F4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF26A69A), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _loading ? null : _onLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: _loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text(
              'LOGIN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Belum punya akun? ',
          style: TextStyle(
            color: const Color(0xFF00796B),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterPage()),
            );
          },
          child: const Text(
            'Daftar',
            style: TextStyle(
              color: Color(0xFF26A69A),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

enum SnackbarType { success, error, warning, info }