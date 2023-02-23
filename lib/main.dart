import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase/rest.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'constants.dart';
import 'firebase_options.dart';

late AndroidNotificationChannel channel;
bool isFlutterLocalNotificationsInitialized = false;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
final StreamController<String?> selectNotificationStream =
    StreamController<String?>.broadcast();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  setupFlutterNotifications();
  initializeNotificationsPlugin();
  await showNotification(message);
  debugPrint('Handling a background message ${message.messageId}');
}

Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
    'channel_id', // id
    'channel_name', // name
    description: 'channel_description', // description
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await _requestPermissions();

  isFlutterLocalNotificationsInitialized = true;
}

void initializeNotificationsPlugin() {
  const initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
    onDidReceiveLocalNotification:
        (int id, String? title, String? body, String? payload) async {},
    notificationCategories: [],
  );

  final initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );
  flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
    selectNotificationStream.add(response.payload);
  });
}

Future<void> _requestPermissions() async {
  if (Platform.isIOS) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  } else if (Platform.isAndroid) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}

Future<void> showNotification(RemoteMessage message) async {
  final Int64List vibrationPattern = Int64List(4);
  vibrationPattern[0] = 0;
  vibrationPattern[1] = 500;
  vibrationPattern[2] = 1000;

  final AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(channel.id, channel.name,
          channelDescription: channel.description,
          icon: '@mipmap/ic_launcher',
          vibrationPattern: vibrationPattern,
          enableLights: true,
          color: const Color.fromARGB(255, 255, 0, 0),
          ledColor: const Color.fromARGB(255, 255, 0, 0),
          ledOnMs: 1000,
          ledOffMs: 500);

  final NotificationDetails notificationDetails =
      NotificationDetails(android: androidNotificationDetails);
  flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      notificationDetails);
}

void configureSelectNotificationSubject() {
  selectNotificationStream.stream.listen((String? payload) async {
    debugPrint('FirebaseHelper._configureSelectNotificationSubject');
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp],
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  setupFlutterNotifications();

  initializeNotificationsPlugin();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late TextEditingController _textToken;
  final _rest = Rest();

  getToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint(token);
    return token;
  }

  @override
  void initState() {
    _textToken = TextEditingController();

    getToken();
    FirebaseMessaging.onMessage.listen((message) {
      RemoteNotification? notification = message.notification;
      if (notification != null) {
        showNotification(message);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 50),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textToken,
                      decoration: const InputDecoration(
                          enabled: false, labelText: "My Token"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _textToken.text));
                      },
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  _textToken.text = await getToken();
                },
                child: const Text('Token'),
              ),
              const SizedBox(height: 30),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            FirebaseMessaging.instance
                                .subscribeToTopic('myTopic1');
                          },
                          child: const Text('Subscribe myTopic1'),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            FirebaseMessaging.instance
                                .unsubscribeFromTopic('myTopic1');
                          },
                          child: const Text('Unsubscribe myTopic1'),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            sendPushNotification(topic: "myTopic1");
                          },
                          child: const Text('Send myTopic1'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            FirebaseMessaging.instance
                                .subscribeToTopic('myTopic2');
                          },
                          child: const Text('Subscribe myTopic2'),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            FirebaseMessaging.instance
                                .unsubscribeFromTopic('myTopic2');
                          },
                          child: const Text('Unsubscribe myTopic2'),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            sendPushNotification(topic: "myTopic2");
                          },
                          child: const Text('Send myTopic2'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> sendPushNotification({required String topic}) async {
    String dataNotifications = '{ '
        ' "to" : "/topics/$topic" , '
        ' "notification" : {'
        ' "title":"$topic title" , '
        ' "body":"$topic body" '
        ' } '
        ' } ';

    final result = await _rest.request(
      path: '',
      method: Method.post,
      header: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=${Constants.KEY_SERVER}',
      },
      data: dataNotifications,
    );

    print(result?.data);
    return true;
  }

  @override
  void dispose() {
    _textToken.dispose();
    super.dispose();
  }
}
