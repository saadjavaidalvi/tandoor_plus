import 'package:user/common/shared.dart';

class ShopMenuItem {
  String id;
  String shopId;
  String name;
  String description;
  double price;
  double moq;
  String category;
  String tags;
  String imageUrl;
  bool available;
  String unit;

  ShopMenuItem({
    this.id,
    this.shopId,
    this.name,
    this.description,
    this.price,
    this.moq,
    this.category,
    this.tags,
    this.imageUrl,
    this.available,
    this.unit,
  });

  factory ShopMenuItem.fromMap(Map<String, dynamic> values) {
    ShopMenuItem item = ShopMenuItem();
    item.id = values["id"];
    item.shopId = values["shopId"];
    item.name = values["name"];
    item.description = values["description"];
    item.price = toDouble(values["price"]);
    item.moq = 1; // toDouble(values["moq"]); // Todo MOQ
    item.category = values["category"];
    item.tags = values["tags"];
    item.imageUrl = values["imageUrl"];
    item.available = values["available"];
    item.unit = values["unit"];
    return item;
  }
}
