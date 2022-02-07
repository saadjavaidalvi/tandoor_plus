import 'package:user/models/notification_new_message_entity.dart';

notificationNewMessageEntityFromJson(
    NotificationNewMessageEntity data, Map<String, dynamic> json) {
  if (json['type'] != null) {
    data.type = json['type'].toString();
  }
  if (json['uid'] != null) {
    data.uid = json['uid'].toString();
  }
  if (json['orderId'] != null) {
    data.orderId = json['orderId'].toString();
  }
  if (json['messageType'] != null) {
    data.messageType = json['messageType'].toString();
  }
  if (json['message'] != null) {
    data.message = json['message'].toString();
  }
  return data;
}

Map<String, dynamic> notificationNewMessageEntityToJson(
    NotificationNewMessageEntity entity) {
  final Map<String, dynamic> data = new Map<String, dynamic>();
  data['type'] = entity.type;
  data['uid'] = entity.uid;
  data['orderId'] = entity.orderId;
  data['messageType'] = entity.messageType;
  data['message'] = entity.message;
  return data;
}
