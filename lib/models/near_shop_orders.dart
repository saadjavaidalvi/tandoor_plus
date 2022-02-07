class NearShopOrders {
  String id;
  List<String> shopIds;
  List<String> orderIds;
  double centerLat = 0;
  double centerLon = 0;

  NearShopOrders({
    this.id,
    this.shopIds,
    this.orderIds,
    this.centerLat = 0,
    this.centerLon = 0,
  }) {
    shopIds = shopIds ?? [];
    orderIds = orderIds ?? [];
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "shopIds": shopIds,
      "orderIds": orderIds,
      "centerLat": centerLat,
      "centerLon": centerLon,
    };
  }
}
