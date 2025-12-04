import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String usersBox = 'usersBox';
  static const String sessionBox = 'sessionBox';
  static const String inventoryBox = 'inventoryBox';

  static bool _initialized = false;
  static Future<void> initHive() async {
    if (_initialized) return;

    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(usersBox),
      Hive.openBox(sessionBox),
      Hive.openBox(inventoryBox),
    ]);

    _initialized = true;
    print("Hive initialized & boxes opened");
  }

  static Future<void> insertUser(String username, String email, String passwordHash) async {
    final box = Hive.box(usersBox);
    await box.put(username, {
      "email": email,
      "password": passwordHash,
      "photo": null,
    });
    print("User '$username' berhasil disimpan di Hive.");
  }

  static Map<String, dynamic>? getUser(String username) {
    final box = Hive.box(usersBox);
    final data = box.get(username);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  static String? getUserPasswordHash(String username) {
    final box = Hive.box(usersBox);
    final data = box.get(username);
    if (data is Map && data["password"] is String) {
      return data["password"] as String;
    }
    return null;
  }

  static String? getUserEmail(String username) {
    final box = Hive.box(usersBox);
    final data = box.get(username);
    if (data is Map && data["email"] is String) {
      return data["email"] as String;
    }
    return null;
  }

  static String? findUsernameByUsernameOrEmail(String usernameOrEmail) {
    final box = Hive.box(usersBox);
    
    if (box.containsKey(usernameOrEmail)) {
      return usernameOrEmail;
    }
    
    for (var key in box.keys) {
      final data = box.get(key);
      if (data is Map && data["email"] == usernameOrEmail) {
        return key.toString();
      }
    }
    return null;
  }

  static Future<void> updateUserPhoto(String username, String path) async {
    final box = Hive.box(usersBox);
    final data = box.get(username);
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      map["photo"] = path;
      await box.put(username, map);
      print("Foto profil user '$username' diperbarui.");
    }
  }

  static String? getUserPhoto(String username) {
    final box = Hive.box(usersBox);
    final data = box.get(username);
    if (data is Map && data["photo"] is String) {
      return data["photo"] as String;
    }
    return null;
  }

  static Future<void> saveSession(String username) async {
    await Hive.box(sessionBox).put("currentUser", username);
    print("Session disimpan untuk user: $username");
  }

  static String? getCurrentUser() {
    return Hive.box(sessionBox).get("currentUser") as String?;
  }

  static Future<void> clearSession() async {
    await Hive.box(sessionBox).delete("currentUser");
    print("Session dihapus");
  }

  static Future<Box> getInventoryBox() async {
    if (!_initialized) {
      print("Hive belum diinisialisasi, memanggil initHive() otomatis...");
      await initHive();
    }
    if (!Hive.isBoxOpen(inventoryBox)) {
      print("Membuka box: $inventoryBox...");
      await Hive.openBox(inventoryBox);
    }

    return Hive.box(inventoryBox);
  }

  static Future<void> addInventoryItem(
    String username,
    String id,
    Map<String, dynamic> data,
  ) async {
    final box = await getInventoryBox();
    final key = '${username}_$id';
    await box.put(key, data);
    print("Item '$key' berhasil ditambahkan ke inventory.");
  }

  static Future<void> updateInventoryItem(
    String username,
    String id,
    Map<String, dynamic> data,
  ) async {
    final box = await getInventoryBox();
    final key = '${username}_$id';
    await box.put(key, data);
    print("Item '$key' berhasil diperbarui di inventory.");
  }

  static Future<void> deleteInventoryItem(String username, String id) async {
    final box = await getInventoryBox();
    final key = '${username}_$id';
    await box.delete(key);
    print("Item '$key' berhasil dihapus dari inventory.");
  }

  static Future<List<Map<String, dynamic>>> getAllInventoryItems(String username) async {
    final box = await getInventoryBox();
    final List<Map<String, dynamic>> result = [];
    final prefix = '${username}_';
    for (final key in box.keys) {
      if (key.toString().startsWith(prefix)) {
        final value = box.get(key);
        if (value is Map) {
          result.add(Map<String, dynamic>.from(value));
        }
      }
    }
    return result;
  }

  static Future<void> clearAllData() async {
    await Hive.box(usersBox).clear();
    await Hive.box(sessionBox).clear();
    await Hive.box(inventoryBox).clear();
    print("Semua data Hive dihapus (users, session, inventory).");
  }
}