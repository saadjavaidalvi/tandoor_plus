import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user/common/app_bar.dart';
import 'package:user/common/app_progress_bar.dart';
import 'package:user/common/draggable_list_view.dart';
import 'package:user/common/marquee_widget.dart';
import 'package:user/common/shared.dart';
import 'package:user/common/tandoor_menu.dart';
import 'package:user/common/tile_text.dart';
import 'package:user/managers/database_manager.dart';
import 'package:user/models/address.dart';
import 'package:user/models/cart.dart';
import 'package:user/models/contact_info.dart';
import 'package:user/models/db_entities.dart';
import 'package:user/models/near_shop_orders.dart';
import 'package:user/models/order.dart';
import 'package:user/pages/home_page.dart';
import 'package:user/pages/order_page.dart';
import 'package:user/pages/your_orders_page.dart';

import 'address_page.dart';
import 'contact_info_page.dart';

class OrderSummaryPage extends StatefulWidget {
  static final String route = "order_summary";

  OrderSummaryPage();

  @override
  _OrderSummaryPageState createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  bool progressBarVisible;

  bool addressesListVisible;
  List<AddressEntity> _addressEntities = [];

  bool contactsListVisible;
  List<ContactInfoEntity> _contactInfoEntities = [];

  List<Order> orders;
  List<NearShopOrders> nearShopOrdersList;

