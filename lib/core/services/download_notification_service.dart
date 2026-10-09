import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:permission_handler/permission_handler.dart';

class DownloadNotificationService {
  static final DownloadNotificationService _instance =
      DownloadNotificationService._internal();
  factory DownloadNotificationService() => _instance;

  DownloadNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _downloadChannelId = 'download_channel';
  static const String _downloadChannelName = 'Download Progress';
  static const String _downloadChannelDescription =
      'Shows download progress for songs';

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    const WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
          appName: 'Auralis',
          iconPath: 'assets/default_artwork.png',
          appUserModelId: 'com.auralis.app',
          guid: '27D44D0C-A542-5B90-BCDB-AC3126048BA2',
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
          linux: initializationSettingsLinux,
          windows: initializationSettingsWindows,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    if (Platform.isAndroid) {
      await _createNotificationChannel();
      // await _requestNotificationPermission();
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _downloadChannelId,
      _downloadChannelName,
      description: _downloadChannelDescription,
      importance: Importance.low,
      showBadge: false,
      enableVibration: false,
      playSound: false,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // Future<void> _requestNotificationPermission() async {
  //   if (Platform.isAndroid && await Permission.notification.isDenied) {
  //     await Permission.notification.request();
  //   }
  // }

  void _onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) {}

  Future<void> showDownloadProgress({
    required int notificationId,
    required String title,
    required String artist,
    required double progress,
    required bool isPaused,
  }) async {
    final int progressPercent = (progress * 100).round();

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          _downloadChannelId,
          _downloadChannelName,
          channelDescription: _downloadChannelDescription,
          importance: Importance.low,
          priority: Priority.low,
          showProgress: true,
          maxProgress: 100,
          progress: progressPercent,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          showWhen: false,
          channelShowBadge: false,
          enableVibration: false,
          playSound: false,
        );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: false,
          presentSound: false,
        );

    const LinuxNotificationDetails linuxPlatformChannelSpecifics =
        LinuxNotificationDetails();

    const WindowsNotificationDetails windowsPlatformChannelSpecifics =
        WindowsNotificationDetails();

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
      linux: linuxPlatformChannelSpecifics,
      windows: windowsPlatformChannelSpecifics,
    );

    final String statusText = isPaused ? 'Paused' : 'Downloading...';
    final String notificationTitle = 'Downloading: $title';
    final String notificationBody = '$artist • $progressPercent% • $statusText';

    await _flutterLocalNotificationsPlugin.show(
      id: notificationId,
      title: notificationTitle,
      body: notificationBody,
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> showDownloadComplete({
    required int notificationId,
    required String title,
    required String artist,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          _downloadChannelId,
          _downloadChannelName,
          channelDescription: _downloadChannelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          ongoing: false,
          autoCancel: true,
          channelShowBadge: false,
          enableVibration: true,
          playSound: true,
        );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        );

    const LinuxNotificationDetails linuxPlatformChannelSpecifics =
        LinuxNotificationDetails();

    const WindowsNotificationDetails windowsPlatformChannelSpecifics =
        WindowsNotificationDetails();

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
      linux: linuxPlatformChannelSpecifics,
      windows: windowsPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: notificationId,
      title: 'Download Complete',
      body: '$title by $artist',
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> showDownloadFailed({
    required int notificationId,
    required String title,
    required String artist,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          _downloadChannelId,
          _downloadChannelName,
          channelDescription: _downloadChannelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          ongoing: false,
          autoCancel: true,
          channelShowBadge: false,
          enableVibration: true,
          playSound: true,
        );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        );

    const LinuxNotificationDetails linuxPlatformChannelSpecifics =
        LinuxNotificationDetails();

    const WindowsNotificationDetails windowsPlatformChannelSpecifics =
        WindowsNotificationDetails();

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
      linux: linuxPlatformChannelSpecifics,
      windows: windowsPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: notificationId,
      title: 'Download Failed',
      body: '$title by $artist',
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> cancelNotification(int notificationId) async {
    await _flutterLocalNotificationsPlugin.cancel(id: notificationId);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
