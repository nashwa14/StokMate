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

  static Future<void> insertUser(String username, String passwordHash) async {
    final box = Hive.box(usersBox);
    await box.put(username, {
      "password": passwordHash,
      "photo": null,
    });
    print("User '$username' berhasil disimpan di Hive.");
  }

  static Map? getUser(String username) {
    final box = Hive.box(usersBox);
    return box.get(username);
  }

  static String? getUserPasswordHash(String username) {
    final box = Hive.box(usersBox);
    final data = box.get(username);
    return data?["password"];
  }

  static Future<void> updateUserPhoto(String username, String path) async {
    final box = Hive.box(usersBox);
    final data = box.get(username);
    if (data != null) {
      data["photo"] = path;
      await box.put(username, data);
      print("Foto profil user '$username' diperbarui.");
    }
  }

  static String? getUserPhoto(String username) {
    final box = Hive.box(usersBox);
    final data = box.get(username);
    return data?["photo"];
  }

  static Future<void> saveSession(String username) async {
    await Hive.box(sessionBox).put("currentUser", username);
    print("Session disimpan untuk user: $username");
  }

  static String? getCurrentUser() {
    return Hive.box(sessionBox).get("currentUser");
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

  static Future<void> addInventoryItem(String id, Map<String, dynamic> data) async {
    final box = await getInventoryBox();
    await box.put(id, data);
    print("Item '$id' berhasil ditambahkan ke inventory.");
  }

  static Future<void> updateInventoryItem(String id, Map<String, dynamic> data) async {
    final box = await getInventoryBox();
    await box.put(id, data);
    print("Item '$id' berhasil diperbarui di inventory.");
  }

  static Future<void> deleteInventoryItem(String id) async {
    final box = await getInventoryBox();
    await box.delete(id);
    print("Item '$id' berhasil dihapus dari inventory.");
  }

  static Future<List<Map>> getAllInventoryItems() async {
    final box = await getInventoryBox();
    return box.values.cast<Map>().toList();
  }

  static Future<void> clearAllData() async {
    await Hive.box(usersBox).clear();
    await Hive.box(sessionBox).clear();
    await Hive.box(inventoryBox).clear();
    print("Semua data Hive dihapus (users, session, inventory).");
  }
}
