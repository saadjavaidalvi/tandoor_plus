import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:user/common/shared.dart';
import 'package:user/managers/database_manager.dart';
import 'package:user/models/chat.dart';
import 'package:user/models/model_extensions.dart';
import 'package:user/models/notification_new_message_entity.dart';
import 'package:user/models/notification_payload_entity.dart';
import 'package:user/pages/order_page.dart';

const String _userAccount = "UserAccount";
const String _order = "Order";
const String _progress = "Progress";

// final BehaviorSubject<String> selectNotificationSubject = BehaviorSubject<String>();

Map<String, AndroidNotificationDetails> _channels = {
  _userAccount: AndroidNotificationDetails(
    _userAccount,
    "User account notifications",
    "This channels shows notifications related to user account",
    enableVibration: true,
  ),
  _order: AndroidNotificationDetails(
    _order,
    "This channels shows notifications related to orders, like if order was canceled",
    "This channels shows notifications related to user account",
    importance: Importance.high,
    enableVibration: true,
    enableLights: true,
  ),
  _progress: AndroidNotificationDetails(_progress, "Progress notifications",
      "This channels shows notifications related to progress of an ongoing service."),
};

// ignore: non_constant_identifier_names
String _KEY_LAST_TIME_UPDATED_TOKEN = "last_time_token_updated";

class MessagingManager {
  static MessagingManager _instance;

  static MessagingManager get instance {
    if (_instance == null) {
      _instance = MessagingManager._();
    }
    return _instance;
  }

  MessagingManager._();

  Future<void> init() async {
    await Future.wait([
      subscribeToFCMTopics(),
      configureFCMCallbacks(),
      FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false),
    ]);

    var flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(
        android:
            AndroidInitializationSettings("@drawable/ic_notification_badge"),
        iOS: IOSInitializationSettings(
          defaultPresentSound: true,
          defaultPresentBadge: true,
        ),
      ),
      onSelectNotification: onSelectNotification,
    );

    var notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      await onSelectNotification(notificationAppLaunchDetails.payload);
    }
  }

  Future<void> saveTokenToDb(DatabaseManager databaseManager, String uid) async {
    if ((storage.read(_KEY_LAST_TIME_UPDATED_TOKEN) ?? 0) <
        ((await getEpoch()) - (60 * 1000))) {
      try {
        String token = await FirebaseMessaging.instance.getToken();
        await databaseManager.saveToken(uid, token);
        await storage.write(_KEY_LAST_TIME_UPDATED_TOKEN, await getEpoch());
      } catch (e) {
        printInfo("Error: $e");
      }
    }
  }

  Future<void> subscribeToFCMTopics() async {
    FirebaseMessaging.instance.subscribeToTopic(debug ? "debugUser" : "user");
  }

  Future<void> configureFCMCallbacks() async {
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    FirebaseMessaging.onMessage.listen(handleFCMMessage);
    FirebaseMessaging.onBackgroundMessage(handleFCMMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleFCMMessage);
  }
}

Future<dynamic> handleNotificationData(Map<dynamic, dynamic> data) async {
  printInfo("data: $data, isempty?: ${data?.isEmpty}");
  if (data?.isEmpty ?? true) return "";

  if ("${data["type"]}" == "0") {
    // Data notification from admin app

    if ("${data["auth_filter"]}" == "1") {
      if (FirebaseAuth.instance.currentUser != null) {
        showTopicNotification(data);
      }
    } else
      showTopicNotification(data);
  } else if ("${data["type"]}" == "1") {
    // Logged out
    if ("${data["uid"]}" == FirebaseAuth.instance?.currentUser?.uid) {
      await FirebaseAuth.instance.signOut();
      showLoggedOutNotification(data);
      // Todo: close the app
    }
  } else if ("${data["type"]}" == "3") {
    // Order canceled
    if ("${data["uid"]}" == FirebaseAuth.instance?.currentUser?.uid) {
      showOrderCanceledNotification(data);
    }
  } else if ("${data["type"]}" == "4") {
    // Order confirmed
    if ("${data["uid"]}" == FirebaseAuth.instance?.currentUser?.uid) {
      showOrderConfirmedNotification(data);
    }
  } else if ("${data["type"]}" == "6") {
    // Order confirmed
    if ("${data["uid"]}" == FirebaseAuth.instance?.currentUser?.uid) {
      showOrderCompleteNotification(data);
    }
  } else if ("${data["type"]}" == "9") {
    // Rider is on the way
    if ("${data["uid"]}" == FirebaseAuth.instance?.currentUser?.uid) {
      showRiderComingNotification(data);
    }
  } else if ("${data["type"]}" == "10") {
    NotificationNewMessageEntity notificationNewMessageEntity =
        NotificationNewMessageEntity().fromJson(data);
    // Chat message received
    if (notificationNewMessageEntity.uid ==
        FirebaseAuth.instance?.currentUser?.uid) {
      showChatMessageReceivedNotification(notificationNewMessageEntity);
    }
  } else {
    printInfo("Unknown notification type: '${data["type"]}'");
  }

  return "";
}

