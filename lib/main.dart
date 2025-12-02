import 'package:flutter/material.dart';
import 'menu/login_page.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.initHive();
  await NotificationService.initialize();  
  await NotificationService.checkAndNotify();
  
  runApp(const StokMateApp());
}

class StokMateApp extends StatelessWidget {
  const StokMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StokMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const LoginPage(),
    );
  }
}