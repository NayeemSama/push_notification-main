import 'dart:convert';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:overlay_support/overlay_support.dart';

//Global Initialization
const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    'This channel is used for important notifications.', // description
    importance: Importance.high,
    playSound: true);

// flutter local notification
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// firebase background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {

  print('A Background message just showed up ID :  ${message.messageId}');
  print('A Background message just showed up DATA:  ${message.data}');
  print('A Background message just showed up CONTENT :  ${message.contentAvailable}');
  print('A Background message just showed up CATE :  ${message.category}');
  print('A Background message just showed up FROM :  ${message.from}');

  AwesomeNotifications().createNotificationFromJsonData(message.data);

}

Future<void> main() async {
  // firebase App initialize

  WidgetsFlutterBinding.ensureInitialized();

  AwesomeNotifications().initialize('assets/images/profile',null);

  await Firebase.initializeApp();

  var _messaging = await FirebaseMessaging.instance;
  var token = await _messaging.getAPNSToken();

  if (Platform.isIOS) {
    NotificationSettings settings = await _messaging.requestPermission(alert: true);

    // If you want to wait until Permission dialog close,
    // you need wait changing setting registered.

    print('User granted permission: ${settings.alert}');
  }

  print('FCM TOKEN :::::: ${token.toString()}');

  var uri = '192.168.0.9:1337/api/v1/notifications/create';

  print('PLATFORM ::::::::: ${Platform.operatingSystem}');

  http.Response response = await http.post(
    Uri.parse('http://192.168.0.9:1337/api/v1/notifications/create'),
    body: jsonEncode({
      "userType": "owner",
      "deviceType": 'iOS',
      "deviceToken": 'fEF2RFhcfUqxhh5DmAGfiM:APA91bEmdrk5aZ9UPC3-dTuClbv0w9PlOoC8ELWpXhgFO7ZmkQTS7DnGhOMvoJqGLS6N38ptbVR2P9YZIWuItwhXNXO2k6Omj0K0Ow6zUt4vcqLwV4MoAuVyz-msfsRUwu5eJ_auvqo1',
      "email": "abc@gmail.com"
    }),
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MiwidHlwZSI6InZldCIsImlhdCI6MTY1MzU3MTk3MSwiZXhwIjoxNjg1MTA3OTcxfQ.Q0WkYHNaHN1P90_c8y4F-egmHL65GMDhWMCxYiZ7A2E',
    },
    encoding: Encoding.getByName("utf-8"),
  );

  //eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MiwidHlwZSI6InZldCIsImlhdCI6MTY1MzU3MTk3MSwiZXhwIjoxNjg1MTA3OTcxfQ.Q0WkYHNaHN1P90_c8y4F-egmHL65GMDhWMCxYiZ7A2E
  //eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwidHlwZSI6InZldCIsImlhdCI6MTY1MzU2ODc4OCwiZXhwIjoxNjg1MTA0Nzg4fQ.w0lYRAIXyuPKEVtQDGatgqWa6C7Mw5LPexsQulvR7TU

  print('RESPONSE :::::::::: ${response.body.toString()}');

// Firebase local notification plugin
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

//Firebase messaging
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return OverlaySupport.global(
      child: MaterialApp(
        title: 'Push Notification',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Flutter Push Notification'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {

  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  int _counter = 0;

  @override
  void initState() {
    super.initState();
    //  om message app open
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification notification = message.notification;
      AndroidNotification android = message.notification?.android;

      if (notification != null && android != null) {

        print('NOTICE ANDROID!!!! ::::::: ${notification.android.toMap()}');
        print('NOTICE APPLE!!!! ::::::: ${notification.apple}');
        print('NOTICE TITLE!!!! ::::::: ${notification.title}');
        print('NOTICE BODY!!!! ::::::: ${notification.body}');

        print('NOTICE MAP DATA !!!! ::::::: ${message.data}');


        showOverlayNotification((context) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: SafeArea(
              child: ListTile(
                leading: SizedBox.fromSize(
                    size: const Size(40, 40),
                    child: ClipOval(
                        child: Container(
                          color: Colors.black,
                        ))),
                title: Text(notification.title),
                subtitle: Text(notification.body),
                trailing: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      OverlaySupportEntry.of(context).dismiss();
                    }),
              ),
            ),
          );
        }, duration: Duration(milliseconds: 4000));

        // Get.showSnackbar(GetSnackBar(messageText: Text('hello',style: TextStyle(color: Colors.black,fontWeight: FontWeight.w500,fontSize: 15)),
        // ));

        // flutterLocalNotificationsPlugin.show(
        //     notification.hashCode,
        //     notification.title,
        //     notification.body,
        //     NotificationDetails(
        //       android: AndroidNotificationDetails(
        //         channel.id,
        //         channel.name,
        //         channel.description,
        //         color: Colors.blue,
        //         playSound: true,
        //         icon: '@mipmap/ic_lancher',
        //       ),
        //     )
        // );
      }
    });
    //Message for Background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new messageopen app event was published');
      RemoteNotification notification = message.notification;
      AndroidNotification android = message.notification?.android;
      if (notification != null && android != null) {
        showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: Text(notification.title),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(notification.body)],
                  ),
                ),
              );
            });
      }
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  void showNotification() {
    setState(() {
      _counter++;
    });

    flutterLocalNotificationsPlugin.show(
        0,
        "Testing $_counter",
        "This is an Flutter Push Notification",
        NotificationDetails(
            android: AndroidNotificationDetails(
                channel.id, channel.name, channel.description,
                importance: Importance.high,
                color: Colors.blue,
                playSound: true,)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'This is Flutter Push Notification Example',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showNotification,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
