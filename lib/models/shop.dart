import 'package:user/common/shared.dart';

class Shop {
  String id;
  String nameEnglish;
  String nameUrdu;
  String address;
  int distanceTime;
  double distance;
  String imageUrl;
  bool available;
  double deliveryPrice;

  Shop({
    this.id,
    this.nameEnglish,
    this.nameUrdu,
    this.address,
    this.distanceTime,
    this.distance,
    this.imageUrl,
    this.available,
    this.deliveryPrice,
  });

  String get distanceTimeString {
    if (distanceTime < 60) {
      return "$distanceTime mins";
    } else {
      Duration duration = Duration(minutes: distanceTime);
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      String twoDigitHours = duration.inHours.toString();
      String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
      return "${twoDigitHours}hr ${twoDigitMinutes}m";
    }
  }

  String get distanceString {
    if (distance <= 500) {
      return "${distance.toStringAsFixed(0)}m";
    } else {
      return "${(distance / 1000).roundTo(0.5).toStringAsFixed(1).replaceAll(".0", "")}km";
    }
  }

  factory Shop.fromMap(dynamic data) {
    if (data == null) return null;
    assert(data is Map);
    Shop shop = new Shop();
    if (data is Map) {
      for (String key in data.keys) {
        if (key == "id") shop.id = data[key];
        if (key == "nameEnglish") shop.nameEnglish = data[key];
        if (key == "nameUrdu") shop.nameUrdu = data[key];
        if (key == "address") shop.address = data[key];
        if (key == "distanceTime")
          shop.distanceTime = double.parse((data[key] ?? 0).toString()).toInt();
        if (key == "distance")
          shop.distance = double.parse((data[key] ?? 0).toString());
        if (key == "imageUrl") shop.imageUrl = data[key];
        if (key == "available") shop.available = data[key] ?? false;
        if (key == "deliveryPrice")
          shop.deliveryPrice = double.parse((data[key] ?? 0).toString());
      }
    }

    return shop;
  }
}
