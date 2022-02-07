import 'package:user/managers/messaging_manager.dart';

import 'chat.dart';
import 'notification_new_message_entity.dart';
import 'notification_payload_entity.dart';

extension notification_new_message_entity_ext on NotificationNewMessageEntity {
  CHAT_MESSAGE_TYPE get ChatMessageType {
    switch (type.toUpperCase()) {
      case "IMAGE":
        return CHAT_MESSAGE_TYPE.IMAGE;
      case "VOICE":
        return CHAT_MESSAGE_TYPE.VOICE;
      default:
        return CHAT_MESSAGE_TYPE.TEXT;
    }
  }
}

extension notification_payload_entity_ext on NotificationPayloadEntity {
  NOTIFICATION_TYPE get NotificationType {
    switch (type) {
      default:
        return NOTIFICATION_TYPE.NEW_MESSAGE;
    }
  }
}
