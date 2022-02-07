import 'package:user/common/shared.dart';

class OrderItem {
  String id;
  int quantity = 0;
  String name;
  String urduName;
  double price = 0;

  OrderItem({
    this.id,
    this.quantity = 0,
    this.name,
    this.urduName,
    this.price = 0,
  });

  OrderItem.fromMap(Map<String, dynamic> values) {
    id = values["id"];
    quantity = values["quantity"] ?? 0;
    name = values["name"];
    urduName = values["urduName"];
    price = toDouble(values["price"]) ?? 0;
  }

  OrderItem clone() {
    return OrderItem(
        id: id,
        quantity: quantity,
        name: name,
        urduName: urduName,
        price: price);
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "quantity": quantity,
      "name": name,
      "urduName": urduName,
      "price": price
    };
  }
}
