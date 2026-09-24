import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/study_schedule.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: LinuxInitializationSettings(defaultActionName: 'Open notification'),
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle clicking the notification (e.g. opens the study timer)
      },
    );

    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleStudyNotification(StudySchedule schedule) async {
    if (!schedule.isEnabled) return;

    for (final day in schedule.daysOfWeek) {
      final int notificationId =
          schedule.id.hashCode ^ (day * 100) ^ schedule.startTime.hour;

      // Calculate time for notification (subtracting reminderMinutesBefore)
      var totalMinutes =
          (schedule.startTime.hour * 60 + schedule.startTime.minute) -
              schedule.reminderMinutesBefore;
      if (totalMinutes < 0) {
        totalMinutes += 24 * 60;
      }
      final notifHour = totalMinutes ~/ 60;
      final notifMinute = totalMinutes % 60;

      final reminderNote = schedule.reminderMinutesBefore > 0
          ? 'starts in ${schedule.reminderMinutesBefore} minutes'
          : 'is starting right now!';

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        '📚 Time to Study: ${schedule.title}',
        'Your scheduled study session $reminderNote. Get your notes ready!',
        _nextInstanceOfDayAndTime(day, notifHour, notifMinute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'study_schedule_channel',
            'Study Schedules',
            channelDescription: 'Notifications for upcoming study schedules',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancelScheduleNotifications(StudySchedule schedule) async {
    for (final day in schedule.daysOfWeek) {
      final int notificationId =
          schedule.id.hashCode ^ (day * 100) ^ schedule.startTime.hour;
      await _notificationsPlugin.cancel(notificationId);
    }
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'study_alerts_channel',
        'Study Alerts',
        channelDescription: 'Instant alerts and timer completion notices',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
    );
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int targetDay, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDate.weekday != targetDay || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
