import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:nashwaluthfiya_124230016_pam_a/services/hive_service.dart';
import 'package:nashwaluthfiya_124230016_pam_a/controllers/auth_controller.dart';
import 'package:nashwaluthfiya_124230016_pam_a/menu/login_page.dart';
import 'package:nashwaluthfiya_124230016_pam_a/menu/home_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = AuthController();
  String? _username;
  String? _email;
  String? _imagePath;
  bool _loading = false;
  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final username = _auth.getSession();
    if (username != null) {
      final email = _auth.getUserEmail(username);
      final path = HiveService.getUserPhoto(username);
      setState(() {
        _username = username;
        _email = email;
        _imagePath = path;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null && _username != null) {
      setState(() => _loading = true);
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${_username}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localPath = p.join(appDir.path, fileName);

      try {
        final newImage = await File(pickedFile.path).copy(localPath);
        await HiveService.updateUserPhoto(_username!, newImage.path);
        if (mounted) {
          setState(() {
            _imagePath = newImage.path;
            _loading = false;
          });
          _showSnackbar('Foto profil berhasil diunggah!', SnackbarType.success);
        }
      } catch (e) {
        if (mounted) {
          _showSnackbar('Gagal menyimpan foto: $e', SnackbarType.error);
        }
        setState(() => _loading = false);
      }
    }
  }

  void _onLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFF5FFFE),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: Color(0xFFFF6B6B)),
            ),
            const SizedBox(width: 12),
            const Text(
              'Konfirmasi Logout',
              style: TextStyle(color: Color(0xFF00695C), fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun ini?',
          style: TextStyle(color: Color(0xFF00796B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF80CBC4))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _auth.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
        
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Anda berhasil logout',
                        style: TextStyle(color: Colors.white),
                      ),
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
    }
  }

  void _showSnackbar(String text, SnackbarType type) {
    if (!mounted) return;
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
        backgroundColor = const Color(0xFF4DB6AC);
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
    Widget profileImage = CircleAvatar(
      radius: 60,
      backgroundColor: const Color(0xFF80CBC4).withOpacity(0.3),
      child: Icon(Icons.person, size: 70, color: const Color(0xFF26A69A)),
    );
    if (_imagePath != null && _imagePath!.isNotEmpty) {
      final file = File(_imagePath!);
      if (file.existsSync()) {
        profileImage = CircleAvatar(
          radius: 60,
          backgroundImage: FileImage(file),
        );
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE0F7F4),
      appBar: AppBar(
        title: const Text('Profil Pengguna', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF26A69A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  profileImage,
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5FFFE),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF26A69A), width: 2),
                      ),
                      child: _loading
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF26A69A)),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.camera_alt, color: Color(0xFF26A69A), size: 22),
                              onPressed: _pickImage,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Selamat Datang Kembali!',
                style: TextStyle(color: const Color(0xFF00796B), fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                _username ?? 'Memuat...',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00695C),
                ),
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: const Color(0xFFF5FFFE),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF26A69A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.inventory, color: Color(0xFF26A69A)),
                      ),
                      title: const Text(
                        'Stok Anda',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF00695C)),
                      ),
                      subtitle: const Text(
                        'Lihat ringkasan stok Anda',
                        style: TextStyle(color: Color(0xFF00796B)),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF80CBC4)),
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage()),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFF80CBC4)),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF26A69A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person_outline, color: Color(0xFF26A69A)),
                      ),
                      title: const Text(
                        'Username',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF00695C)),
                      ),
                      subtitle: Text(
                        _username ?? 'Memuat...',
                        style: const TextStyle(color: Color(0xFF00796B)),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFF80CBC4)),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF26A69A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.email_outlined, color: Color(0xFF26A69A)),
                      ),
                      title: const Text(
                        'Email',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF00695C)),
                      ),
                      subtitle: Text(
                        _email ?? 'Memuat...',
                        style: const TextStyle(color: Color(0xFF00796B)),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFF80CBC4)),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4DB6AC).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF26A69A)),
                      ),
                      title: const Text(
                        'Kesan',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF00695C)),
                      ),
                      subtitle: const Text(
                        'Seru, tapi bikin laptop dan otak kepanasan',
                        style: TextStyle(color: Color(0xFF00796B)),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFF80CBC4)),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4DB6AC).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.lightbulb_outline, color: Color(0xFF26A69A)),
                      ),
                      title: const Text(
                        'Saran',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF00695C)),
                      ),
                      subtitle: const Text(
                        'Semoga kedepannya diselingi tugas yang agak banyak untuk membantu pahaman',
                        style: TextStyle(color: Color(0xFF00796B)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _onLogout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
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

enum SnackbarType { success, error, warning, info }