import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:nashwaluthfiya_124230016_pam_a/services/hive_service.dart';

class AuthController {
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<bool> register(String username, String email, String password) async {
    final exists = HiveService.getUser(username);
    if (exists != null) return false;
    final hash = _hashPassword(password);
    await HiveService.insertUser(username, email, hash);
    return true;
  }

  Future<bool> login(String usernameOrEmail, String password) async {
    final username = HiveService.findUsernameByUsernameOrEmail(usernameOrEmail);
    if (username == null) return false;
    final storedHash = HiveService.getUserPasswordHash(username);
    if (storedHash == null) return false;
    final inputHash = _hashPassword(password);
    if (inputHash == storedHash) {
      await HiveService.saveSession(username);
      return true;
    }
    return false;
  }

  String? getSession() => HiveService.getCurrentUser();
  String? getUserEmail(String username) => HiveService.getUserEmail(username);
  Future<void> logout() async => HiveService.clearSession();
}