  _OrderSummaryPageState() {
    orders = getIt.get<Cart>().toOrders();
    printInfo("Number of orders are: ${orders.length}");
    orders.forEach((order) {
      if (order.shopId == null || order.shopId.isEmpty) {
        order.shopId = null;
        order.shopAddress = null;
        order.shopName = null;
      }
      order.orderItems.removeWhere(
        (element) => element.quantity <= 0 || element.quantity <= 0,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    assert(orders != null);
    assert(orders.length > 0);

    addressesListVisible = false;
    _addressEntities = [];
    DatabaseManager.instance.getAddresses().then((addressEntities) {
      _addressEntities = addressEntities;
    });

    contactsListVisible = false;
    _contactInfoEntities = [];
    nearShopOrdersList = [];

    loadUserInformation();

    if (orders.length > 0 && orders[0].isShopOrder) {
      progressBarVisible = true;
      groupByShops();
    } else {
      progressBarVisible = false;
    }
  }

  void groupByShops() async {
    List<Order> shopOrders =
        orders.where((order) => order.isShopOrder).toList();
    List<Map<String, dynamic>> locs =
        await DatabaseManager.instance.getShopLocations(
      List.generate(shopOrders.length, (index) => shopOrders[index].id),
      List.generate(shopOrders.length, (index) => shopOrders[index].shopId),
    );

    List<NearShopOrders> _nearShopOrdersList = groupOrdersByCloseShops(
      DatabaseManager.instance.nearShopOrders,
      locs,
    );

    updateDiscountDeliveryPrices(_nearShopOrdersList);

    setState(() {
      nearShopOrdersList = _nearShopOrdersList;
      progressBarVisible = false;
    });
  }

  void updateDiscountDeliveryPrices(
      [List<NearShopOrders> _nearShopOrdersList]) {
    if (orders.length == 1 && !orders[0].isShopOrder) return;

    _nearShopOrdersList = _nearShopOrdersList ?? nearShopOrdersList;
    List<Order> _orders = [];
    bool isFirst;

    for (NearShopOrders nearShopOrders in _nearShopOrdersList) {
      isFirst = true;
      for (String id in nearShopOrders.orderIds) {
        Order order = orders.firstWhere((element) => element.id == id,
            orElse: () => null);
        if (order != null) {
          if (isFirst) {
            isFirst = false;
            order.deliveryPrice =
                order.originalDeliveryPrice ?? order.deliveryPrice;
            order.calculatePrices();
          } else {
            order.originalDeliveryPrice = order.deliveryPrice;
            order.deliveryPrice =
                TandoorMenu.tandoorAppConfig["near_shop_delivery_charges"];
            order.calculatePrices();
          }
          _orders.add(order);
        }
      }
    }

    setState(() {
      orders = _orders;
    });
  }

  void loadUserInformation() async {
    User user = FirebaseAuth.instance.currentUser;
    List<ContactInfoEntity> contactInfoEntities =
        await DatabaseManager.instance.getContactInfos();
    if (contactInfoEntities.isEmpty) {
      ContactInfoEntity contactInfoEntity = ContactInfoEntity(
        uid: user.uid,
        name: user.displayName,
        phoneNumber: user.phoneNumber,
        email: user.email,
      );
      ContactInfoEntity newContactInfo =
          await DatabaseManager.instance.addNewContactInfo(contactInfoEntity);
      if (newContactInfo != null)
        setState(() {
          _contactInfoEntities = [newContactInfo];
        });
    } else {
      setState(() {
        _contactInfoEntities = contactInfoEntities;
      });
    }

    ContactInfo contactInfo;
    bool hasNullContact = false;
    orders.forEach((order) {
      if (order.contactInfo != null)
        contactInfo = order.contactInfo;
      else
        hasNullContact = true;
    });
    if (contactInfo == null) {
      if (_contactInfoEntities.length > 0) {
        orders.forEach((order) {
          order.contactInfo =
              ContactInfo.fromContactInfoEntity(_contactInfoEntities[0]);
        });
      }
    } else if (hasNullContact) {
      orders.forEach((order) {
        order.contactInfo = contactInfo;
      });
    }
  }

  void calculatePrices(String itemId, int quantity) {
    int orderIndex = -1;
    List<int> indexesToRemove = [];
    List<Order> _orders = orders;

    _orders.forEach((order) {
      orderIndex++;

      // Remove items with quantity 0
      int i = order.orderItems.indexWhere((element) => element.id == itemId);

      if (i >= 0) {
        order.orderItems[i].quantity = quantity;

        if (order.orderItems[i].quantity <= 0 ||
            order.orderItems[i].price <= 0) {
          if (order.orderItems.length == 1) {
            indexesToRemove.add(orderIndex);
          } else {
            order.orderItems.removeAt(i);
          }
        }

        order.calculatePrices();
      }
    });

    if (indexesToRemove.isEmpty) {
      setState(() {
        orders = _orders;
      });
    } else {
      indexesToRemove = indexesToRemove.reversed.toList();
      indexesToRemove.forEach((index) {
        _orders.removeAt(index);
      });
      if (_orders.length > 0) {
        setState(() {
          orders = _orders;
        });
        updateDiscountDeliveryPrices();
      } else {
        Navigator.pop(context);
      }
    }
  }

  void checkout() async {
    setState(() {
      progressBarVisible = true;
    });

    Address address = orders[0].address;
    ContactInfo contactInfo = orders[0].contactInfo;
    String uid = orders[0].uid;

    if (address?.city == null || address.city.length < 3) {
      setState(() {
        addressesListVisible = true;
      });
    } else if (contactInfo?.name == null ||
        contactInfo?.phone == null ||
        contactInfo.name.length < 3 ||
        !(isValidPhoneNumber(contactInfo.phone) ||
            isValidPhoneNumber("+" + contactInfo.phone))) {
      setState(() {
        contactsListVisible = true;
      });
    } else if ((orders?.length ?? 0) == 0) {
      Navigator.pop(context);
    } else if ((uid ?? "").length < 5) {
      showOkMessage(context, "Logged out",
          "Sorry you are not logged in. Please restart the app and login again.",
          cancelable: false,
          onDismiss: () => SystemNavigator.pop(animated: true));
      Navigator.pop(context);
    } else {
      List<String> orderIds = await DatabaseManager.instance
          .saveNewOrders(orders, nearShopOrdersList);

      getIt.get<Cart>().clear();

      Navigator.popUntil(
        context,
        (route) => route.settings.name == HomePage.route,
      );

      if (orderIds.length == 1) {
        Navigator.pushNamed(
          context,
          OrderPage.route,
          arguments: orderIds[0],
        );
      } else {
        Navigator.pushNamed(context, YourOrdersPage.route);
      }
    }

    setState(() {
      progressBarVisible = false;
    });
  }

  void hideAddressList() {
    setState(() {
      addressesListVisible = false;
    });
  }

  hideContactInfoList() {
    setState(() {
      contactsListVisible = false;
    });
  }

  void setAddress(int i) {
    hideAddressList();
    Address address = Address.fromAddressEnt(_addressEntities[i]);

    orders.forEach((order) {
      order.address = address;
    });
  }

  void setContactInfo(int i) {
    hideContactInfoList();
    ContactInfo contactInfo =
        ContactInfo.fromContactInfoEntity(_contactInfoEntities[i]);

    orders.forEach((order) {
      order.contactInfo = contactInfo;
    });
  }

  void addNewAddress() async {
    hideAddressList();
    await Get.delete(tag: MartOrderTag);
    Navigator.pushNamed(
      context,
      AddressPage.route,
      arguments: ContactInfoType.TANDOOR_DROP_OFF,
    ).then((_newAddressEntity) {
      if (_newAddressEntity != null) {
        AddressEntity newAddressEntity = _newAddressEntity as AddressEntity;
        _addressEntities.add(newAddressEntity);
        setAddress(_addressEntities.length - 1);
      }
    });
  }

  void addNewContactInfo() async {
    hideContactInfoList();
    await Get.delete(tag: MartOrderTag);
    Navigator.pushNamed(
      context,
      ContactInfoPage.route,
      arguments: [ContactInfoType.TANDOOR_DROP_OFF],
    ).then((_newContactInfoEntity) {
      if (_newContactInfoEntity != null) {
        ContactInfoEntity newContactInfoEntity =
            _newContactInfoEntity as ContactInfoEntity;
        _contactInfoEntities.add(newContactInfoEntity);
        setContactInfo(_contactInfoEntities.length - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int cartQuantity = 0;
    double totalPrice = 0;

    TextStyle textButtonStyle = TextStyle(
      fontSize: getARFontSize(context, NormalSize.S_16),
      color: appPrimaryColor,
    );

    orders.forEach((order) {
      cartQuantity += order.cartQuantity;
      totalPrice = totalPrice + order.subtotalPrice + order.deliveryPrice;
    });

    List<ListTileTemplate> addresses = [
      TitleListTile(
        "Select delivery address",
        onBack: hideAddressList,
      ),
      SelectionListTitle(
        "Add New Destination",
        onTap: addNewAddress,
        fontColor: appPrimaryColor,
        leadingIcon: Icons.add,
      ),
      ...List.generate(
        _addressEntities.length,
        (index) => SelectionListTitle(
          _addressEntities[index].toTitle(),
          leadingImage: "assets/icons/ic_address2.png",
          onTap: () {
            setAddress(index);
          },
        ),
      ),
    ];

    List<ListTileTemplate> contactInfos = [
      TitleListTile(
        "Select Contact Info",
        onBack: hideContactInfoList,
      ),
      SelectionListTitle(
        "Add New Contact Info",
        onTap: addNewContactInfo,
        fontColor: appPrimaryColor,
        leadingIcon: Icons.add,
      ),
      ...List.generate(
        _contactInfoEntities.length,
        (index) => SelectionListTitle(
          _contactInfoEntities[index].name,
          leadingIcon: Icons.call,
          onTap: () {
            setContactInfo(index);
          },
        ),
      ),
    ];

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: getAppBar(
          context,
          AppBarType.backWithWidget,
          title: "Order Summary",
          leadingWidget: Stack(
            alignment: AlignmentDirectional.topEnd,
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                "assets/icons/ic_cart.png",
                height: 14,
              ),
              Visibility(
                visible: cartQuantity > 0,
                child: Positioned(
                  top: -8,
                  right: -5,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.15),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: 1,
                        ),
                        child: Text(
                          "$cartQuantity",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: GoogleFonts.lato().fontFamily,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          onBackPressed: () {
            Navigator.pop(context);
          },
        ),
        body: Stack(
          children: [
            Container(
              color: Color(0xFFF9F9F6),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.06),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              )
                            ]),
                        child: ClipPath(
                          clipper: _PointsClipper(),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Color(0xFFEFEFEF),
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                ...List.generate(
                                  orders.length,
                                  (index) {
                                    Order order = orders[index];
                                    return _SubOrderCartItem(
                                      isLast: index + 1 == orders.length,
                                      tandoorName: order.shopName,
                                      subTotal: order.subtotalPrice,
                                      deliveryPrice: order.deliveryPrice,
                                      wallet: order.fromWallet,
                                      total: order.totalPrice,
                                      cartItems: List.generate(
                                        order.orderItems.length,
                                        (index2) => _CartItem(
                                          order.orderItems[index2].id,
                                          order.orderItems[index2].name,
                                          order.orderItems[index2].urduName,
                                          order.orderItems[index2].price,
                                          order.orderItems[index2].quantity,
                                          calculatePrices,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Divider(color: Colors.transparent),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Color(0xFFEFEFEF), width: 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.06),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Delivery Details: ",
                                  style: AppTextStyle.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Visibility(
                                  visible:
                                      orders[0].address?.buildingName != null,
                                  child: Text(
                                    orders[0].address?.buildingName ?? "",
                                    style: AppTextStyle.copyWith(
                                        color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                            Divider(
                              color: Colors.transparent,
                              height: 8,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    orders[0].address?.toString() ?? "",
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: AppTextStyle.copyWith(
                                      color: Color(0xFFC8C8C8),
                                    ),
                                  ),
                                ),
                                VerticalDivider(color: Colors.transparent),
                                TextButton(
                                  onPressed: orders[0].address == null
                                      ? addNewAddress
                                      : () {
                                          setState(() {
                                            addressesListVisible = true;
                                          });
                                        },
                                  style: ButtonStyle(
                                    padding: MaterialStateProperty.all(
                                        EdgeInsets.zero),
                                  ),
                                  child: Text(
                                    orders[0].address == null
                                        ? "Add"
                                        : "Change",
                                    style: textButtonStyle,
                                  ),
                                ),
                              ],
                            ),
                            Divider(),
                            Text(
                              "Contact info",
                              style: AppTextStyle.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        orders[0].contactInfo?.name ??
                                            orders[0].contactInfo?.email ??
                                            "",
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: AppTextStyle.copyWith(
                                          color: Color(0xFFC8C8C8),
                                        ),
                                      ),
                                      Text(
                                        orders[0].contactInfo?.phone ?? "",
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: AppTextStyle.copyWith(
                                          color: Color(0xFFC8C8C8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                VerticalDivider(color: Colors.transparent),
                                TextButton(
                                  onPressed: orders[0].contactInfo == null
                                      ? addNewContactInfo
                                      : () {
                                          setState(() {
                                            contactsListVisible = true;
                                          });
                                        },
                                  style: ButtonStyle(
                                    padding: MaterialStateProperty.all(
                                        EdgeInsets.zero),
                                  ),
                                  child: Text(
                                    orders[0].contactInfo == null
                                        ? "Add"
                                        : "Change",
                                    style: textButtonStyle,
                                  ),
                                ),
                              ],
                            ),
                            // Todo: Add delivery time
                          ],
                        ),
                      ),
                      Divider(color: Colors.transparent),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Color(0xFFEFEFEF), width: 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.06),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Payment Methods",
                              style: AppTextStyle.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Divider(
                              height: 8,
                              color: Colors.transparent,
                            ),
                            Row(
                              children: [
                                Image.asset(
                                  "assets/icons/ic_cod.png",
                                  width: 18,
                                ),
                                VerticalDivider(
                                  color: Colors.transparent,
                                ),
                                Expanded(
                                  child: Text(
                                    "Cash on delivery",
                                    style: AppTextStyle,
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        color: Colors.transparent,
                        height: 60,
                      ),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.06),
                            spreadRadius: 1,
                            blurRadius: 2,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Rs. ${totalPrice.toStringAsFixed(2)}",
                                    style: AppTextStyle.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    "(Tax included)",
                                    style: AppTextStyle.copyWith(
                                      color: Color(0xFFC8C8C8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ElevatedButton(
                                style: ButtonStyle(
                                  elevation: MaterialStateProperty.all(3),
                                  backgroundColor: MaterialStateProperty.all(
                                    appPrimaryColor,
                                  ),
                                  shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                onPressed: checkout,
                                child: Text(
                                  "Checkout",
                                  style: AppTextStyle.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            DraggableListView(
              visible: addressesListVisible,
              children: addresses,
              onHide: hideAddressList,
            ),
            DraggableListView(
              visible: contactsListVisible,
              children: contactInfos,
              onHide: hideContactInfoList,
            ),
            AppProgressBar(visible: progressBarVisible),
          ],
        ),
      ),
    );
  }
}

class _SubOrderCartItem extends StatelessWidget {
  final bool isLast;
  final String tandoorName;
  final double subTotal;
  final double deliveryPrice;
  final double wallet;
  final double total;
  final List<_CartItem> cartItems;

  _SubOrderCartItem({
    this.isLast: false,
    @required this.tandoorName,
    @required @required this.subTotal,
    @required this.deliveryPrice,
    @required this.wallet,
    @required this.total,
    @required this.cartItems,
  }) : super(key: UniqueKey());

  @override
  Widget build(BuildContext context) {
    printInfo("Wallet value received is: $wallet");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tandoorName ?? "Tandoor",
          style: AppTextStyle.copyWith(fontWeight: FontWeight.bold),
        ),
        Divider(
          height: 8,
          color: Colors.transparent,
        ),
        ...cartItems,
        Divider(),
        Row(
          children: [
            Expanded(
              child: Text(
                "Subtotal",
                style: AppTextStyle,
              ),
            ),
            Text(
              "Rs. ${subTotal.toStringAsFixed(2)}",
              style: AppTextStyle,
            ),
          ],
        ),
        Divider(
          color: Colors.transparent,
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                "Delivery Fee",
                style: AppTextStyle,
              ),
            ),
            Text(
              "Rs. ${deliveryPrice.toStringAsFixed(2)}",
              style: AppTextStyle,
            ),
          ],
        ),
        Visibility(
          visible: wallet > 0,
          child: Divider(
            color: Colors.transparent,
          ),
        ),
        Visibility(
          visible: wallet > 0,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "Wallet",
                  style: AppTextStyle,
                ),
              ),
              Text(
                "-Rs. ${wallet.toStringAsFixed(2)}",
                style: AppTextStyle,
              ),
            ],
          ),
        ),
        Divider(),
        Row(
          children: [
            Text(
              "Total ",
              style: AppTextStyle.copyWith(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Text(
                "(incl. VAT)",
                style: AppTextStyle.copyWith(
                  color: Color(0xFFC8C8C8),
                ),
              ),
            ),
            Text(
              "Rs. ${total.toStringAsFixed(2)}",
              style: AppTextStyle.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        // Divider(
        //   height: isLast ? 0 : 16,
        //   color: isLast ? Colors.transparent : null,
        // ),
        Divider(
          color: isLast ? Colors.transparent : null,
          height: isLast ? 8 : 16,
        ),
      ],
    );
  }
}

class _CartItem extends StatefulWidget {
  final String itemId;
  final String nameEnglish;
  final String urduName;
  final double price;
  final int quantity;
  final Function quantityUpdated;

  _CartItem(
    this.itemId,
    this.nameEnglish,
    this.urduName,
    this.price,
    this.quantity,
    void
        this.quantityUpdated(
      String itemId,
      int newQuantity,
    ),
  );

  @override
  __CartItemState createState() => __CartItemState();
}

class __CartItemState extends State<_CartItem> {
  int quantity;

  @override
  void initState() {
    super.initState();

    quantity = widget.quantity;
  }

  void quantityUpdated() {
    widget.quantityUpdated?.call(widget.itemId, quantity);
  }

  void plus() {
    setState(() {
      quantity++;
      quantityUpdated();
    });
  }

  void minus({bool force = false}) {
    if (quantity > 1 || force) {
      setState(() {
        quantity--;
        quantityUpdated();
      });
    } else if (quantity == 1) {
      showYesNoMessage(
        context,
        "Remove item?",
        "Do you want to remove ${widget.nameEnglish ?? widget.urduName} from cart?",
        onYes: () {
          minus(force: true);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          InkWell(
            onTap: minus,
            child: Image.asset(
              "assets/icons/ic_q_minus_active.png",
              width: 20,
            ),
          ),
          Container(
            width: 30,
            child: Text(
              "$quantity",
              style: AppTextStyle.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          InkWell(
            onTap: plus,
            child: Image.asset(
              "assets/icons/ic_q_plus.png",
              width: 20,
            ),
          ),
          VerticalDivider(color: Colors.transparent),
          Expanded(
            child: MarqueeWidget(
              child: Text(
                "${widget.nameEnglish}",
                style: AppTextStyle.copyWith(fontSize: 16),
              ),
            ),
          ),
          VerticalDivider(color: Colors.transparent),
          Text(
            "Rs. ${(widget.price * quantity).toStringAsFixed(2)}",
            style: AppTextStyle,
          ),
        ],
      ),
    );
  }
}

// Taken from package flutter_custom_clippers and updated
class _PointsClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    double x = 0;
    double y = size.height * .95;
    path.lineTo(x, y);

    double increment = size.width / 40;

    while (x < size.width) {
      x += increment;
      y = (y == size.height) ? size.height * .97 : size.height;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, 0.0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper old) {
    return old != this;
  }
}
