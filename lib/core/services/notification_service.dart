import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  // Khởi tạo Notification Plugin & Timezone
  static Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    _isInitialized = true;
  }

  // Xin quyền thông báo thực tế cho Android & iOS
  static Future<bool> requestPermission() async {
    await init();

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final bool? androidGranted = await androidImplementation?.requestNotificationsPermission();

    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    final bool? iosGranted = await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return (androidGranted ?? true) && (iosGranted ?? true);
  }

  // 1. Lên lịch Nhắc Uống Nước (Đầu sáng 7:00 AM)
  static Future<void> scheduleWaterReminder(bool enable) async {
    const int notificationId = 1001;
    if (!enable) {
      await _notificationsPlugin.cancel(notificationId);
      return;
    }

    await requestPermission();
    await _scheduleDailyNotification(
      id: notificationId,
      title: 'Uống nước buổi sáng 💧',
      body: 'Hãy uống một ly nước ấm để đánh thức cơ thể và khởi đầu ngày mới tràn đầy năng lượng!',
      hour: 7,
      minute: 0,
    );
  }

  // 2. Lên lịch Nhắc Giấc Ngủ (22:00 PM)
  static Future<void> scheduleSleepReminder(bool enable) async {
    const int notificationId = 1002;
    if (!enable) {
      await _notificationsPlugin.cancel(notificationId);
      return;
    }

    await requestPermission();
    await _scheduleDailyNotification(
      id: notificationId,
      title: 'Đã đến giờ đi ngủ rồi 😴',
      body: '22h rồi! Hãy gác lại công việc, tắt màn hình điện thoại và thả lỏng cho giấc ngủ ngon nhé.',
      hour: 22,
      minute: 0,
    );
  }

  // 3. Lên lịch Nhắc Vận Động (4:00 PM / 16:00)
  static Future<void> scheduleWorkoutReminder(bool enable) async {
    const int notificationId = 1003;
    if (!enable) {
      await _notificationsPlugin.cancel(notificationId);
      return;
    }

    await requestPermission();
    await _scheduleDailyNotification(
      id: notificationId,
      title: 'Thời gian vận động 🏃‍♂️',
      body: '4h chiều rồi! Hãy đứng dậy vươn vai, ra ngoài hít thở không khí và vận động một chút nào.',
      hour: 16,
      minute: 0,
    );
  }

  // 4. Nhắc nhở Thời gian sử dụng điện thoại (Theo mức giờ)
  static Future<void> checkAndShowScreenTimeReminder({
    required bool enable,
    required double usageHoursToday,
  }) async {
    const int notificationId = 1004;
    if (!enable) {
      await _notificationsPlugin.cancel(notificationId);
      return;
    }

    await requestPermission();

    String title = '';
    String body = '';

    if (usageHoursToday >= 10) {
      title = '⚠️ CẢNH BÁO NGUY HIỂM SỬ DỤNG ĐIỆN THOẠI';
      body =
          'Bạn đã dùng điện thoại hơn ${usageHoursToday.toStringAsFixed(1)} tiếng hôm nay! Hãy buông máy và nghỉ ngơi ngay lập tức.';
    } else if (usageHoursToday >= 6) {
      title = 'Cảnh báo thời gian màn hình ⏳';
      body =
          'Thời gian sử dụng điện thoại đã vượt quá ${usageHoursToday.toStringAsFixed(1)} tiếng! Hãy đứng dậy thư giãn mắt thôi.';
    } else if (usageHoursToday >= 3) {
      title = 'Nhắc nhở nhẹ thời gian màn hình 📱';
      body =
          'Bạn đã dùng điện thoại hơn 3 tiếng hôm nay. Hãy tạm nghỉ mắt một chút nhé!';
    } else {
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'screen_time_channel',
      'Cảnh báo thời gian màn hình',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      notificationId,
      title,
      body,
      details,
    );
  }

  // 5. Lên lịch Thông điệp / Quote ngẫu nhiên mỗi ngày (8:30 AM)
  static Future<void> scheduleQuoteReminder(bool enable) async {
    const int notificationId = 1005;
    if (!enable) {
      await _notificationsPlugin.cancel(notificationId);
      return;
    }

    try {
      await requestPermission();
      final jsonString = await rootBundle.loadString('assets/quotes/daily_quotes.json');
      final List<dynamic> quotes = jsonDecode(jsonString);

      if (quotes.isNotEmpty) {
        final randomQuote = quotes[Random().nextInt(quotes.length)];
        final String text = randomQuote['quote'] ?? '';
        final String author = randomQuote['author'] ?? 'Healthiez';

        await _scheduleDailyNotification(
          id: notificationId,
          title: 'Thông điệp ấm áp hôm nay ✨',
          body: '"$text" - $author',
          hour: 8,
          minute: 30,
        );
      }
    } catch (_) {}
  }

  // Hàm hỗ trợ lên lịch thông báo hàng ngày theo giờ cụ thể
  static Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'healthiez_reminders',
      'Nhắc nhở Sức khỏe',
      channelDescription: 'Cung cấp các thông báo nhắc nhở sức khỏe lành mạnh',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
