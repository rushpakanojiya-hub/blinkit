import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:share_plus/share_plus.dart';

/// Shows a native "Download complete" style notification after a file has
/// been saved to the device, similar to how browsers/downloads managers
/// notify the user. Tapping the notification opens the share sheet for the
/// saved file, letting the user pick a PDF viewer (more reliable across
/// device manufacturers than launching a viewer directly via FileProvider).
class DownloadNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) async {
        final path = response.payload;
        if (path != null && path.isNotEmpty) {
          await SharePlus.instance.share(ShareParams(files: [XFile(path)], text: 'Invoice'));
        }
      },
    );

    const channel = AndroidNotificationChannel(
      'downloads_channel',
      'Downloads',
      description: 'Notifies when a file finishes downloading',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<void> showDownloadComplete({
    required String fileName,
    required String filePath,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'downloads_channel',
      'Downloads',
      channelDescription: 'Notifies when a file finishes downloading',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      fileName.hashCode,
      'Download complete',
      fileName,
      details,
      payload: filePath,
    );
  }
}

