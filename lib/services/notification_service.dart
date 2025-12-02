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

  static Future<void> checkAndNotify() async {
    try {
      if (!Hive.isBoxOpen(HiveService.inventoryBox)) {
        await Hive.initFlutter();
        await Hive.openBox(HiveService.inventoryBox);
      }

      final items = await HiveService.getAllInventoryItems();
      final List<InventoryItem> inventory =
          items.map((map) => InventoryItem.fromMap(map)).toList();

      final outOfStock = NotificationHelper.getOutOfStockItems(inventory);
      final expired = NotificationHelper.getExpiredItems(inventory);
      final lowStock = NotificationHelper.getLowStockItems(inventory);
      final nearExpiry = NotificationHelper.getNearExpiryItems(inventory);

      if (outOfStock.isNotEmpty) {
        await _showNotification(
          id: 1,
          title: '🚨 Stok Habis!',
          body: '${outOfStock.length} barang stoknya habis: ${outOfStock.map((e) => e.name).join(", ")}',
          priority: Priority.high,
        );
      }

      if (expired.isNotEmpty) {
        await _showNotification(
          id: 2,
          title: '⚠️ Barang Kadaluarsa!',
          body: '${expired.length} barang sudah kadaluarsa: ${expired.map((e) => e.name).join(", ")}',
          priority: Priority.high,
        );
      }

      if (lowStock.isNotEmpty) {
        await _showNotification(
          id: 3,
          title: '📦 Stok Menipis',
          body: '${lowStock.length} barang stoknya menipis: ${lowStock.map((e) => e.name).join(", ")}',
          priority: Priority.defaultPriority,
        );
      }

      if (nearExpiry.isNotEmpty) {
        await _showNotification(
          id: 4,
          title: 'Hampir Kadaluarsa',
          body: '${nearExpiry.length} barang akan kadaluarsa dalam ${nearExpiry.map((e) => e.name).join(", ")}',
          priority: Priority.defaultPriority,
        );
      }

      print("Pengecekan notifikasi selesai");
    } catch (e) {
      print("Error saat cek notifikasi: $e");
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