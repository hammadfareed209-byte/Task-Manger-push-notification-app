import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';

enum NotificationSoundOption {
  systemDefault,
  alarm,
  ringtone,
  silent,
}

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationSoundOption _selectedSound = NotificationSoundOption.systemDefault;
  NotificationSoundOption get selectedSound => _selectedSound;

  NotificationService._init();

  static const AndroidNotificationChannel _defaultChannel = AndroidNotificationChannel(
    'task_default_channel',
    'Task Reminders (Standard)',
    description: 'Standard notification alerts for tasks',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel _alarmChannel = AndroidNotificationChannel(
    'task_alarm_channel',
    'Task Alarms (High Priority)',
    description: 'Urgent alarm sound for upcoming task deadlines',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel _silentChannel = AndroidNotificationChannel(
    'task_silent_channel',
    'Task Reminders (Silent)',
    description: 'Silent notifications with vibration only',
    importance: Importance.high,
    playSound: false,
    enableVibration: true,
  );

  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification click
      },
    );

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(_defaultChannel);
      await androidImplementation.createNotificationChannel(_alarmChannel);
      await androidImplementation.createNotificationChannel(_silentChannel);

      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  void setSoundPreference(NotificationSoundOption soundOption) {
    _selectedSound = soundOption;
  }

  String getChannelIdForSound(NotificationSoundOption option) {
    switch (option) {
      case NotificationSoundOption.alarm:
        return 'task_alarm_channel';
      case NotificationSoundOption.silent:
        return 'task_silent_channel';
      case NotificationSoundOption.systemDefault:
      case NotificationSoundOption.ringtone:
      default:
        return 'task_default_channel';
    }
  }

  /// Sends a test notification with the user's selected sound
  Future<bool> sendInstantNotification({
    required String title,
    required String body,
    int id = 100,
    NotificationSoundOption? customSound,
  }) async {
    final soundToUse = customSound ?? _selectedSound;
    final channelId = getChannelIdForSound(soundToUse);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      soundToUse == NotificationSoundOption.alarm
          ? 'Task Alarms (High Priority)'
          : soundToUse == NotificationSoundOption.silent
              ? 'Task Reminders (Silent)'
              : 'Task Reminders (Standard)',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: soundToUse != NotificationSoundOption.silent,
      enableVibration: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        platformDetails,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Schedules notification: alerts user BEFORE upcoming task
  Future<void> scheduleTaskNotification(Task task) async {
    if (task.id == null) return;

    final dueTimeFormatted = DateFormat('h:mm a').format(task.dueDate);
    final advanceMinutes = task.reminderBeforeMinutes;

    String alertTitle;
    String alertBody;

    if (advanceMinutes > 0) {
      alertTitle = '⏰ Reminder: ${task.title} in $advanceMinutes mins';
      alertBody = 'Due at $dueTimeFormatted • ${task.description.isNotEmpty ? task.description : "Get ready for this task!"}';
    } else {
      alertTitle = '🎯 Task Due Now: ${task.title}';
      alertBody = task.description.isNotEmpty ? task.description : 'Scheduled for $dueTimeFormatted';
    }

    // Trigger notification
    await sendInstantNotification(
      id: task.id!,
      title: alertTitle,
      body: alertBody,
    );
  }

  Future<void> cancelTaskNotification(int taskId) async {
    await _notificationsPlugin.cancel(taskId);
  }
}
