import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user/common/app_bar.dart';
import 'package:user/common/app_progress_bar.dart';
import 'package:user/common/shared.dart';
import 'package:user/managers/database_manager.dart';
import 'package:user/models/order.dart';
import 'package:user/models/order_item.dart';
import 'package:user/pages/chat_page.dart';

ConfettiController _confettiController;

class OrderPage extends StatefulWidget {
  static final String route = "order";

  final String orderId;
  final bool openChat;

  OrderPage(this.orderId, this.openChat);

  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  Order order;
  String riderPhone;
  bool firstRun;

  GlobalKey<ScaffoldState> _scaffoldKey;

  dynamic orderChangesSubscription;

  bool firstConfettiFired = false;
  bool secondConfettiFired = false;

  @override
  void initState() {
    super.initState();

    firstRun = true;

    _confettiController = ConfettiController(
      duration: Duration(milliseconds: 300),
    );

    _scaffoldKey = GlobalKey<ScaffoldState>();

    listenToOrderChanges();
  }

  void listenToOrderChanges() async {
    orderChangesSubscription = await DatabaseManager.instance
        .addOrderListener(widget.orderId, (order) {
      if (order != null && _confettiController != null && !order.canceled) {
        if (order.resolvedStatus == ORDER_STATUS.ASSIGNED_TO_RIDER) {
          if (!firstConfettiFired) {
            _confettiController.play();
            firstConfettiFired = true;
          }
        } else if (order.resolvedStatus.index >= ORDER_STATUS.DELIVERED.index) {
          if (!secondConfettiFired) {
            _confettiController.play();
            secondConfettiFired = true;
          }
        }
      }
      if (mounted) {
        setState(() {
          this.order = order;
        });
      } else {
        this.order = order;
      }
      if (firstRun && widget.openChat) {
        firstRun = false;
        openChat();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    if (orderChangesSubscription != null) orderChangesSubscription.cancel();
    super.dispose();
  }

  void callRider() {
    if (order.riderPhone != null) {
      String url = "tel:${order.riderPhone}";
      canLaunch(url).then((value) => launch(url));
    }
  }

  void openChat() {
    Navigator.of(context).pushNamed(ChatPage.route, arguments: order);
  }

  @override
  Widget build(BuildContext context) {
    double timeLineHeight = 245;
    double timeLineWidth = 32;

    String statusImage = "";
    String statusMessage = "";
    String reason = "";
    ORDER_STATUS orderStatus = ORDER_STATUS.NEW_ORDER;
    ORDER_TYPE orderType = ORDER_TYPE.TANDOOR;
    String preparingTitle = "Preparing order";

    if (order != null) {
      orderStatus = order.resolvedStatus;
      orderType = order.resolvedType;

      if (!order.canceled) {
        if (orderType == ORDER_TYPE.TANDOOR &&
            order.acceptedByRider &&
            !order.acceptedByShop) {
          orderStatus = ORDER_STATUS.NEW_ORDER;
        }

        switch (orderStatus) {
          case ORDER_STATUS.NEW_ORDER:
          case ORDER_STATUS.ASSIGNED_TO_SHOP:
            statusImage = "assets/icons/ic_order_status_0.png";
            statusMessage = "We got your order, yay!";
            break;
          case ORDER_STATUS.ASSIGNED_TO_RIDER:
            if (orderType == ORDER_TYPE.TANDOOR) {
              statusImage = "assets/icons/ic_order_status_2.png";
              statusMessage =
                  "Preparing your order, Your rider will pick it up once it's ready";
            } else {
              statusImage = "assets/icons/ic_order_status_3.png";
              if (order.riderReachedMart) {
                statusMessage = "Rider has reached at the pickup location.";
              } else {
                statusMessage = "Your order is confirmed! Rider is on the way.";
              }
            }
            break;
          case ORDER_STATUS.ON_THE_WAY:
            statusImage = "assets/icons/ic_order_status_3.png";
            statusMessage = "Your rider has picked up your order";
            break;
          default:
            statusImage = "assets/icons/ic_order_status_4.png";
            statusMessage = orderType == ORDER_TYPE.TANDOOR
                ? "Enjoy your fresh Naans!"
                : "Your order has been delivered!";
        }
      } else {
        statusImage = "assets/icons/ic_order_status_canceled.png";
        statusMessage = "Order was canceled";

        switch (order.reasonToCancel) {
          case 1:
            reason = "Shop not available";
            break;
          case 2:
            reason = "Rider not available";
            break;
          default:
            reason = "Reason unknown";
        }
      }

      switch (orderType) {
        case ORDER_TYPE.TANDOOR:
          break;
        case ORDER_TYPE.PARCEL:
          preparingTitle = "Picking up package";
          break;
        case ORDER_TYPE.SHOPPING:
          preparingTitle = "Picking up grocery";
          break;
      }
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: getAppBar(
          context,
          AppBarType.backWithButton,
          title: "Your order",
          centerTitle: true,
          buttonText: "Help",
          onBackPressed: () {
            Navigator.pop(context, true);
          },
          onButtonPressed: () => showHelpMessage(context),
          trailing: order != null &&
                  !order.canceled &&
                  !GetUtils.isNullOrBlank(order.riderId) &&
                  order.resolvedStatus == ORDER_STATUS.DELIVERED
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: openChat,
                  child: Image.asset(
                    "assets/icons/ic_chat.png",
                    width: 32,
                  ),
                )
              : null,
        ),
        body: Container(
          color: Color(0xFFF9F9F9),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: order == null
              ? AppProgressBar(visible: true)
              : ListView(
                  children: [
                    Visibility(
                      visible: orderStatus.index >=
                              ORDER_STATUS.ASSIGNED_TO_RIDER.index &&
                          !order.canceled,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.only(top: 24),
                        child: Column(
                          children: [
                            Text(
                                orderStatus.index < ORDER_STATUS.DELIVERED.index
                                    ? "Estimated delivery time"
                                    : "Delivered at"),
                            Divider(
                              height: 6,
                              color: Colors.transparent,
                            ),
                            orderStatus.index >= ORDER_STATUS.DELIVERED.index
                                ? Text(
                                    "${epochToShortTime(order.deliveredDatetime)}",
                                    style: AppTextStyle.copyWith(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : (order.eta > 0
                                    ? _ETATimer(order.eta)
                                    : Text(
                                        "...",
                                        style: AppTextStyle.copyWith(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      color: Colors.white,
                      padding: order.canceled
                          ? const EdgeInsets.all(24)
                          : const EdgeInsets.only(
                              left: 24, right: 24, top: 14, bottom: 24),
                      child: Stack(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.width / 3,
                            child: Center(
                              child: ConfettiWidget(
                                confettiController: _confettiController,
                                blastDirectionality:
                                    BlastDirectionality.explosive,
                                particleDrag: 0.1,
                                emissionFrequency: 0.4,
                                maximumSize: Size(20, 10),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              Image.asset(
                                statusImage,
                                width: MediaQuery.of(context).size.width / 3,
                                height: MediaQuery.of(context).size.width / 3,
                                fit: BoxFit.contain,
                              ),
                              Divider(
                                color: Colors.transparent,
                              ),
                              Text(
                                statusMessage,
                                style: AppTextStyle.copyWith(fontSize: 15),
                                textAlign: TextAlign.center,
                              ),
                              Visibility(
                                visible: order.canceled,
                                child: Text(
                                  reason,
                                  style: AppTextStyle.copyWith(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: !order.canceled &&
                              (orderStatus == ORDER_STATUS.ASSIGNED_TO_RIDER ||
                                  orderStatus == ORDER_STATUS.ON_THE_WAY) ||
                          true,
                      child: Divider(
                        color: Colors.transparent,
                      ),
                    ),
                    Visibility(
                      visible: !order.canceled &&
                          (orderStatus == ORDER_STATUS.ASSIGNED_TO_RIDER ||
                              orderStatus == ORDER_STATUS.ON_THE_WAY),
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/icons/ic_delivery_boy.png",
                              height: 44,
                            ),
                            VerticalDivider(
                              color: Colors.transparent,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Contact your rider",
                                    style: AppTextStyle.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Ask for contactless delivery",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            VerticalDivider(
                              color: Colors.transparent,
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: callRider,
                              child: Container(
                                child: Image.asset(
                                  "assets/icons/ic_phone_number.png",
                                  height: 36,
                                ),
                              ),
                            ),
                            VerticalDivider(
                              color: Colors.transparent,
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: openChat,
                              child: Container(
                                child: Image.asset(
                                  "assets/icons/ic_chat.png",
                                  height: 36,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(
                      color: Colors.transparent,
                    ),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Order Status:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              Text(
                                "${epochToShortDate(order.datetime)}",
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Divider(
                            height: 28,
                            color: Colors.transparent,
                          ),
                          Container(
                            height: timeLineHeight,
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: timeLineWidth,
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Opacity(
                                              opacity: orderStatus.index >=
                                                      ORDER_STATUS
                                                          .ASSIGNED_TO_RIDER
                                                          .index
                                                  ? 1
                                                  : 0.4,
                                              child: Image.asset(
                                                "assets/icons/ic_order_timeline_line.png",
                                                height: (timeLineHeight / 2) -
                                                    timeLineWidth,
                                              ),
                                            ),
                                            Opacity(
                                              opacity: orderStatus.index >=
                                                      ORDER_STATUS
                                                          .ON_THE_WAY.index
                                                  ? 1
                                                  : 0.4,
                                              child: Image.asset(
                                                "assets/icons/ic_order_timeline_line.png",
                                                height: (timeLineHeight / 2) -
                                                    timeLineWidth,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        child: Image.asset(
                                          "assets/icons/ic_order_timeline_0.png",
                                          width: timeLineWidth,
                                        ),
                                      ),
                                      Center(
                                        child: Opacity(
                                          opacity: orderStatus.index >=
                                                      ORDER_STATUS
                                                          .ASSIGNED_TO_RIDER
                                                          .index &&
                                                  (orderType ==
                                                          ORDER_TYPE.TANDOOR ||
                                                      order.riderReachedMart)
                                              ? 1
                                              : 0.4,
                                          child: Image.asset(
                                            orderType == ORDER_TYPE.TANDOOR
                                                ? "assets/icons/ic_order_timeline_2.png"
                                                : "assets/icons/ic_delivery_boy.png",
                                            width: timeLineWidth,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        child: Opacity(
                                          opacity: orderStatus.index >=
                                                  ORDER_STATUS.ON_THE_WAY.index
                                              ? 1
                                              : 0.4,
                                          child: Image.asset(
                                            "assets/icons/ic_order_timeline_3.png",
                                            width: timeLineWidth,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                VerticalDivider(
                                  color: Colors.transparent,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  order.canceled
                                                      ? "Order was canceled"
                                                      : "Order placed",
                                                  style: AppTextStyle.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Divider(
                                                  color: Colors.transparent,
                                                  height: 4,
                                                ),
                                                Text(order.canceled
                                                    ? reason
                                                    : "We have received your order"),
                                              ],
                                            ),
                                          ),
                                          VerticalDivider(
                                            width: 8,
                                            color: Colors.transparent,
                                          ),
                                          Text(
                                            epochToShortTime(order.datetime),
                                            style: AppTextStyle.copyWith(
                                              color: appPrimaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Opacity(
                                        opacity: orderStatus.index >=
                                                    ORDER_STATUS
                                                        .ASSIGNED_TO_RIDER
                                                        .index &&
                                                (orderType ==
                                                        ORDER_TYPE.TANDOOR ||
                                                    order.riderReachedMart)
                                            ? 1
                                            : 0.4,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    preparingTitle,
                                                    style:
                                                        AppTextStyle.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Divider(
                                                    color: Colors.transparent,
                                                    height: 4,
                                                  ),
                                                  Text(
                                                    "Please wait while we prepare your order",
                                                  ),
                                                  Divider(
                                                    color: Colors.transparent,
                                                    height: 4,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            VerticalDivider(
                                              width: 8,
                                              color: Colors.transparent,
                                            ),
                                            Text(
                                              epochToShortTime(
                                                orderType == ORDER_TYPE.TANDOOR
                                                    ? order.riderAcceptDatetime
                                                    : order.riderReachedMartAt,
                                              ),
                                              style: AppTextStyle.copyWith(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Opacity(
                                        opacity: orderStatus.index >=
                                                ORDER_STATUS.ON_THE_WAY.index
                                            ? 1
                                            : 0.4,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Delivery on the way",
                                                    style:
                                                        AppTextStyle.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Divider(
                                                    color: Colors.transparent,
                                                    height: 4,
                                                  ),
                                                  Text(
                                                      "Our rider is on his way to delivery your order"),
                                                  Divider(
                                                    color: Colors.transparent,
                                                    height: 4,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            VerticalDivider(
                                              width: 8,
                                              color: Colors.transparent,
                                            ),
                                            Visibility(
                                              visible:
                                                  order.deliveredDatetime > 0,
                                              child: Text(
                                                epochToShortTime(
                                                  order.deliveredDatetime,
                                                ),
                                                style: AppTextStyle.copyWith(
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: Colors.transparent,
                    ),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Order Details:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Divider(
                            height: 28,
                            color: Colors.transparent,
                          ),
                          Table(
                            columnWidths: {0: IntrinsicColumnWidth()},
                            children: [
                              TableRow(
                                children: [
                                  Text(
                                    "Your order id:",
                                    maxLines: 1,
                                  ),
                                  SelectableText(
                                    order.id,
                                    onTap: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text("Copied!"),
                                        ),
                                      );
                                      Clipboard.setData(
                                        new ClipboardData(text: order.id),
                                      );
                                    },
                                    textAlign: TextAlign.right,
                                    style: AppTextStyle.copyWith(
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                              TableRow(
                                children: [
                                  Text(
                                    "Delivery address:",
                                    maxLines: 1,
                                  ),
                                  Text(
                                    order.resolvedType == ORDER_TYPE.TANDOOR
                                        ? order.address.toString()
                                        : order.receiverAddress.toString(),
                                    textAlign: TextAlign.right,
                                    style: AppTextStyle,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Divider(
                            height: 12,
                            color: Colors.transparent,
                          ),
                          Center(
                            child: DottedLine(
                              lineLength: 100,
                              dashColor: appPrimaryColor,
                            ),
                          ),
                          ...List.generate(
                            order.resolvedType == ORDER_TYPE.TANDOOR ? 1 : 0,
                            (index) => _OrderItemsList(
                              orderItems: order.orderItems,
                              shopName: order.shopName,
                            ),
                          ),
                          Visibility(
                            visible:
                                order.resolvedType == ORDER_TYPE.SHOPPING &&
                                    order.groceryList != null,
                            child: Text(
                              "Grocery List:",
                              style: AppTextStyle.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Visibility(
                            visible:
                                order.resolvedType == ORDER_TYPE.SHOPPING &&
                                    order.groceryList != null,
                            child: Text(order.groceryList ?? ""),
                          ),
                          Divider(),
                          Row(
                            children: [
                              Expanded(
                                child: Text("Subtotal"),
                              ),
                              Text(
                                order.resolvedType == ORDER_TYPE.TANDOOR
                                    ? "Rs. ${order.subtotalPrice.toStringAsFixed(2)}"
                                    : "Rs. ${order.grocerySubtotal.toStringAsFixed(2)}",
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                    "Delivery Fee${order.resolvedType != ORDER_TYPE.TANDOOR && order.estimatedDeliveryCharges > 0 ? " (Est.)" : ""}"),
                              ),
                              Text(
                                order.resolvedType != ORDER_TYPE.TANDOOR &&
                                        order.estimatedDeliveryCharges > 0
                                    ? "Rs. ${(order.estimatedDeliveryCharges - 5).toStringAsFixed(2)} - ${(order.estimatedDeliveryCharges + 5).toStringAsFixed(2)}"
                                    : "Rs. ${order.deliveryPrice.toStringAsFixed(2)}",
                              ),
                            ],
                          ),
                          Visibility(
                            visible: order.fromWallet > 0,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text("Wallet"),
                                ),
                                Text(
                                  "-Rs. ${order.fromWallet.toStringAsFixed(2)}",
                                ),
                              ],
                            ),
                          ),
                          Divider(),
                          Row(
                            children: [
                              Text(
                                "Total ",
                                style: AppTextStyle.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "(incl. VAT)",
                                  style: AppTextStyle.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Text(
                                order.resolvedType != ORDER_TYPE.TANDOOR &&
                                        order.estimatedDeliveryCharges > 0
                                    ? "Rs. ${(order.estimatedDeliveryCharges + order.grocerySubtotal - 5).toStringAsFixed(2)} - ${(order.estimatedDeliveryCharges + order.grocerySubtotal + 5).toStringAsFixed(2)}"
                                    : "Rs. ${order.totalPrice.toStringAsFixed(2)}",
                                style: AppTextStyle.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: Colors.transparent,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ETATimer extends StatefulWidget {
  final int eta;

  _ETATimer(this.eta);

  @override
  __ETATimerState createState() => __ETATimerState();
}

class __ETATimerState extends State<_ETATimer> {
  Duration timeLeft;
  String eta;
  Timer _timer;
  Duration unitOfTimer = const Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() async {
    while (!mounted) await Future.delayed(Duration(milliseconds: 500));
    Duration _timeLeft = Duration(milliseconds: widget.eta - await getEpoch());
    setState(() {
      timeLeft = _timeLeft;
      if (timeLeft < unitOfTimer) timeLeft = Duration.zero;
    });

    _timer = Timer.periodic(unitOfTimer, (timer) {
      if (timeLeft.inMinutes <= 0) {
        _timer.cancel();
      } else {
        setState(() {
          timeLeft = timeLeft - unitOfTimer;
        });
      }
    });
  }

  @override
  void dispose() {
    if (_timer != null) _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (timeLeft == null) {
      eta = "...";
    } else if (timeLeft.inMinutes < 5) {
      eta = "Less than 5 min";
      if (_timer != null) _timer.cancel();
    } else {
      eta = "${timeLeft.inMinutes} min";
    }

    return Text(
      eta,
      style: AppTextStyle.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _OrderItemsList extends StatelessWidget {
  final String shopName;
  final List<OrderItem> orderItems;

  _OrderItemsList({
    this.shopName,
    this.orderItems,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          height: 12,
          color: Colors.transparent,
        ),
        Row(
          children: [
            Expanded(
              child: Text("Your order from:"),
            ),
            Text(
              shopName ?? "Tandoor",
              textAlign: TextAlign.right,
              style: AppTextStyle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Divider(
          color: Colors.transparent,
          height: 4,
        ),
        ...List.generate(
          orderItems?.length ?? 0,
          (index) => Row(
            children: [
              Text(
                "x${orderItems[index].quantity}",
                style: AppTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              VerticalDivider(
                color: Colors.transparent,
              ),
              Expanded(
                child: Text(
                  orderItems[index].name,
                ),
              ),
              VerticalDivider(
                color: Colors.transparent,
              ),
              Text(
                "Rs. ${(orderItems[index].price * orderItems[index].quantity).toStringAsFixed(2)}",
              ),
            ],
          ),
        ),
      ],
    );
  }
}
