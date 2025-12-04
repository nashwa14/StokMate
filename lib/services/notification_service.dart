import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nashwaluthfiya_124230016_pam_a/services/hive_service.dart';
import 'package:nashwaluthfiya_124230016_pam_a/models/inventory_models.dart';
import 'package:nashwaluthfiya_124230016_pam_a/services/notification_helper.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static Future<void> initialize() async {
    if (_initialized) return;
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'stokmate_channel', 
      'StokMate Notifications',
      description: 'Notifikasi untuk stok barang habis pakai',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    await Workmanager().registerPeriodicTask(
      "stockCheckTask",
      "stockCheckTask",
      frequency: const Duration(hours: 6),
    );

    _initialized = true;
    print("✅ Notification Service initialized");
  }
  static void _onNotificationTapped(NotificationResponse response) {
    print("Notification tapped: ${response.payload}");
  }

  static Future<void> showStockSummaryNotification(List<InventoryItem> items) async {
    try {
      final summary = NotificationHelper.getStockSummary(items);
      final total = NotificationHelper.getTotalProblematicItems(items);

      if (total == 0) {
        await _showNotification(
          id: 0,
          title: '✅ Semua Barang Aman',
          body: 'Tidak ada barang yang perlu perhatian khusus',
          priority: Priority.defaultPriority,
        );
        return;
      }

      final message = NotificationHelper.generateDetailedMessage(items);
      await _showNotification(
        id: 0,
        title: '📊 Ringkasan Stok',
        body: message,
        priority: Priority.high,
      );

      int notifId = 1;

      if (summary['outOfStock']!.isNotEmpty) {
        final items = summary['outOfStock']!;
        await _showNotification(
          id: notifId++,
          title: '🚨 Stok Habis (${items.length})',
          body: items.map((e) => e.name).take(3).join(", ") + 
                (items.length > 3 ? ', dan lainnya' : ''),
          priority: Priority.high,
        );
      }

      if (summary['expired']!.isNotEmpty) {
        final items = summary['expired']!;
        await _showNotification(
          id: notifId++,
          title: '⚠️ Barang Kadaluarsa (${items.length})',
          body: items.map((e) => e.name).take(3).join(", ") + 
                (items.length > 3 ? ', dan lainnya' : ''),
          priority: Priority.high,
        );
      }

      if (summary['lowStock']!.isNotEmpty) {
        final items = summary['lowStock']!;
        await _showNotification(
          id: notifId++,
          title: '📦 Stok Menipis (${items.length})',
          body: items.map((e) => e.name).take(3).join(", ") + 
                (items.length > 3 ? ', dan lainnya' : ''),
          priority: Priority.defaultPriority,
        );
      }

      if (summary['nearExpiry']!.isNotEmpty) {
        final items = summary['nearExpiry']!;
        await _showNotification(
          id: notifId++,
          title: '⏰ Hampir Kadaluarsa (${items.length})',
          body: items.map((e) => e.name).take(3).join(", ") + 
                (items.length > 3 ? ', dan lainnya' : ''),
          priority: Priority.defaultPriority,
        );
      }

      print("✅ Notifikasi stok berhasil ditampilkan");
    } catch (e) {
      print("❌ Error menampilkan notifikasi: $e");
    }
  }

  static Future<void> showItemAddedNotification(String itemName) async {
    await _showNotification(
      id: 100,
      title: '✅ Barang Berhasil Ditambahkan',
      body: '$itemName telah ditambahkan ke inventory',
      priority: Priority.defaultPriority,
    );
  }

  static Future<void> showItemUpdatedNotification(String itemName) async {
    await _showNotification(
      id: 101,
      title: '✏️ Barang Berhasil Diperbarui',
      body: '$itemName telah diperbarui',
      priority: Priority.defaultPriority,
    );
  }

  static Future<void> showItemDeletedNotification(String itemName) async {
    await _showNotification(
      id: 102,
      title: '🗑️ Barang Berhasil Dihapus',
      body: '$itemName telah dihapus dari inventory',
      priority: Priority.defaultPriority,
    );
  }

  static Future<void> checkAndNotify() async {
    try {
      if (!Hive.isBoxOpen(HiveService.inventoryBox)) {
        await Hive.initFlutter();
        await Hive.openBox(HiveService.inventoryBox);
      }

      final box = await HiveService.getInventoryBox();
      final List<InventoryItem> inventory = [];

      for (var key in box.keys) {
        final value = box.get(key);
        if (value is Map) {
          try {
            final keyStr = key.toString();
            final parts = keyStr.split('_');
            if (parts.length >= 2) {
              final id = parts.sublist(1).join('_');
              final map = Map<String, dynamic>.from(value);
              map['id'] = id;
              inventory.add(InventoryItem.fromMap(map));
            }
          } catch (e) {
            print("Error parsing item: $e");
          }
        }
      }
      final total = NotificationHelper.getTotalProblematicItems(inventory);
      if (total > 0) {
        await showStockSummaryNotification(inventory);
      }
      print("✅ Background check selesai");
    } catch (e) {
      print("❌ Error saat background check: $e");
    }
  }

  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    Priority priority = Priority.defaultPriority,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'stokmate_channel',
      'StokMate Notifications',
      channelDescription: 'Notifikasi untuk stok barang habis pakai',
      importance: priority == Priority.high ? Importance.high : Importance.defaultImportance,
      priority: priority,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
  static Future<void> stopBackgroundCheck() async {
    await Workmanager().cancelAll();
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print("Background task running: $task");
      await NotificationService.checkAndNotify();
      return Future.value(true);
    } catch (e) {
      print("Background task error: $e");
      return Future.value(false);
    }
  });
}