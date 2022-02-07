class Chat {
  String id;
  List<ChatMessage> messages;

  Chat.fromMap(String id, Map<dynamic, dynamic> data) {
    messages = [];

    if (data != null) {
      data.keys.forEach((key) {
        if (data[key] is Map) {
          messages.add(ChatMessage.fromMap(data[key]));
        }
      });
    }

    messages.sort((a, b) => b.datetime.compareTo(a.datetime));
  }
}

class ChatMessage {
  String id;
  String sender;
  String receiver;
  CHAT_MESSAGE_TYPE type;
  String value;
  int datetime;

  ChatMessage();

  ChatMessage.fromMap(Map<dynamic, dynamic> data) {
    if (data != null) {
      id = data["id"];
      sender = data["sender"];
      receiver = data["receiver"];
      value = data["value"];
      datetime = int.tryParse("${data["datetime"]}") ?? 0;

      String type = data["type"];
      switch (type) {
        case "image":
          this.type = CHAT_MESSAGE_TYPE.IMAGE;
          break;
        case "voice":
          this.type = CHAT_MESSAGE_TYPE.VOICE;
          break;
        case "text":
        default:
          this.type = CHAT_MESSAGE_TYPE.TEXT;
      }
    }
  }

  Map<dynamic, dynamic> toMap() {
    String type;
    switch (this.type) {
      case CHAT_MESSAGE_TYPE.IMAGE:
        type = "image";
        break;
      case CHAT_MESSAGE_TYPE.VOICE:
        type = "voice";
        break;
      case CHAT_MESSAGE_TYPE.TEXT:
      default:
        type = "text";
    }

    return {
      "id": id,
      "sender": sender,
      "receiver": receiver,
      "type": type,
      "value": value,
      "datetime": datetime,
    };
  }
}

enum CHAT_MESSAGE_TYPE {
  TEXT,
  IMAGE,
  VOICE,
}
