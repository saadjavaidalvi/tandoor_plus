import 'package:animate_do/animate_do.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';
import 'package:user/common/app_bar.dart';
import 'package:user/common/shared.dart';
import 'package:user/managers/database_manager.dart';
import 'package:user/models/order.dart';
import 'package:user/models/order_item.dart';
import 'package:user/pages/order_page.dart';

class YourOrdersPage extends StatefulWidget {
  static final String route = "your_orders";

  @override
  _YourOrdersPageState createState() => _YourOrdersPageState();
}

class _YourOrdersPageState extends State<YourOrdersPage> {
  bool hasMoreOrders;
  List<Order> orders;
  int lastOrderTime;
  final int limit = 8;
  GlobalKey<ScaffoldState> _scaffoldKey;

  @override
  void initState() {
    super.initState();
    hasMoreOrders = true;
    orders = [];

    _scaffoldKey = GlobalKey<ScaffoldState>();

    initLoadMoreOrders();
  }

  void initLoadMoreOrders() async {
    lastOrderTime = await getEpoch();
    loadMoreOrders();
  }

  Future<void> loadMoreOrders({bool refreshOnly = false}) async {
    if (refreshOnly) lastOrderTime = await getEpoch();
    List<Order> _orders = await DatabaseManager.instance.getOrdersList(
        limit: refreshOnly ? orders.length : limit,
        beforeDatetime: lastOrderTime,
        forceServerUpdated: orders.length == 0 || refreshOnly);
    if (mounted) {
      if (_orders == null) {
        Future.delayed(Duration(seconds: 2), loadMoreOrders);
        return;
      } else {
        if (_orders.length > 0) {
          lastOrderTime = _orders.last.datetime;
          setState(() {
            if (refreshOnly) orders.clear();
            orders.addAll(_orders);
          });
        }

        if (_orders.length < limit) {
          setState(() {
            hasMoreOrders = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    printInfo("Loading number of orders: ${orders.length}");

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, null);
        return false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: getAppBar(
          context,
          AppBarType.backOnly,
          title: "Your orders",
          onBackPressed: () {
            Navigator.pop(context);
          },
        ),
        body: Container(
          color: Color(0xFFF9F9F9),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: LazyLoadScrollView(
            onEndOfPage: loadMoreOrders,
            child: RefreshIndicator(
              backgroundColor: appPrimaryColor,
              onRefresh: () async {
                await loadMoreOrders(refreshOnly: true);
              },
              child: ListView.builder(
                itemCount: orders.length + 1,
                itemBuilder: (listContext, index) {
                  if (index == orders.length) {
                    return Center(
                      child: hasMoreOrders
                          ? Container(
                              width: 90,
                              height: 90,
                              margin: const EdgeInsets.all(24),
                              color: Colors.transparent,
                              child: Spin(
                                key: UniqueKey(),
                                child: Image.asset(
                                    "assets/launcher/foreground.png"),
                                infinite: true,
                                duration: Duration(milliseconds: 1250),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text("No more orders"),
                            ),
                    );
                  } else {
                    Order order = orders[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      OrderPage.route,
                                      arguments: order.id,
                                    ),
                                    child: Icon(
                                      Icons.open_in_new,
                                      color: appPrimaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  VerticalDivider(
                                    color: Colors.transparent,
                                  ),
                                  Expanded(
                                    child: Text(
                                      "Order Details:",
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
                              Divider(color: Colors.transparent),
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
                                          _scaffoldKey.currentState
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
                                order.resolvedType == ORDER_TYPE.TANDOOR
                                    ? 1
                                    : 0,
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
                                        ? "Estimated Rs. ${(order.estimatedDeliveryCharges + order.grocerySubtotal).toStringAsFixed(2)}"
                                        : "Rs. ${order.totalPrice.toStringAsFixed(2)}",
                                    style: AppTextStyle.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Status",
                                      style: AppTextStyle,
                                    ),
                                  ),
                                  Text(
                                    order.canceled
                                        ? "Canceled"
                                        : ((order.resolvedStatus.index <=
                                                    ORDER_STATUS
                                                        .ASSIGNED_TO_SHOP
                                                        .index) ||
                                                (order.acceptedByShop &&
                                                    !order.acceptedByRider)
                                            ? "Pending"
                                            : (order.resolvedStatus ==
                                                        ORDER_STATUS
                                                            .ASSIGNED_TO_RIDER &&
                                                    order.acceptedByShop
                                                ? "Confirmed"
                                                : (order.resolvedStatus ==
                                                        ORDER_STATUS.ON_THE_WAY
                                                    ? "On the way"
                                                    : "Completed"))),
                                    style: AppTextStyle,
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
                    );
                  }
                },
              ),
            ),
          ),
        ),
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
