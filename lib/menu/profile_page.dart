import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../services/hive_service.dart';
import '../controllers/auth_controller.dart';
import 'login_page.dart'; 
import 'home_page.dart'; 

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = AuthController();
  String? _username;
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
      final path = HiveService.getUserPhoto(username); 
      setState(() {
        _username = username;
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil berhasil diunggah!'), backgroundColor: Color(0xFF4CAF50)),
          );
        }
      } catch (e) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan foto: $e'), backgroundColor: Colors.redAccent),
          );
        }
        setState(() => _loading = false);
      }
    }
  }

  void _onLogout() async {
    await _auth.logout(); 
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget profileImage = CircleAvatar(
      radius: 60,
      backgroundColor: const Color(0xFFC8E6C9),
      child: Icon(Icons.person, size: 70, color: const Color(0xFF4CAF50)),
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
      appBar: AppBar(
        title: const Text('Profil Pengguna', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4CAF50),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300, width: 2)
                      ),
                      child: _loading 
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 15, height: 15, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4CAF50))
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.camera_alt, color: Color(0xFF4CAF50), size: 22),
                            onPressed: _pickImage,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text('Selamat Datang Kembali!', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              Text(
                _username ?? 'Memuat...', 
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))
              ),
              const Divider(height: 32),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.inventory, color: Color(0xFF4CAF50)),
                      title: const Text('Stok Anda'),
                      subtitle: const Text('Lihat ringkasan stok Anda.'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage())),
                    ),
                    ListTile(
                      leading: const Icon(Icons.email, color: Color(0xFF4CAF50)),
                      title: const Text('Email Kontak'),
                      subtitle: Text(_username != null ? '$_username@gmail.com' : 'Memuat...'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.chat_bubble, color: Color(0xFF4CAF50)),
                      title: const Text('Kesan'),
                      subtitle: const Text('Seru, tapi bikin laptop dan otak kepanasan'),
                    ),
                      ListTile(
                      leading: const Icon(Icons.lightbulb, color: Color(0xFF4CAF50)),
                      title: const Text('Saran'),
                      subtitle: const Text('Lebih baik tahun depan kita tidak bertemu lagi di mata kuliah ini'),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _onLogout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Logout', style: TextStyle(fontSize: 18, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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