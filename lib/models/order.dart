import 'package:user/common/shared.dart';

import 'address.dart';
import 'contact_info.dart';
import 'order_item.dart';

class Order {
  String id;
  Address address;
  ContactInfo contactInfo;
  List<OrderItem> orderItems = [];
  double _subtotalPrice = 0;
  double deliveryPrice = 0;
  double _totalPrice = 0;
  double fromWallet = 0;
  int datetime = 0;
  int shopAcceptDatetime = 0;
  int riderAcceptDatetime = 0;
  String uid;
  String shopId;
  String riderId;
  String riderName;
  bool canceled = false;
  String shopName;
  String shopAddress;
  double shopLat = 0;
  double shopLon = 0;
  int status = 0;
  int reasonToCancel = 0;
  int deliveredDatetime = 0;
  int eta = 0;
  String riderPhone;
  bool acceptedByShop = false;
  bool acceptedByRider = false;
  bool isShopOrder = false;
  String chatId;
  int type = 0;
  ContactInfo sender;
  ContactInfo receiver;
  Address senderAddress;
  Address receiverAddress;
  String instructions;
  String groceryList;
  bool riderReachedMart = false;
  double estimatedDeliveryCharges = 0;
  double grocerySubtotal = 0;
  int riderReachedMartAt = 0;

  double originalDeliveryPrice;

  /*
   * 0: new Order,
   * 1: order assigned to a shop (not ready to take),
   * 2: order assigned to a rider (may or may not be ready to take),
   * 3: Order is on the way,
   * 4: Order has been delivered to user
   */

  /*
  * Reasons of cancellation. Only applies if canceled = true:
  * 0: Server Error
  * 1: No shop is available to accept order
  * 2: No rider is available to accept order
  */

  set subtotalPrice(double subtotalPrice) =>
      this._subtotalPrice = subtotalPrice;

  double get subtotalPrice {
    _pricePrecaution();
    return this._subtotalPrice;
  }

  set totalPrice(double totalPrice) => this._totalPrice = totalPrice;

  double get totalPrice {
    _pricePrecaution();
    return this._totalPrice;
  }

  int get cartQuantity => calculateCartQuantity(orderItems);

  ORDER_STATUS get resolvedStatus => ORDER_STATUS.values[status];

  ORDER_TYPE get resolvedType => ORDER_TYPE.values[type ?? 0];

  Order({
    this.id,
    this.address,
    this.contactInfo,
    this.orderItems = const [],
    this.deliveryPrice = 0,
    this.fromWallet = 0,
    this.datetime = 0,
    this.shopAcceptDatetime = 0,
    this.riderAcceptDatetime = 0,
    this.uid,
    this.shopId,
    this.riderId,
    this.riderName,
    this.canceled = false,
    this.shopName,
    this.shopAddress,
    this.shopLat = 0,
    this.shopLon = 0,
    this.status = 0,
    this.reasonToCancel = 0,
    this.deliveredDatetime = 0,
    this.eta = 0,
    this.riderPhone,
    this.acceptedByShop = false,
    this.acceptedByRider = false,
    this.isShopOrder = false,
    this.chatId,
    this.type = 0,
    this.sender,
    this.receiver,
    this.senderAddress,
    this.receiverAddress,
    this.instructions,
    this.groceryList,
    this.riderReachedMart = false,
    this.estimatedDeliveryCharges = 0,
    this.grocerySubtotal = 0,
    this.riderReachedMartAt = 0,
  }) {
    acceptedByShop = acceptedByShop ||
        (resolvedStatus.index >= ORDER_STATUS.ON_THE_WAY.index);
    acceptedByRider = acceptedByRider ||
        (resolvedStatus.index >= ORDER_STATUS.ON_THE_WAY.index);
  }

