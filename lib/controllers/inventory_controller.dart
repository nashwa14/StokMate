import '../models/inventory_models.dart';
import '../services/hive_service.dart';
import '../services/api_service.dart';
import 'dart:async';

class InventoryController {
  final ApiService _apiService = ApiService();

  Future<bool> saveItem(InventoryItem item) async {
    try {
      print("Menyimpan item ke Hive...");

      final box = await HiveService.getInventoryBox();

      final String id = (item.id ?? DateTime.now().millisecondsSinceEpoch).toString();
      item.id = id;

      await box.put(id, item.toMap()).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Waktu penyimpanan habis! Coba lagi dalam beberapa saat.');
        },
      );

      print("Item '${item.name}' berhasil disimpan (ID: $id)");
      return true;
    } on TimeoutException catch (e) {
      print("TIMEOUT: $e");
      rethrow;
    } catch (e, st) {
      print("Error saat menyimpan item ke Hive: $e");
      print("Stacktrace: $st");
      rethrow;
    }
  }

  Future<List<InventoryItem>> getAllItems() async {
    try {
      final box = await HiveService.getInventoryBox();

      print("Mengambil semua data inventory...");
      final List<InventoryItem> items = [];

      for (var key in box.keys) {
        final map = box.get(key);
        if (map is Map) {
          map['id'] = key.toString();
          items.add(InventoryItem.fromMap(map));
        }
      }

      print("Ditemukan ${items.length} item di inventory.");
      return items;
    } catch (e) {
      print("Error saat mengambil data dari Hive: $e");
      return [];
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      print("Menghapus item dengan ID: $id");
      await HiveService.deleteInventoryItem(id);
      print("Item $id berhasil dihapus.");
    } catch (e) {
      print("Gagal menghapus item $id: $e");
    }
  }

  Future<void> updateItem(InventoryItem item) async {
    try {
      final id = item.id?.toString();
      if (id == null) throw Exception("ID item tidak boleh null.");
      print("Update item (ID: $id)");

      await HiveService.updateInventoryItem(id, item.toMap());
      print("Item $id berhasil diperbarui.");
    } catch (e) {
      print("Gagal update item: $e");
    }
  }

  String getStatus(InventoryItem item) {
    try {
      if (item.quantity == 0) {
        return 'Stok Habis';
      }
      if (item.quantity <= 1) {
        return 'Stok Menipis';
      }

      final daysRemaining = item.expiryDate.difference(DateTime.now()).inDays;
      
      if (daysRemaining == 0) {
        return 'Kadaluarsa';
      }
      if (daysRemaining < 0) {
        return 'Kadaluarsa';
      }
      if (daysRemaining <= 7) {
        return 'Hampir Kadaluarsa (H-$daysRemaining hari)';
      }
      
      return 'Aman';
    } catch (e) {
      print("Gagal menghitung status item: $e");
      return 'Tidak diketahui';
    }
  }

  String getStockStatus(InventoryItem item) {
    if (item.quantity == 0) {
      return 'Stok Habis';
    }
    if (item.quantity == 1) {
      return 'Stok Menipis';
    }
    return 'Stok Aman';
  }

  String getExpiryStatus(InventoryItem item) {
    final daysRemaining = item.expiryDate.difference(DateTime.now()).inDays;
    
    if (daysRemaining <= 0) {
      return 'Kadaluarsa';
    }
    if (daysRemaining <= 7) {
      return 'Hampir Kadaluarsa (H-$daysRemaining hari)';
    }
    return 'Aman';
  }

  Future<Map<String, double>> getExchangeRates() async {
    try {
      return await _apiService.getExchangeRates('IDR');
    } catch (e) {
      print("Gagal ambil exchange rate: $e");
      return {};
    }
  }

  Future<Map<String, int>> getTimeZoneOffsets() async {
    try {
      return await _apiService.getTimeZoneOffsets();
    } catch (e) {
      print("Gagal ambil time zone offsets: $e");
      return {};
    }
  }
}