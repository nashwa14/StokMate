import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:nashwaluthfiya_124230016_pam_a/services/hive_service.dart';

class AuthController {
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<bool> register(String username, String password) async {
    final exists = HiveService.getUser(username);
    if (exists != null) return false; // username sudah ada

    final hash = _hashPassword(password);
    await HiveService.insertUser(username, hash);
    return true;
  }

  Future<bool> login(String username, String password) async {
    final storedHash = HiveService.getUserPasswordHash(username);
    if (storedHash == null) return false; // user tidak ada

    final inputHash = _hashPassword(password);
    if (inputHash == storedHash) {
      await HiveService.saveSession(username);
      return true;
    }
    return false;
  }

  String? getSession() => HiveService.getCurrentUser();
  Future<void> logout() async => HiveService.clearSession();
}