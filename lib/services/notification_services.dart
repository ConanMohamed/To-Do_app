import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/route_manager.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:todo/models/task.dart';
import 'package:todo/ui/pages/notification_screen.dart';

class NotifyHelper {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  String selectedNotificationPayload = '';

  final BehaviorSubject<String> selectNotificationSubject =
      BehaviorSubject<String>();
  initializeNotification() async {
    // Initialize time zones
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Egypt')); // Adjust the location
    _configureSelectNotificationSubject();
    // tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('appicon');
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
  }

  requestPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(sound: true, alert: true, badge: true);
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (notificationResponse.payload != null) {
      debugPrint('notification payload: $payload');
    }
    await Get.to(() => NotificationScreen(
          payLoad: payload ?? '',
        ));
  }

  displayNotification(
    String title,
    String body,
  ) async {
    NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails('0', title,
            channelDescription: body,
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker'),
        iOS: const DarwinNotificationDetails());
    await flutterLocalNotificationsPlugin.show(
        0, title, body, notificationDetails,
        payload: '$title|$body|18:11');
  }

  tz.TZDateTime _nextNotification(
      int hour, int minutes, String repeat, int remind, String date) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    var formattedDate = DateFormat.yMd().parse(date);
    var fLocalDate = tz.TZDateTime.from(formattedDate, tz.getLocation('Egypt'));
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      fLocalDate.year,
      fLocalDate.month,
      fLocalDate.day,
      hour,
      minutes,
    );
    scheduledDate = afterReminder(remind, scheduledDate);
    if (scheduledDate.isBefore(now)) {
      if (repeat == 'Daily') {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      if (repeat == 'Weekly') {
        scheduledDate = tz.TZDateTime(tz.local, now.year, now.month,
            (formattedDate.day) + 7, hour, minutes);
      }
      if (repeat == 'Monthly') {
        scheduledDate = tz.TZDateTime(tz.local, now.year,
            formattedDate.month + 1, formattedDate.day, hour, minutes);
      }
      scheduledDate = afterReminder(remind, scheduledDate);
    }
    print(
        'hours: $hour  minutes: $minutes  month: ${now.month} day: ${now.day} year: ${now.year}  now: $now');
    return scheduledDate;
  }

  tz.TZDateTime afterReminder(int remind, tz.TZDateTime scheduledDate) {
    if (remind == 5) {
      scheduledDate = scheduledDate.subtract(const Duration(minutes: 5));
    }
    if (remind == 10) {
      scheduledDate = scheduledDate.subtract(const Duration(minutes: 10));
    }
    if (remind == 15) {
      scheduledDate = scheduledDate.subtract(const Duration(minutes: 15));
    }
    if (remind == 20) {
      scheduledDate = scheduledDate.subtract(const Duration(minutes: 20));
    }
    return scheduledDate;
  }

  scheduledNotification(int hour, int minutes, Task task) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
        task.id!,
        task.title,
        task.note,
        // tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
        _nextNotification(
            hour, minutes, task.repeat!, task.remind!, task.date!),
        const NotificationDetails(
            android: AndroidNotificationDetails('0', 'your channel name',
                channelDescription: 'your channel description')),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: '${task.title}|${task.note}|${task.startTime}|');
  }

  cancelNotification(Task task) async {
    await flutterLocalNotificationsPlugin.cancel(task.id!);
  }
  cancelAllNotification() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

//Older IOS
  void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    // display a dialog with the notification details, tap ok to go to another page
    Get.dialog(Text(body!));
  }

  void _configureSelectNotificationSubject() {
    selectNotificationSubject.stream.listen((String payload) async {
      debugPrint('My payload is $payload');
      await Get.to(() => NotificationScreen(
            payLoad: payload,
          ));
    });
  }
}
