import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:user/common/shared.dart';
import 'package:user/common/tandoor_menu.dart';
import 'package:user/managers/database_manager.dart';
import 'package:user/models/wallet.dart';

import 'address.dart';
import 'contact_info.dart';
import 'order.dart';
import 'order_item.dart';

class SubCart {
  List<OrderItem> orderItems;
  double deliveryPrice = 0;
  String shopId;
  String shopName;
  String shopAddress;
  double shopLat = 0;
  double shopLon = 0;

  SubCart({
    this.orderItems,
    this.deliveryPrice,
    this.shopId,
    this.shopName,
    this.shopAddress,
    this.shopLat,
    this.shopLon,
  }) {
    orderItems = orderItems ?? [];
  }
}

extension SubCartsExtension on List<SubCart> {
  SubCart findByShopId(String shopId) {
    return this.firstWhere(
      (subCart) => subCart.shopId == shopId,
      orElse: () => null,
    );
  }
}

class Cart {
  Address address;
  ContactInfo contactInfo;
  double deliveryPrice = 0;
  List<SubCart> _subCarts;

  set subCarts(List<SubCart> subCarts) => _subCarts = subCarts ?? [];

  List<SubCart> get subCarts => _subCarts ?? [];

  int get cartQuantity {
    int quantity = 0;
    for (SubCart sc in subCarts ?? []) {
      quantity += calculateCartQuantity(sc.orderItems);
    }
    return quantity;
  }

  bool get isGeneral {
    return subCarts.length == 1 &&
        (subCarts[0].shopId == null || subCarts[0].shopId.isEmpty);
  }

  Cart._();

  Cart({
    this.address,
    this.contactInfo,
    @required this.deliveryPrice,
    List<SubCart> subCarts,
  }) {
    assert(deliveryPrice != null);
    this.subCarts = subCarts;
  }

  List<Order> toOrders() {
    String uid = FirebaseAuth?.instance?.currentUser?.uid; // Should not be null
    double wallet = getIt.get<Wallet>().amount;

    if (uid == null) {
      throw Exception("User is not logged in");
    }

    subCarts.removeWhere((subCart) => subCart.orderItems.length == 0);

    List<Order> orders = List.generate(subCarts.length, (index) {
      SubCart c = subCarts[index];
      Order order = Order(
        id: DatabaseManager.instance.orders.doc().id,
        address: this.address,
        contactInfo: this.contactInfo,
        orderItems: c.orderItems.map((e) => e.clone()).toList(),
        deliveryPrice: (c.deliveryPrice == null || c.deliveryPrice <= 0)
            ? this.deliveryPrice
            : c.deliveryPrice,
        shopId: c.shopId,
        shopName: c.shopName,
        shopAddress: c.shopAddress,
        shopLat: c.shopLat,
        shopLon: c.shopLon,
        uid: uid,
        isShopOrder: (c.shopId ?? "").length > 0 ?? false,
        fromWallet: 0,
      );
      order.calculatePrices();

      if (wallet > 0) {
        if (order.totalPrice > wallet) {
          order.fromWallet = wallet;
          wallet = 0;
        } else {
          order.fromWallet = order.totalPrice;
          wallet = wallet - order.fromWallet;
        }
        order.calculatePrices();
      }

      return order;
    });

    return orders;
  }

  void clear() {
    address = null;
    contactInfo = null;
    subCarts = [];
    // deliveryPrice = 0; // Not changing delivery price
  }

  static Future<Cart> newEmpty({double deliveryPrice}) async {
    Cart cart = Cart._();

    if (deliveryPrice == null) {
      try {
        await TandoorMenu.loadTandoorAppConfig();
      } catch (e) {
        printInfo("Error in calling loadTandoorAppConfig: $e");
      } finally {
        deliveryPrice = double.parse(
          "${TandoorMenu.tandoorAppConfig["delivery_charges"]}",
        );
      }
    }

    cart.deliveryPrice = deliveryPrice;
    cart.subCarts = [];

    return cart;
  }
}
