import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../features/recurring_transactions/domain/entities/recurring_transaction.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _pluginAvailable = true;

  Future<void> initialize() async {
    if (_initialized || !_pluginAvailable || kIsWeb) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _initialized = true;
    } on MissingPluginException catch (error) {
      // A newly added native plugin is unavailable in an already running
      // hot-reload session. Keep the rest of the app usable until a full
      // native rebuild registers the plugin.
      _pluginAvailable = false;
      debugPrint('Local notifications unavailable: $error');
    }
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await initialize();
    if (!_initialized) return false;
    final android = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return android ?? ios ?? true;
  }

  Future<void> schedule(RecurringTransaction transaction) async {
    if (kIsWeb || !transaction.isActive || transaction.id.isEmpty) return;
    await initialize();
    if (!_initialized) return;
    await cancel(transaction.id);
    var cursor = DateTime.now();
    for (var index = 0; index < 12; index++) {
      final reminder = transaction.nextReminderDate(cursor);
      await _plugin.zonedSchedule(
        id: _notificationId('${transaction.id}:$index'),
        title: 'Pengingat transaksi: ${transaction.title}',
        body: 'Jatuh tempo tanggal ${transaction.dayOfMonth}.',
        scheduledDate: tz.TZDateTime.from(reminder, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'recurring_transactions',
            'Transaksi berulang',
            channelDescription: 'Pengingat jatuh tempo transaksi bulanan',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: transaction.id,
      );
      cursor = reminder.add(const Duration(days: 1));
    }
  }

  Future<void> cancel(String transactionId) async {
    if (kIsWeb || transactionId.isEmpty) return;
    await initialize();
    if (!_initialized) return;
    await _plugin.cancel(id: _notificationId(transactionId));
    for (var index = 0; index < 12; index++) {
      await _plugin.cancel(id: _notificationId('$transactionId:$index'));
    }
  }

  int _notificationId(String value) => value.hashCode & 0x7fffffff;
}