  Order.fromMap(Map<String, dynamic> values) {
    List<dynamic> orderItemsList =
        (values["orderItems"] ?? []) as List<dynamic>;
    orderItems = List.generate(
      orderItemsList.length,
      (index) =>
          OrderItem.fromMap(orderItemsList[index] as Map<String, dynamic>),
    );

    id = values["id"];
    if (values["address"] != null) address = Address.fromMap(values["address"]);
    if (values["contactInfo"] != null)
      contactInfo = ContactInfo.fromMap(values["contactInfo"]);
    deliveryPrice = toDouble(values["deliveryPrice"]) ?? 0;
    fromWallet = toDouble(values["fromWallet"]) ?? 0;
    datetime = values["datetime"] ?? 0;
    shopAcceptDatetime = values["shopAcceptDatetime"] ?? 0;
    riderAcceptDatetime = values["riderAcceptDatetime"] ?? 0;
    uid = values["uid"];
    shopId = values["shopId"];
    riderId = values["riderId"];
    riderName = values["riderName"];
    canceled = values["canceled"] ?? false;
    shopName = values["shopName"];
    shopAddress = values["shopAddress"];
    shopLat = toDouble(values["shopLat"]) ?? 0;
    shopLon = toDouble(values["shopLon"]) ?? 0;
    status = values["status"] ?? 0;
    reasonToCancel = values["reasonToCancel"] ?? 0;
    deliveredDatetime = values["deliveredDatetime"] ?? 0;
    eta = ((values["eta"] ?? 0) as num).toInt();
    riderPhone = values["riderPhone"];
    acceptedByShop = values["acceptedByShop"] ??
        (resolvedStatus.index >= ORDER_STATUS.ON_THE_WAY.index);
    acceptedByRider = values["acceptedByRider"] ??
        (resolvedStatus.index >= ORDER_STATUS.ON_THE_WAY.index);
    isShopOrder = values["isShopOrder"];
    chatId = values["chatId"];
    type = ((values["type"] ?? 0) as num).toInt();
    if (values["sender"] != null)
      sender = ContactInfo.fromMap(values["sender"]);
    if (values["receiver"] != null)
      receiver = ContactInfo.fromMap(values["receiver"]);
    if (values["senderAddress"] != null)
      senderAddress = Address.fromMap(values["senderAddress"]);
    if (values["receiverAddress"] != null)
      receiverAddress = Address.fromMap(values["receiverAddress"]);
    instructions = values["instructions"];
    groceryList = values["groceryList"];
    riderReachedMart = values["riderReachedMart"] ?? false;
    estimatedDeliveryCharges = ((values["estimatedDeliveryCharges"] ?? 0) as num).toDouble();
    grocerySubtotal = ((values["grocerySubtotal"] ?? 0) as num).toDouble();
    riderReachedMartAt = ((values["riderReachedMartAt"] ?? 0) as num).toInt();
  }

  Order clone() {
    return Order(
      id: id,
      address: address?.clone(),
      contactInfo: contactInfo?.clone(),
      orderItems: List<OrderItem>.generate(
        orderItems.length,
        (index) => orderItems[index]?.clone(),
      ),
      deliveryPrice: deliveryPrice,
      fromWallet: fromWallet,
      datetime: datetime,
      shopAcceptDatetime: shopAcceptDatetime,
      riderAcceptDatetime: riderAcceptDatetime,
      uid: uid,
      shopId: shopId,
      riderId: riderId,
      riderName: riderName,
      canceled: canceled,
      shopName: shopName,
      shopAddress: shopAddress,
      shopLat: shopLat,
      shopLon: shopLon,
      status: status,
      reasonToCancel: reasonToCancel,
      deliveredDatetime: deliveredDatetime,
      eta: eta,
      riderPhone: riderPhone,
      acceptedByShop: acceptedByShop,
      acceptedByRider: acceptedByRider,
      isShopOrder: isShopOrder,
      chatId: chatId,
      type: type,
      sender: sender,
      receiver: receiver,
      senderAddress: senderAddress,
      receiverAddress: receiverAddress,
      instructions: instructions,
      groceryList: groceryList,
      riderReachedMart: riderReachedMart,
      estimatedDeliveryCharges: estimatedDeliveryCharges,
      grocerySubtotal: grocerySubtotal,
      riderReachedMartAt: riderReachedMartAt,
    );
  }

