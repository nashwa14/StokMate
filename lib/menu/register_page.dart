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
  final _e = TextEditingController();
  final _p = TextEditingController();
  final _c = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _u.dispose();
    _e.dispose();
    _p.dispose();
    _c.dispose();
    super.dispose();
  }

  void _onRegister() async {
    final username = _u.text.trim();
    final email = _e.text.trim();
    final password = _p.text;
    final confirm = _c.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showSnackbar("Semua field wajib diisi", SnackbarType.error);
      return;
    }
    if (username.length < 3) {
      _showSnackbar("Username minimal 3 karakter", SnackbarType.warning);
      return;
    }
    if (!_isValidEmail(email)) {
      _showSnackbar("Format email tidak valid", SnackbarType.error);
      return;
    }
    if (password.length < 6) {
      _showSnackbar("Password minimal 6 karakter", SnackbarType.warning);
      return;
    }
    if (password != confirm) {
      _showSnackbar("Konfirmasi password tidak sama", SnackbarType.error);
      return;
    }

    setState(() => _loading = true);
    final ok = await _auth.register(username, email, password);
    setState(() => _loading = false);

    if (ok) {
      if (mounted) {
        Navigator.pop(context);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Berhasil Register!', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF26A69A),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      }
    } else {
      _showSnackbar("Username sudah terdaftar", SnackbarType.error);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
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
              child: Text(text, style: const TextStyle(color: Colors.white)),
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
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildRegisterCard(),
                      ],
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

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_rounded,
            size: 40,
            color: Color(0xFF26A69A),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Buat Akun Baru',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Daftar untuk mulai mengelola stok',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterCard() {
    return Container(
      padding: const EdgeInsets.all(28),
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
          _buildTextField(
            controller: _u,
            label: 'Username',
            icon: Icons.person_outline,
            hint: 'Pilih username unik',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _e,
            label: 'Email',
            icon: Icons.email_outlined,
            hint: 'contoh@email.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _p,
            label: 'Password',
            icon: Icons.lock_outline,
            hint: 'Minimal 6 karakter',
            isPassword: true,
            obscureValue: _obscurePassword,
            onToggleObscure: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _c,
            label: 'Konfirmasi Password',
            icon: Icons.lock_outline,
            hint: 'Ulangi password',
            isPassword: true,
            obscureValue: _obscureConfirm,
            onToggleObscure: () {
              setState(() => _obscureConfirm = !_obscureConfirm);
            },
          ),
          const SizedBox(height: 24),
          _buildPasswordHint(),
          const SizedBox(height: 24),
          _buildRegisterButton(),
          const SizedBox(height: 20),
          _buildLoginLink(),
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
    bool obscureValue = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
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
          obscureText: isPassword ? obscureValue : false,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: const Color(0xFF80CBC4)),
            prefixIcon: Icon(icon, color: const Color(0xFF26A69A)),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureValue ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF80CBC4),
                    ),
                    onPressed: onToggleObscure,
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

  Widget _buildPasswordHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF4FC3F7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4FC3F7).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: const Color(0xFF4FC3F7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Password minimal 6 karakter untuk keamanan',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF00796B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _loading ? null : _onRegister,
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
              'DAFTAR',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Sudah punya akun? ',
          style: TextStyle(
            color: const Color(0xFF00796B),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'Login',
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