import 'package:user/models/notification_payload_entity.dart';

notificationPayloadEntityFromJson(
    NotificationPayloadEntity data, Map<String, dynamic> json) {
  if (json['type'] != null) {
    data.type = json['type'].toString();
  }
  if (json['orderId'] != null) {
    data.orderId = json['orderId'].toString();
  }
  return data;
}

Map<String, dynamic> notificationPayloadEntityToJson(
    NotificationPayloadEntity entity) {
  final Map<String, dynamic> data = new Map<String, dynamic>();
  data['type'] = entity.type;
  data['orderId'] = entity.orderId;
  return data;
}