  void _pricePrecaution() {
    if ((resolvedType == ORDER_TYPE.TANDOOR
            ? _subtotalPrice <= 0
            : grocerySubtotal <= 0) ||
        _totalPrice <= 0 ||
        (fromWallet ?? -1) < 0) {
      calculatePrices(deliveryPrice: deliveryPrice);
    }
  }

  void calculatePrices({double deliveryPrice}) {
    if (resolvedType == ORDER_TYPE.TANDOOR) {
      deliveryPrice = deliveryPrice ?? this.deliveryPrice;
      fromWallet = fromWallet ?? 0;
      if (fromWallet < 0) fromWallet = 0;
      subtotalPrice = 0;
      orderItems.forEach(
        (item) {
          subtotalPrice = _subtotalPrice + (item.price * item.quantity);
        },
      );
      this.deliveryPrice = deliveryPrice;
      totalPrice = deliveryPrice + _subtotalPrice - fromWallet;

      if (_totalPrice < 0) {
        fromWallet = deliveryPrice + _subtotalPrice;
        totalPrice = 0;
      }
    } else {
      this.deliveryPrice = deliveryPrice ?? this.deliveryPrice;
      _totalPrice = grocerySubtotal + this.deliveryPrice - fromWallet;
    }
  }

  static double calculateMartOrderDeliveryPrice(
      double minDeliveryPrice, double distance) {
    double deliveryPrice = (20 + (10 * (distance / 1000))).roundToDouble();
    printInfo(
      "Distance for MartOrder is ${distance.toStringAsFixed(0)}m and delivery price is $deliveryPrice ($minDeliveryPrice)",
    );
    if (deliveryPrice < minDeliveryPrice) deliveryPrice = minDeliveryPrice;
    return deliveryPrice;
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "address": address?.toMap(),
      "contactInfo": contactInfo?.toMap(),
      "orderItems": List.generate(
        orderItems.length ?? 0,
        (index) => orderItems[index].toMap(),
      ),
      "deliveryPrice": deliveryPrice,
      "fromWallet": fromWallet,
      "datetime": datetime,
      "shopAcceptDatetime": shopAcceptDatetime,
      "riderAcceptDatetime": riderAcceptDatetime,
      "uid": uid,
      "shopId": shopId,
      "riderId": riderId,
      "riderName": riderName,
      "canceled": canceled,
      "shopName": shopName,
      "shopAddress": shopAddress,
      "shopLat": shopLat,
      "shopLon": shopLon,
      "status": status,
      "reasonToCancel": reasonToCancel,
      "s_datetime": epochToFormattedDatetime(datetime),
      "deliveredDatetime": deliveredDatetime,
      "eta": eta,
      "riderPhone": riderPhone,
      "acceptedByShop": acceptedByShop,
      "acceptedByRider": acceptedByRider,
      "isShopOrder": isShopOrder,
      "chatId": chatId,
      "type": type,
      "sender": sender?.toMap(),
      "receiver": receiver?.toMap(),
      "senderAddress": senderAddress?.toMap(),
      "receiverAddress": receiverAddress?.toMap(),
      "instructions": instructions,
      "groceryList": groceryList,
      "riderReachedMart": riderReachedMart,
      "estimatedDeliveryCharges": estimatedDeliveryCharges,
      "grocerySubtotal": grocerySubtotal,
      "riderReachedMartAt": riderReachedMartAt,
    };
  }
}

enum ORDER_STATUS {
  NEW_ORDER,
  ASSIGNED_TO_SHOP,
  ASSIGNED_TO_RIDER,
  ON_THE_WAY,
  DELIVERED
}

enum ORDER_TYPE {
  TANDOOR,
  PARCEL,
  SHOPPING,
}
