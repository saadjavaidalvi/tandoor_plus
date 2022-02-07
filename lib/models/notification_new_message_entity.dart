import 'package:user/generated/json/base/json_convert_content.dart';

class NotificationNewMessageEntity
    with JsonConvert<NotificationNewMessageEntity> {
  String type;
  String uid;
  String orderId;
  String messageType;
  String message;
}