Future onSelectNotification(String payload) async {
  printInfo("Payload received: $payload");

  try {
    NotificationPayloadEntity notificationPayloadEntity =
        NotificationPayloadEntity().fromJson(json.decode(payload));

    Get.toNamed(OrderPage.route,
        arguments: [notificationPayloadEntity.orderId, true]);
  } catch (e) {
    printInfo("Error parsing payload: $payload");
  }
}

void showTopicNotification(Map<dynamic, dynamic> data) async {
  await FlutterLocalNotificationsPlugin().show(
    0,
    data["title"],
    data["text"] ?? data["body"],
    NotificationDetails(android: _channels[_userAccount]),
    payload: _Payloads.topicNotification,
  );
}

void showLoggedOutNotification(Map<dynamic, dynamic> data) async {
  await FlutterLocalNotificationsPlugin().show(
      0,
      "Logged out",
      "Please login again",
      NotificationDetails(android: _channels[_userAccount]),
      payload: _Payloads.logoutNotification);
}

void showOrderCanceledNotification(Map<dynamic, dynamic> data) async {
  await FlutterLocalNotificationsPlugin().show(
      1,
      "Order canceled",
      "Your order was canceled",
      NotificationDetails(android: _channels[_order]),
      payload: _Payloads.canceledNotification);
}

void showOrderConfirmedNotification(Map<dynamic, dynamic> data) async {
  await FlutterLocalNotificationsPlugin().show(
      2,
      "Order confirmed",
      "Your order is confirmed",
      NotificationDetails(android: _channels[_order]),
      payload: _Payloads.confirmedNotification);
}

void showOrderCompleteNotification(Map<dynamic, dynamic> data) async {
  await FlutterLocalNotificationsPlugin().show(
      4,
      "Order delivered🥳🥳🥳",
      "Thank you for shopping with TandoorPlus",
      NotificationDetails(android: _channels[_order]),
      payload: _Payloads.orderCompleteNotification);
}

void showRiderComingNotification(Map<dynamic, dynamic> data) async {
  await FlutterLocalNotificationsPlugin().show(
      3,
      "Rider is on the way!",
      "Rider has received your order and is on the way to you.",
      NotificationDetails(android: _channels[_order]),
      payload: _Payloads.riderComingNotification);
}

void showChatMessageReceivedNotification(
    NotificationNewMessageEntity notificationNewMessageEntity) async {
  String description;

  switch (notificationNewMessageEntity.ChatMessageType) {
    case CHAT_MESSAGE_TYPE.TEXT:
      description = notificationNewMessageEntity.message;
      break;
    case CHAT_MESSAGE_TYPE.IMAGE:
      description = "Image";
      break;
    case CHAT_MESSAGE_TYPE.VOICE:
      description = "Voice note";
      break;
  }

  await FlutterLocalNotificationsPlugin().show(
      Random(DateTime.now().millisecondsSinceEpoch).nextInt(100) + 10,
      "New message from rider",
      description,
      NotificationDetails(android: _channels[_order]),
      payload: json.encode((NotificationPayloadEntity()
            ..type = "NEW_MESSAGE"
            ..orderId = notificationNewMessageEntity.orderId)
          .toJson()));
}

Future<dynamic> handleFCMMessage(RemoteMessage message) async {
  if (message != null) {
    await Firebase.initializeApp();
    printInfo("onMessage: ${message.data}");
    try {
      if (message.data["notification"] != null &&
          message.data["notification"]["title"] != null) {
        showTopicNotification(message.data["notification"]);
      } else
        return await handleNotificationData(message.data);
    } catch (e) {
      printInfo("$e");
    }
  }
  return "";
}

class _Payloads {
  static const String topicNotification = "topic_notification";
  static const String logoutNotification = "logout_notification";
  static const String canceledNotification = "canceled_notification";
  static const String confirmedNotification = "confirmed_notification";
  static const String riderComingNotification = "rider_coming_notification";
  static const String orderCompleteNotification = "order_complete_notification";
}

enum NOTIFICATION_TYPE {
  NEW_MESSAGE,
}
