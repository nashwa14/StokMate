import 'package:nashwaluthfiya_124230016_pam_a/models/inventory_models.dart';

class NotificationHelper {
  static const int lowStockThreshold = 5;
  static const int nearExpiryDays = 7;
  static List<InventoryItem> getOutOfStockItems(List<InventoryItem> items) {
    return items.where((item) => item.quantity == 0).toList();
  }

  static List<InventoryItem> getExpiredItems(List<InventoryItem> items) {
    final now = DateTime.now();
    return items.where((item) {
      // Bandingkan hanya tanggal (tanpa waktu)
      final expiryDateOnly = DateTime(
        item.expiryDate.year,
        item.expiryDate.month,
        item.expiryDate.day,
      );
      final todayOnly = DateTime(now.year, now.month, now.day);
      return expiryDateOnly.isBefore(todayOnly);
    }).toList();
  }

  static List<InventoryItem> getLowStockItems(List<InventoryItem> items) {
    return items.where((item) {
      return item.quantity > 0 && item.quantity < lowStockThreshold;
    }).toList();
  }

  static List<InventoryItem> getNearExpiryItems(List<InventoryItem> items) {
    final now = DateTime.now();
    final futureDate = now.add(const Duration(days: nearExpiryDays));

    return items.where((item) {
      final expiryDateOnly = DateTime(
        item.expiryDate.year,
        item.expiryDate.month,
        item.expiryDate.day,
      );
      final todayOnly = DateTime(now.year, now.month, now.day);

      return expiryDateOnly.isAfter(todayOnly) &&
          expiryDateOnly.isBefore(futureDate);
    }).toList();
  }

  static Map<String, List<InventoryItem>> getStockSummary(
      List<InventoryItem> items) {
    return {
      'outOfStock': getOutOfStockItems(items),
      'expired': getExpiredItems(items),
      'lowStock': getLowStockItems(items),
      'nearExpiry': getNearExpiryItems(items),
    };
  }

  static int getTotalProblematicItems(List<InventoryItem> items) {
    final summary = getStockSummary(items);
    return summary['outOfStock']!.length +
        summary['expired']!.length +
        summary['lowStock']!.length +
        summary['nearExpiry']!.length;
  }

  static String generateDetailedMessage(List<InventoryItem> items) {
    final summary = getStockSummary(items);
    
    List<String> messages = [];
    
    if (summary['outOfStock']!.isNotEmpty) {
      messages.add('${summary['outOfStock']!.length} stok habis');
    }
    if (summary['expired']!.isNotEmpty) {
      messages.add('${summary['expired']!.length} kadaluarsa');
    }
    if (summary['lowStock']!.isNotEmpty) {
      messages.add('${summary['lowStock']!.length} stok menipis');
    }
    if (summary['nearExpiry']!.isNotEmpty) {
      messages.add('${summary['nearExpiry']!.length} hampir kadaluarsa');
    }
    
    return messages.isEmpty ? 'Semua barang aman' : messages.join(', ');
  }

  static bool isProblematic(InventoryItem item) {
    final now = DateTime.now();
    final futureDate = now.add(const Duration(days: nearExpiryDays));
    final expiryDateOnly = DateTime(
      item.expiryDate.year,
      item.expiryDate.month,
      item.expiryDate.day,
    );
    final todayOnly = DateTime(now.year, now.month, now.day);

    if (item.quantity == 0) return true;
    if (expiryDateOnly.isBefore(todayOnly)) return true;
    if (item.quantity > 0 && item.quantity < lowStockThreshold) return true;
    if (expiryDateOnly.isAfter(todayOnly) &&
        expiryDateOnly.isBefore(futureDate)) {
      return true;
    }
    return false;
  }

  static String getItemStatusLabel(InventoryItem item) {
    final now = DateTime.now();
    final futureDate = now.add(const Duration(days: nearExpiryDays));
    final expiryDateOnly = DateTime(
      item.expiryDate.year,
      item.expiryDate.month,
      item.expiryDate.day,
    );
    final todayOnly = DateTime(now.year, now.month, now.day);

    if (item.quantity == 0) return 'Stok Habis';
    if (expiryDateOnly.isBefore(todayOnly)) return 'Kadaluarsa';
    if (item.quantity < lowStockThreshold) return 'Stok Menipis';
    if (expiryDateOnly.isAfter(todayOnly) &&
        expiryDateOnly.isBefore(futureDate)) {
      return 'Hampir Kadaluarsa';
    }
    return 'Aman';
  }
}